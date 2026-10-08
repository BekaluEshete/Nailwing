"""
Flights App Tests
Covers: Flight CRUD, status auto-calculation, signals, UserInterest,
        TravelPreference, community_posts, upcoming/current actions
"""
from datetime import timedelta
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APITestCase
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken

from authentication.models import CustomUser
from flights.models import Flight, UserInterest, TravelPreference


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def make_user(email="pilot@example.com", password="Pass123!", **kwargs):
    username = kwargs.pop("username", email.split("@")[0])
    first_name = kwargs.pop("first_name", "Test")
    last_name = kwargs.pop("last_name", "User")
    return CustomUser.objects.create_user(
        username=username, email=email, password=password,
        first_name=first_name, last_name=last_name, **kwargs,
    )


_flight_counter = 0


def make_flight(user, **overrides):
    """Return a scheduled future flight with sensible defaults."""
    global _flight_counter
    _flight_counter += 1
    now = timezone.now()
    defaults = dict(
        flight_number=overrides.pop("flight_number", f"ET{_flight_counter:04d}"),
        airline="Ethiopian Airlines",
        departure_airport="ADD",
        departure_city="Addis Ababa",
        arrival_airport="DXB",
        arrival_city="Dubai",
        departure_datetime=now + timedelta(days=3),
        arrival_datetime=now + timedelta(days=3, hours=5),
        is_visible=True,
        open_to_meeting=True,
        has_layover=False,
    )
    defaults.update(overrides)
    return Flight.objects.create(user=user, **defaults)


def bearer(user):
    return {"HTTP_AUTHORIZATION": f"Bearer {RefreshToken.for_user(user).access_token}"}


# ---------------------------------------------------------------------------
# Unit Tests – Flight Model
# ---------------------------------------------------------------------------

class FlightModelTest(TestCase):

    def setUp(self):
        self.user = make_user()

    # --- route property ---

    def test_route_direct(self):
        f = make_flight(self.user, has_layover=False)
        self.assertEqual(f.route, "ADD → DXB")

    def test_route_with_layover(self):
        now = timezone.now()
        f = make_flight(
            self.user,
            has_layover=True,
            layover_airport="DXB",
            layover_city="Dubai",
            layover_start=now + timedelta(days=3, hours=5),
            layover_end=now + timedelta(days=3, hours=9),
            arrival_airport="LHR",
            arrival_city="London",
        )
        self.assertEqual(f.route, "ADD → DXB → LHR")

    # --- duration_hours property ---

    def test_duration_hours(self):
        f = make_flight(self.user)
        self.assertAlmostEqual(f.duration_hours, 5.0, places=1)

    # --- calculate_status_based_on_datetime ---

    def test_status_scheduled_future(self):
        f = make_flight(self.user)
        self.assertEqual(f.calculate_status_based_on_datetime(), "scheduled")

    def test_status_boarding_within_2_hours(self):
        now = timezone.now()
        f = make_flight(
            self.user,
            departure_datetime=now + timedelta(hours=1),
            arrival_datetime=now + timedelta(hours=6),
        )
        self.assertEqual(f.calculate_status_based_on_datetime(), "boarding")

    def test_status_in_flight(self):
        now = timezone.now()
        f = make_flight(
            self.user,
            departure_datetime=now - timedelta(hours=1),
            arrival_datetime=now + timedelta(hours=4),
        )
        self.assertEqual(f.calculate_status_based_on_datetime(), "in_flight")

    def test_status_landed_after_arrival(self):
        now = timezone.now()
        f = make_flight(
            self.user,
            departure_datetime=now - timedelta(hours=6),
            arrival_datetime=now - timedelta(hours=1),
        )
        self.assertEqual(f.calculate_status_based_on_datetime(), "landed")

    def test_cancelled_status_never_overridden(self):
        now = timezone.now()
        f = make_flight(
            self.user,
            status="cancelled",
            departure_datetime=now - timedelta(hours=6),
            arrival_datetime=now - timedelta(hours=1),
        )
        self.assertEqual(f.calculate_status_based_on_datetime(), "cancelled")

    def test_save_auto_promotes_to_in_flight(self):
        now = timezone.now()
        f = Flight(
            user=self.user,
            flight_number="ET200",
            airline="ET",
            departure_airport="ADD",
            departure_city="Addis",
            arrival_airport="DXB",
            arrival_city="Dubai",
            departure_datetime=now - timedelta(hours=2),
            arrival_datetime=now + timedelta(hours=3),
            status="scheduled",
        )
        f.save()
        f.refresh_from_db()
        self.assertEqual(f.status, "in_flight")

    def test_save_does_not_change_cancelled(self):
        now = timezone.now()
        f = Flight(
            user=self.user,
            flight_number="ET300",
            airline="ET",
            departure_airport="ADD",
            departure_city="Addis",
            arrival_airport="DXB",
            arrival_city="Dubai",
            departure_datetime=now - timedelta(hours=2),
            arrival_datetime=now + timedelta(hours=3),
            status="cancelled",
        )
        f.save()
        f.refresh_from_db()
        self.assertEqual(f.status, "cancelled")


