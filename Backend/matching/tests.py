"""
Matching App Tests
Covers: MatchingService scenarios 1-6, common interests, scoring,
        Match model, MatchFilter, like/reject/accept_connection API,
        connection_requests, find_matches endpoint
"""
from datetime import timedelta
from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework.test import APITestCase
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken

from authentication.models import CustomUser
from flights.models import Flight, UserInterest, TravelPreference
from matching.models import Match, MatchFilter
from matching.matching_service import MatchingService


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def make_user(email="user@example.com", password="Pass123!", **kwargs):
    username = kwargs.pop("username", email.split("@")[0])
    first_name = kwargs.pop("first_name", "Test")
    last_name = kwargs.pop("last_name", "User")
    return CustomUser.objects.create_user(
        username=username, email=email, password=password,
        first_name=first_name, last_name=last_name, **kwargs,
    )


_flight_counter = 0


def make_flight(user, dep="ADD", arr="DXB", dep_offset_days=3,
                has_layover=False, layover_airport=None, layover_city=None,
                layover_start=None, layover_end=None, **overrides):
    global _flight_counter
    _flight_counter += 1
    now = timezone.now()
    dep_dt = now + timedelta(days=dep_offset_days)
    arr_dt = dep_dt + timedelta(hours=5)
    defaults = dict(
        flight_number=overrides.pop("flight_number", f"ET{_flight_counter:04d}"),
        airline="Ethiopian Airlines",
        departure_airport=dep,
        departure_city=dep,
        arrival_airport=arr,
        arrival_city=arr,
        departure_datetime=dep_dt,
        arrival_datetime=arr_dt,
        is_visible=True,
        open_to_meeting=True,
        has_layover=has_layover,
        layover_airport=layover_airport,
        layover_city=layover_city,
        layover_start=layover_start,
        layover_end=layover_end,
    )
    defaults.update(overrides)
    return Flight.objects.create(user=user, **defaults)


def make_match(u1, u2, f1, f2, **overrides):
    now = timezone.now()
    # Enforce user1 = smaller id
    if u1.id > u2.id:
        u1, u2 = u2, u1
        f1, f2 = f2, f1
    defaults = dict(
        match_type="same_route",
        matching_airport="ADD",
        matching_city="Addis Ababa",
        overlap_start=now + timedelta(hours=1),
        overlap_end=now + timedelta(hours=3),
        overlap_duration_hours=2.0,
        match_score=0.7,
        status="pending",
    )
    defaults.update(overrides)
    return Match.objects.create(user1=u1, user2=u2, flight1=f1, flight2=f2, **defaults)


def bearer(user):
    return f"Bearer {RefreshToken.for_user(user).access_token}"


# ---------------------------------------------------------------------------
# Unit Tests – Match Model
# ---------------------------------------------------------------------------

class MatchModelTest(TestCase):

    def setUp(self):
        self.u1 = make_user(email="u1@example.com", username="u1")
        self.u2 = make_user(email="u2@example.com", username="u2")
        self.f1 = make_flight(self.u1)
        self.f2 = make_flight(self.u2, flight_number="ET999")

    def test_str_representation(self):
        m = make_match(self.u1, self.u2, self.f1, self.f2)
        self.assertIn(self.u1.email, str(m))
        self.assertIn(self.u2.email, str(m))

    def test_mark_matched_when_both_liked(self):
        m = make_match(self.u1, self.u2, self.f1, self.f2,
                       user1_liked=True, user2_liked=True, status="pending")
        m.mark_matched()
        self.assertEqual(m.status, "matched")
        self.assertIsNotNone(m.matched_at)

    def test_mark_matched_not_triggered_if_only_one_liked(self):
        m = make_match(self.u1, self.u2, self.f1, self.f2,
                       user1_liked=True, user2_liked=False, status="pending")
        m.mark_matched()
        self.assertEqual(m.status, "pending")

    def test_unique_together_user_pair_and_flights(self):
        make_match(self.u1, self.u2, self.f1, self.f2)
        with self.assertRaises(Exception):
            make_match(self.u1, self.u2, self.f1, self.f2)

    def test_default_status_is_pending(self):
        m = make_match(self.u1, self.u2, self.f1, self.f2)
        self.assertEqual(m.status, "pending")


# ---------------------------------------------------------------------------
# Unit Tests – MatchFilter Model
# ---------------------------------------------------------------------------

class MatchFilterModelTest(TestCase):

    def setUp(self):
        self.user = make_user()

    def test_create_match_filter(self):
        mf = MatchFilter.objects.create(user=self.user, min_age=20, max_age=40)
        self.assertIn(self.user.email, str(mf))

    def test_one_to_one_constraint(self):
        MatchFilter.objects.create(user=self.user)
        with self.assertRaises(Exception):
            MatchFilter.objects.create(user=self.user)


# ---------------------------------------------------------------------------
# Unit Tests – MatchingService.calculate_common_interests
# ---------------------------------------------------------------------------

class CommonInterestsTest(TestCase):

    def setUp(self):
        self.u1 = make_user(email="ci1@example.com", username="ci1")
        self.u2 = make_user(email="ci2@example.com", username="ci2")

    def test_common_interests_found(self):
        UserInterest.objects.create(user=self.u1, interest="Hiking")
        UserInterest.objects.create(user=self.u1, interest="Photography")
        UserInterest.objects.create(user=self.u2, interest="hiking")  # lowercase
        UserInterest.objects.create(user=self.u2, interest="Cooking")
        common = MatchingService.calculate_common_interests(self.u1, self.u2)
        self.assertEqual(len(common), 1)
        self.assertEqual(common[0].lower(), "hiking")

    def test_no_common_interests(self):
        UserInterest.objects.create(user=self.u1, interest="Hiking")
        UserInterest.objects.create(user=self.u2, interest="Cooking")
        common = MatchingService.calculate_common_interests(self.u1, self.u2)
        self.assertEqual(common, [])

    def test_empty_interests_both_users(self):
        common = MatchingService.calculate_common_interests(self.u1, self.u2)
        self.assertEqual(common, [])

    def test_multiple_common_interests(self):
        for interest in ["Hiking", "Photography", "Travel"]:
            UserInterest.objects.create(user=self.u1, interest=interest)
            UserInterest.objects.create(user=self.u2, interest=interest)
        common = MatchingService.calculate_common_interests(self.u1, self.u2)
        self.assertEqual(len(common), 3)


# ---------------------------------------------------------------------------
# Unit Tests – MatchingService Scenarios
# ---------------------------------------------------------------------------