# ---------------------------------------------------------------------------
# Unit Tests – Flight Cancellation Signal
# ---------------------------------------------------------------------------

class FlightCancellationSignalTest(TestCase):

    def setUp(self):
        self.user1 = make_user(email="u1@example.com", username="u1")
        self.user2 = make_user(email="u2@example.com", username="u2")
        self.flight1 = make_flight(self.user1)
        self.flight2 = make_flight(self.user2, flight_number="ET999")

    def test_cancelling_flight_expires_related_matches(self):
        from matching.models import Match

        now = timezone.now()
        match = Match.objects.create(
            user1=self.user1,
            user2=self.user2,
            flight1=self.flight1,
            flight2=self.flight2,
            match_type="same_route",
            matching_airport="ADD",
            matching_city="Addis Ababa",
            overlap_start=now + timedelta(hours=1),
            overlap_end=now + timedelta(hours=3),
            overlap_duration_hours=2.0,
            status="pending",
        )

        # Cancel the flight — signal fires on pre_save
        self.flight1.status = "cancelled"
        self.flight1.save()

        match.refresh_from_db()
        self.assertEqual(match.status, "expired")

    def test_cancelling_flight_does_not_expire_already_rejected(self):
        from matching.models import Match

        now = timezone.now()
        match = Match.objects.create(
            user1=self.user1,
            user2=self.user2,
            flight1=self.flight1,
            flight2=self.flight2,
            match_type="same_route",
            matching_airport="ADD",
            matching_city="Addis Ababa",
            overlap_start=now + timedelta(hours=1),
            overlap_end=now + timedelta(hours=3),
            overlap_duration_hours=2.0,
            status="rejected",
        )

        self.flight1.status = "cancelled"
        self.flight1.save()

        match.refresh_from_db()
        self.assertEqual(match.status, "rejected")  # not changed

    def test_updating_other_field_does_not_expire_matches(self):
        from matching.models import Match

        now = timezone.now()
        match = Match.objects.create(
            user1=self.user1,
            user2=self.user2,
            flight1=self.flight1,
            flight2=self.flight2,
            match_type="same_route",
            matching_airport="ADD",
            matching_city="Addis Ababa",
            overlap_start=now + timedelta(hours=1),
            overlap_end=now + timedelta(hours=3),
            overlap_duration_hours=2.0,
            status="pending",
        )

        # Update delay only — status stays pending
        self.flight1.delay_minutes = 15
        self.flight1.save()

        match.refresh_from_db()
        self.assertEqual(match.status, "pending")


# ---------------------------------------------------------------------------
# Unit Tests – UserInterest & TravelPreference Models
# ---------------------------------------------------------------------------

class UserInterestModelTest(TestCase):

    def setUp(self):
        self.user = make_user()

    def test_create_interest(self):
        interest = UserInterest.objects.create(user=self.user, interest="Photography")
        self.assertEqual(str(interest), f"{self.user.email} - Photography")

    def test_unique_together_constraint(self):
        UserInterest.objects.create(user=self.user, interest="Hiking")
        with self.assertRaises(Exception):
            UserInterest.objects.create(user=self.user, interest="Hiking")


class TravelPreferenceModelTest(TestCase):

    def setUp(self):
        self.user = make_user()

    def test_create_preference(self):
        pref = TravelPreference.objects.create(user=self.user, travel_experience="frequent")
        self.assertIn(self.user.email, str(pref))

    def test_one_to_one_constraint(self):
        TravelPreference.objects.create(user=self.user)
        with self.assertRaises(Exception):
            TravelPreference.objects.create(user=self.user)


# ---------------------------------------------------------------------------
# Integration Tests – Flight API (CRUD)
# ---------------------------------------------------------------------------