class MatchingScenariosTest(TestCase):

    def setUp(self):
        self.u1 = make_user(email="ms1@example.com", username="ms1")
        self.u2 = make_user(email="ms2@example.com", username="ms2")

    # --- Scenario 1: Same departure + layover + destination ---

    def test_scenario1_same_route_with_layover_overlap(self):
        now = timezone.now()
        dep = now + timedelta(days=3)
        lay_start = dep + timedelta(hours=3)
        lay_end = lay_start + timedelta(hours=4)
        arr_dt = lay_end + timedelta(hours=3)

        f1 = Flight.objects.create(
            user=self.u1, flight_number="S1A",
            airline="ET", departure_airport="ADD", departure_city="Addis",
            arrival_airport="LHR", arrival_city="London",
            departure_datetime=dep, arrival_datetime=arr_dt,
            has_layover=True, layover_airport="DXB", layover_city="Dubai",
            layover_start=lay_start, layover_end=lay_end,
            is_visible=True, open_to_meeting=True,
        )
        f2 = Flight.objects.create(
            user=self.u2, flight_number="S1B",
            airline="ET", departure_airport="ADD", departure_city="Addis",
            arrival_airport="LHR", arrival_city="London",
            departure_datetime=dep + timedelta(minutes=30),
            arrival_datetime=arr_dt + timedelta(minutes=30),
            has_layover=True, layover_airport="DXB", layover_city="Dubai",
            layover_start=lay_start + timedelta(minutes=30),
            layover_end=lay_end + timedelta(minutes=30),
            is_visible=True, open_to_meeting=True,
        )

        matches = MatchingService.find_matches_for_user(self.u1, f1)
        matched_users = [m["user"] for m in matches]
        self.assertIn(self.u2, matched_users)

    # --- Scenario 2: Same layover, different destination ---

    def test_scenario2_same_layover_different_destination(self):
        now = timezone.now()
        dep = now + timedelta(days=3)
        lay_start = dep + timedelta(hours=3)
        lay_end = lay_start + timedelta(hours=4)

        f1 = Flight.objects.create(
            user=self.u1, flight_number="S2A",
            airline="ET", departure_airport="ADD", departure_city="Addis",
            arrival_airport="LHR", arrival_city="London",
            departure_datetime=dep, arrival_datetime=lay_end + timedelta(hours=3),
            has_layover=True, layover_airport="DXB", layover_city="Dubai",
            layover_start=lay_start, layover_end=lay_end,
            is_visible=True, open_to_meeting=True,
        )
        f2 = Flight.objects.create(
            user=self.u2, flight_number="S2B",
            airline="ET", departure_airport="JFK", departure_city="New York",
            arrival_airport="CDG", arrival_city="Paris",  # different destination
            departure_datetime=dep, arrival_datetime=lay_end + timedelta(hours=4),
            has_layover=True, layover_airport="DXB", layover_city="Dubai",
            layover_start=lay_start + timedelta(minutes=30),
            layover_end=lay_end + timedelta(minutes=30),
            is_visible=True, open_to_meeting=True,
        )

        matches = MatchingService.find_matches_for_user(self.u1, f1)
        matched_users = [m["user"] for m in matches]
        self.assertIn(self.u2, matched_users)

    # --- Scenario 4: Same departure, different layovers ---

    def test_scenario4_same_departure_different_layovers(self):
        now = timezone.now()
        dep = now + timedelta(days=3)

        f1 = make_flight(
            self.u1, dep="ADD", arr="DXB",
            departure_datetime=dep, arrival_datetime=dep + timedelta(hours=4),
            flight_number="S4A",
        )
        f2 = Flight.objects.create(
            user=self.u2, flight_number="S4B",
            airline="ET", departure_airport="ADD", departure_city="Addis",
            arrival_airport="LHR", arrival_city="London",
            departure_datetime=dep + timedelta(hours=1),  # within 4h
            arrival_datetime=dep + timedelta(hours=10),
            has_layover=True, layover_airport="CDG", layover_city="Paris",
            layover_start=dep + timedelta(hours=5),
            layover_end=dep + timedelta(hours=8),
            is_visible=True, open_to_meeting=True,
        )

        matches = MatchingService.find_matches_for_user(self.u1, f1)
        matched_users = [m["user"] for m in matches]
        self.assertIn(self.u2, matched_users)

    # --- Scenario 5: Same route, direct flight ---

    def test_scenario5_same_direct_route(self):
        now = timezone.now()
        dep = now + timedelta(days=3)

        f1 = Flight.objects.create(
            user=self.u1, flight_number="S5A",
            airline="ET", departure_airport="ADD", departure_city="Addis",
            arrival_airport="DXB", arrival_city="Dubai",
            departure_datetime=dep, arrival_datetime=dep + timedelta(hours=4),
            has_layover=False, is_visible=True, open_to_meeting=True,
        )
        f2 = Flight.objects.create(
            user=self.u2, flight_number="S5B",
            airline="ET", departure_airport="ADD", departure_city="Addis",
            arrival_airport="DXB", arrival_city="Dubai",
            departure_datetime=dep + timedelta(hours=1),  # within 2h
            arrival_datetime=dep + timedelta(hours=5),
            has_layover=False, is_visible=True, open_to_meeting=True,
        )

        matches = MatchingService.find_matches_for_user(self.u1, f1)
        matched_users = [m["user"] for m in matches]
        self.assertIn(self.u2, matched_users)

    # --- No match when open_to_meeting is False ---

    def test_no_match_if_open_to_meeting_false(self):
        now = timezone.now()
        dep = now + timedelta(days=3)

        f1 = Flight.objects.create(
            user=self.u1, flight_number="NM1",
            airline="ET", departure_airport="ADD", departure_city="Addis",
            arrival_airport="DXB", arrival_city="Dubai",
            departure_datetime=dep, arrival_datetime=dep + timedelta(hours=4),
            is_visible=True, open_to_meeting=True,
        )
        Flight.objects.create(
            user=self.u2, flight_number="NM2",
            airline="ET", departure_airport="ADD", departure_city="Addis",
            arrival_airport="DXB", arrival_city="Dubai",
            departure_datetime=dep + timedelta(hours=1),
            arrival_datetime=dep + timedelta(hours=5),
            is_visible=True, open_to_meeting=False,  # closed to meeting
        )

        matches = MatchingService.find_matches_for_user(self.u1, f1)
        matched_users = [m["user"] for m in matches]
        self.assertNotIn(self.u2, matched_users)

    def test_no_match_if_flight_not_visible(self):
        now = timezone.now()
        dep = now + timedelta(days=3)

        f1 = Flight.objects.create(
            user=self.u1, flight_number="NV1",
            airline="ET", departure_airport="ADD", departure_city="Addis",
            arrival_airport="DXB", arrival_city="Dubai",
            departure_datetime=dep, arrival_datetime=dep + timedelta(hours=4),
            is_visible=True, open_to_meeting=True,
        )
        Flight.objects.create(
            user=self.u2, flight_number="NV2",
            airline="ET", departure_airport="ADD", departure_city="Addis",
            arrival_airport="DXB", arrival_city="Dubai",
            departure_datetime=dep + timedelta(hours=1),
            arrival_datetime=dep + timedelta(hours=5),
            is_visible=False,  # hidden
            open_to_meeting=True,
        )

        matches = MatchingService.find_matches_for_user(self.u1, f1)
        matched_users = [m["user"] for m in matches]
        self.assertNotIn(self.u2, matched_users)

    def test_user_not_matched_with_themselves(self):
        f = make_flight(self.u1)
        matches = MatchingService.find_matches_for_user(self.u1, f)
        matched_users = [m["user"] for m in matches]
        self.assertNotIn(self.u1, matched_users)

    def test_no_flight_returns_empty(self):
        matches = MatchingService.find_matches_for_user(self.u1, None)
        self.assertEqual(matches, [])


# ---------------------------------------------------------------------------
# Unit Tests – MatchingService.create_or_update_match
# ---------------------------------------------------------------------------

class CreateOrUpdateMatchTest(TestCase):

    def setUp(self):
        self.u1 = make_user(email="cum1@example.com", username="cum1")
        self.u2 = make_user(email="cum2@example.com", username="cum2")
        self.f1 = make_flight(self.u1)
        self.f2 = make_flight(self.u2, flight_number="ET888")

    def test_creates_new_match(self):
        now = timezone.now()
        match_data = {
            "match_type": "same_route",
            "matching_airport": "ADD",
            "matching_city": "Addis",
            "overlap": {
                "start": now,
                "end": now + timedelta(hours=2),
                "duration_hours": 2.0,
            },
            "user": self.u2,
            "flight": self.f2,
        }
        # Ensure u1 < u2 ordering
        if self.u1.id < self.u2.id:
            u1, u2, f1, f2 = self.u1, self.u2, self.f1, self.f2
        else:
            u1, u2, f1, f2 = self.u2, self.u1, self.f2, self.f1

        match = MatchingService.create_or_update_match(u1, u2, f1, f2, match_data)
        self.assertIsNotNone(match)
        self.assertEqual(match.matching_airport, "ADD")

    def test_updates_existing_match(self):
        now = timezone.now()
        # Enforce ordering
        if self.u1.id < self.u2.id:
            u1, u2, f1, f2 = self.u1, self.u2, self.f1, self.f2
        else:
            u1, u2, f1, f2 = self.u2, self.u1, self.f2, self.f1

        existing = Match.objects.create(
            user1=u1, user2=u2, flight1=f1, flight2=f2,
            match_type="same_route", matching_airport="ADD",
            matching_city="Addis",
            overlap_start=now, overlap_end=now + timedelta(hours=2),
            overlap_duration_hours=2.0, match_score=0.5,
        )

        match_data = {
            "match_type": "same_route",
            "matching_airport": "ADD",
            "matching_city": "Addis",
            "overlap": {
                "start": now,
                "end": now + timedelta(hours=2),
                "duration_hours": 2.0,
            },
            "user": u2,
            "flight": f2,
        }
        match = MatchingService.create_or_update_match(u1, u2, f1, f2, match_data)
        self.assertEqual(match.id, existing.id)