class FlightCRUDAPITest(APITestCase):

    base_url = "/api/flights/flights/"

    def setUp(self):
        self.user = make_user()
        self.other = make_user(email="other@example.com", username="other")
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {RefreshToken.for_user(self.user).access_token}"
        )

    def _payload(self, **overrides):
        now = timezone.now()
        data = {
            "flight_number": "ET101",
            "airline": "Ethiopian Airlines",
            "departure_airport": "ADD",
            "departure_city": "Addis Ababa",
            "arrival_airport": "DXB",
            "arrival_city": "Dubai",
            "departure_datetime": (now + timedelta(days=3)).isoformat(),
            "arrival_datetime": (now + timedelta(days=3, hours=5)).isoformat(),
            "is_visible": True,
            "open_to_meeting": True,
        }
        data.update(overrides)
        return data

    def test_create_flight(self):
        res = self.client.post(self.base_url, self._payload(), format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["flight_number"], "ET101")

    def test_create_flight_sets_user_automatically(self):
        self.client.post(self.base_url, self._payload(), format="json")
        flight = Flight.objects.get(flight_number="ET101")
        self.assertEqual(flight.user, self.user)

    def test_list_flights_only_own(self):
        make_flight(self.user, flight_number="ET111")
        make_flight(self.other, flight_number="ET222")
        res = self.client.get(self.base_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        flight_numbers = [f["flight_number"] for f in res.data]
        self.assertIn("ET111", flight_numbers)
        self.assertNotIn("ET222", flight_numbers)

    def test_retrieve_own_flight(self):
        f = make_flight(self.user)
        res = self.client.get(f"{self.base_url}{f.id}/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["id"], f.id)

    def test_update_flight(self):
        f = make_flight(self.user)
        res = self.client.patch(
            f"{self.base_url}{f.id}/",
            {"airline": "Fly Emirates"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        f.refresh_from_db()
        self.assertEqual(f.airline, "Fly Emirates")

    def test_delete_flight(self):
        f = make_flight(self.user)
        res = self.client.delete(f"{self.base_url}{f.id}/")
        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Flight.objects.filter(id=f.id).exists())

    def test_unauthenticated_request_denied(self):
        self.client.credentials()
        res = self.client.get(self.base_url)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)


# ---------------------------------------------------------------------------
# Integration Tests – Flight Custom Actions
# ---------------------------------------------------------------------------

class FlightActionsAPITest(APITestCase):

    base_url = "/api/flights/flights/"

    def setUp(self):
        self.user = make_user()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {RefreshToken.for_user(self.user).access_token}"
        )

    def test_upcoming_returns_future_visible_flights(self):
        now = timezone.now()
        make_flight(self.user, flight_number="FUTURE1",
                    departure_datetime=now + timedelta(days=1),
                    arrival_datetime=now + timedelta(days=1, hours=4))
        # Past flight — should NOT appear
        make_flight(self.user, flight_number="PAST1",
                    departure_datetime=now - timedelta(days=1),
                    arrival_datetime=now - timedelta(hours=20),
                    status="landed")
        res = self.client.get(f"{self.base_url}upcoming/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        numbers = [f["flight_number"] for f in res.data]
        self.assertIn("FUTURE1", numbers)
        self.assertNotIn("PAST1", numbers)

    def test_update_status_action(self):
        f = make_flight(self.user)
        res = self.client.patch(
            f"{self.base_url}{f.id}/update_status/",
            {"status": "delayed", "delay_minutes": 30},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        f.refresh_from_db()
        self.assertEqual(f.delay_minutes, 30)

    def test_community_posts_returns_list(self):
        now = timezone.now()
        make_flight(self.user,
                    departure_datetime=now + timedelta(days=2),
                    arrival_datetime=now + timedelta(days=2, hours=5),
                    is_visible=True)
        res = self.client.get(f"{self.base_url}community_posts/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIsInstance(res.data, list)

    def test_community_posts_structure(self):
        now = timezone.now()
        make_flight(self.user,
                    departure_datetime=now + timedelta(days=2),
                    arrival_datetime=now + timedelta(days=2, hours=5),
                    is_visible=True)
        res = self.client.get(f"{self.base_url}community_posts/")
        if res.data:
            post = res.data[0]
            self.assertIn("user", post)
            self.assertIn("flight", post)
            self.assertIn("post", post)


# ---------------------------------------------------------------------------
# Integration Tests – UserInterest API
# ---------------------------------------------------------------------------

class UserInterestAPITest(APITestCase):

    base_url = "/api/flights/interests/"

    def setUp(self):
        self.user = make_user()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {RefreshToken.for_user(self.user).access_token}"
        )

    def test_create_interest(self):
        res = self.client.post(self.base_url, {"interest": "Photography"}, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

    def test_list_interests_only_own(self):
        other = make_user(email="other2@example.com", username="other2")
        UserInterest.objects.create(user=self.user, interest="Hiking")
        UserInterest.objects.create(user=other, interest="Skiing")
        res = self.client.get(self.base_url)
        self.assertEqual(len(res.data), 1)
        self.assertEqual(res.data[0]["interest"], "Hiking")

    def test_delete_interest(self):
        interest = UserInterest.objects.create(user=self.user, interest="Reading")
        res = self.client.delete(f"{self.base_url}{interest.id}/")
        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)


# ---------------------------------------------------------------------------
# Integration Tests – TravelPreference API
# ---------------------------------------------------------------------------

class TravelPreferenceAPITest(APITestCase):

    base_url = "/api/flights/preferences/"

    def setUp(self):
        self.user = make_user()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {RefreshToken.for_user(self.user).access_token}"
        )

    def test_my_preferences_get_creates_if_missing(self):
        res = self.client.get(f"{self.base_url}my_preferences/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(TravelPreference.objects.filter(user=self.user).exists())

    def test_my_preferences_update(self):
        res = self.client.put(
            f"{self.base_url}my_preferences/",
            {"travel_experience": "frequent", "open_to_socializing": True},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        pref = TravelPreference.objects.get(user=self.user)
        self.assertEqual(pref.travel_experience, "frequent")