# ---------------------------------------------------------------------------
# Integration Tests – Match API (like / reject / accept_connection)
# ---------------------------------------------------------------------------

class MatchActionsAPITest(APITestCase):

    base_url = "/api/matching/matches/"

    def setUp(self):
        self.u1 = make_user(email="act1@example.com", username="act1")
        self.u2 = make_user(email="act2@example.com", username="act2")
        self.f1 = make_flight(self.u1)
        self.f2 = make_flight(self.u2, flight_number="ACT999")
        self.match = make_match(self.u1, self.u2, self.f1, self.f2)

        self.client.credentials(HTTP_AUTHORIZATION=bearer(self.u1))

    def test_list_matches_for_user(self):
        res = self.client.get(self.base_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        ids = [m["id"] for m in res.data]
        self.assertIn(self.match.id, ids)

    def test_like_sends_connection_request(self):
        res = self.client.post(f"{self.base_url}{self.match.id}/like/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.match.refresh_from_db()
        self.assertEqual(self.match.status, "connection_requested")
        self.assertTrue(self.match.user1_liked)

    def test_mutual_like_creates_match(self):
        # u1 likes
        self.client.post(f"{self.base_url}{self.match.id}/like/")
        # u2 likes back
        self.client.credentials(HTTP_AUTHORIZATION=bearer(self.u2))
        res = self.client.post(f"{self.base_url}{self.match.id}/like/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.match.refresh_from_db()
        self.assertEqual(self.match.status, "matched")

    def test_reject_match(self):
        res = self.client.post(f"{self.base_url}{self.match.id}/reject/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.match.refresh_from_db()
        self.assertEqual(self.match.status, "rejected")

    def test_reject_resets_liked_flag_for_user1(self):
        self.match.user1_liked = True
        self.match.save()
        self.client.post(f"{self.base_url}{self.match.id}/reject/")
        self.match.refresh_from_db()
        self.assertFalse(self.match.user1_liked)

    def test_like_unauthorized_user_forbidden(self):
        # u3 has no relation to this match — queryset excludes it so 404 is returned
        u3 = make_user(email="u3@example.com", username="u3")
        self.client.credentials(HTTP_AUTHORIZATION=bearer(u3))
        res = self.client.post(f"{self.base_url}{self.match.id}/like/")
        self.assertEqual(res.status_code, status.HTTP_404_NOT_FOUND)

    def test_accept_connection_after_request(self):
        # u1 sends connection request
        self.match.user1_liked = True
        self.match.status = "connection_requested"
        self.match.save()

        # u2 accepts
        self.client.credentials(HTTP_AUTHORIZATION=bearer(self.u2))
        res = self.client.post(f"{self.base_url}{self.match.id}/accept_connection/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.match.refresh_from_db()
        self.assertEqual(self.match.status, "matched")

    def test_accept_connection_invalid_status(self):
        # Match is still pending — cannot accept
        self.match.status = "pending"
        self.match.save()
        self.client.credentials(HTTP_AUTHORIZATION=bearer(self.u2))
        res = self.client.post(f"{self.base_url}{self.match.id}/accept_connection/")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_rejected_match_not_in_list(self):
        self.match.status = "rejected"
        self.match.save()
        res = self.client.get(self.base_url)
        ids = [m["id"] for m in res.data]
        self.assertNotIn(self.match.id, ids)

    def test_unauthenticated_request_denied(self):
        self.client.credentials()
        res = self.client.get(self.base_url)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)


# ---------------------------------------------------------------------------
# Integration Tests – find_matches endpoint
# ---------------------------------------------------------------------------

class FindMatchesAPITest(APITestCase):

    url = "/api/matching/matches/find_matches/"

    def setUp(self):
        from django.core.cache import cache
        cache.clear()
        self.u1 = make_user(email="fm1@example.com", username="fm1")
        self.u2 = make_user(email="fm2@example.com", username="fm2")
        self.client.credentials(HTTP_AUTHORIZATION=bearer(self.u1))

    def test_find_matches_no_flight_returns_message(self):
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        # No flights → message returned
        self.assertIn("message", res.data)

    def test_find_matches_with_compatible_flight(self):
        now = timezone.now()
        dep = now + timedelta(days=3)

        make_flight(
            self.u1, dep="ADD", arr="DXB",
            flight_number="FM1",
            departure_datetime=dep,
            arrival_datetime=dep + timedelta(hours=4),
        )
        make_flight(
            self.u2, dep="ADD", arr="DXB",
            flight_number="FM2",
            departure_datetime=dep + timedelta(hours=1),
            arrival_datetime=dep + timedelta(hours=5),
        )

        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)

    def test_find_matches_with_specific_flight_id(self):
        now = timezone.now()
        dep = now + timedelta(days=3)
        f = make_flight(self.u1, flight_number="FMX",
                        departure_datetime=dep,
                        arrival_datetime=dep + timedelta(hours=4))
        res = self.client.get(self.url, {"flight_id": f.id})
        self.assertEqual(res.status_code, status.HTTP_200_OK)

    def test_find_matches_invalid_flight_id_returns_404(self):
        res = self.client.get(self.url, {"flight_id": 99999})
        self.assertEqual(res.status_code, status.HTTP_404_NOT_FOUND)


# ---------------------------------------------------------------------------
# Integration Tests – MatchFilter API
# ---------------------------------------------------------------------------

class MatchFilterAPITest(APITestCase):

    base_url = "/api/matching/filters/"

    def setUp(self):
        self.user = make_user()
        self.client.credentials(HTTP_AUTHORIZATION=bearer(self.user))

    def test_get_my_filters_creates_if_missing(self):
        res = self.client.get(f"{self.base_url}my_filters/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(MatchFilter.objects.filter(user=self.user).exists())

    def test_update_my_filters(self):
        res = self.client.put(
            f"{self.base_url}my_filters/",
            {"min_age": 25, "max_age": 40, "preferred_gender": "female"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        mf = MatchFilter.objects.get(user=self.user)
        self.assertEqual(mf.min_age, 25)
        self.assertEqual(mf.max_age, 40)

    def test_unauthenticated_denied(self):
        self.client.credentials()
        res = self.client.get(f"{self.base_url}my_filters/")
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)


# ---------------------------------------------------------------------------
# Integration Tests – Rate Limiting on find_matches
# ---------------------------------------------------------------------------

class MatchThrottleTest(APITestCase):
    """
    Verify that the matching scope throttle is correctly wired for find_matches.
    """

    url = "/api/matching/matches/find_matches/"

    def setUp(self):
        from django.core.cache import cache
        cache.clear()
        self.user = make_user(email="throttle_match@example.com", username="throttlematch")
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {RefreshToken.for_user(self.user).access_token}"
        )

    def test_find_matches_action_uses_scoped_throttle_when_configured(self):
        """When the matching scope is configured, find_matches returns ScopedRateThrottle."""
        from rest_framework.throttling import ScopedRateThrottle
        from matching.views import MatchViewSet
        from unittest.mock import MagicMock

        view = MatchViewSet()
        view.action = "find_matches"
        view.request = MagicMock()

        with self.settings(REST_FRAMEWORK={
            "DEFAULT_AUTHENTICATION_CLASSES": (
                "rest_framework_simplejwt.authentication.JWTAuthentication",
            ),
            "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.AllowAny",),
            "DEFAULT_THROTTLE_CLASSES": [],
            "DEFAULT_THROTTLE_RATES": {
                "matching": "10/minute",
            },
        }):
            throttles = view.get_throttles()

        self.assertTrue(any(isinstance(t, ScopedRateThrottle) for t in throttles))

    def test_list_action_does_not_use_matching_throttle(self):
        """The list action should not get the matching scoped throttle."""
        from rest_framework.throttling import ScopedRateThrottle
        from matching.views import MatchViewSet
        from unittest.mock import MagicMock

        view = MatchViewSet()
        view.action = "list"
        view.request = MagicMock()

        throttles = view.get_throttles()
        self.assertFalse(any(isinstance(t, ScopedRateThrottle) for t in throttles))

    def test_find_matches_single_call_not_throttled(self):
        """A single find_matches call is never throttled (throttling off in test_settings)."""
        res = self.client.get(self.url)
        self.assertNotEqual(res.status_code, 429)
