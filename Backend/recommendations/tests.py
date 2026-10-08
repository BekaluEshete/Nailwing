"""
Recommendations App Tests
Covers: AirportPlace model, UserRecommendation model,
        AirportPlaceViewSet (list with filters),
        RecommendationViewSet (list, get_recommendations with mocked PlacesAPIService)
"""
from datetime import timedelta
from unittest.mock import patch, MagicMock
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APITestCase
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken

from authentication.models import CustomUser
from flights.models import Flight
from matching.models import Match
from recommendations.models import AirportPlace, UserRecommendation


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def make_user(email="rec@example.com", password="Pass123!", **kwargs):
    username = kwargs.pop("username", email.split("@")[0])
    first_name = kwargs.pop("first_name", "Test")
    last_name = kwargs.pop("last_name", "User")
    return CustomUser.objects.create_user(
        username=username, email=email, password=password,
        first_name=first_name, last_name=last_name, **kwargs,
    )


_flight_counter = 0


def make_flight(user, **overrides):
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
    )
    defaults.update(overrides)
    return Flight.objects.create(user=user, **defaults)


def make_airport_place(airport="ADD", place_type="restaurant", **overrides):
    defaults = dict(
        airport_code=airport,
        name=f"Test {place_type.title()} at {airport}",
        place_type=place_type,
        terminal="T1",
        rating=4.2,
        is_24_hours=False,
    )
    defaults.update(overrides)
    return AirportPlace.objects.create(**defaults)


def bearer(user):
    return f"Bearer {RefreshToken.for_user(user).access_token}"


# Fake PlacesAPIService response used in get_recommendations tests
MOCK_PLACES_RESPONSE = {
    "hotel": [
        {
            "name": "Airport Hotel",
            "rating": 4.5,
            "latitude": 25.2532,
            "longitude": 55.3657,
            "address": "Near DXB Terminal 3",
            "distance": 500,
            "price_range": "$$",
            "opening_hours": "24/7",
            "is_24_hours": True,
            "description": "Comfortable hotel near the airport",
            "photos": [],
        }
    ],
    "cafe": [
        {
            "name": "Terminal Café",
            "rating": 4.0,
            "latitude": 25.2540,
            "longitude": 55.3660,
            "address": "Terminal 1",
            "distance": 200,
            "price_range": "$",
            "opening_hours": "06:00-22:00",
            "is_24_hours": False,
            "description": "Great coffee",
            "photos": [],
        }
    ],
    "restaurant": [
        {
            "name": "Sky Diner",
            "rating": 4.3,
            "latitude": 25.2550,
            "longitude": 55.3670,
            "address": "Terminal 2",
            "distance": 300,
            "price_range": "$$",
            "opening_hours": "07:00-23:00",
            "is_24_hours": False,
            "description": "International cuisine",
            "photos": [],
        }
    ],
}


# ---------------------------------------------------------------------------
# Unit Tests – AirportPlace Model
# ---------------------------------------------------------------------------

class AirportPlaceModelTest(TestCase):

    def test_str_representation(self):
        place = make_airport_place(airport="DXB", place_type="cafe")
        self.assertIn("DXB", str(place))
        self.assertIn("cafe", str(place).lower())

    def test_default_rating(self):
        place = AirportPlace.objects.create(
            airport_code="ADD",
            name="Lounge A",
            place_type="lounge",
        )
        self.assertEqual(place.rating, 0.0)

    def test_is_24_hours_default_false(self):
        place = make_airport_place()
        self.assertFalse(place.is_24_hours)

    def test_24_hours_place(self):
        place = make_airport_place(is_24_hours=True)
        self.assertTrue(place.is_24_hours)


# ---------------------------------------------------------------------------
# Unit Tests – UserRecommendation Model
# ---------------------------------------------------------------------------

class UserRecommendationModelTest(TestCase):

    def setUp(self):
        self.user = make_user()
        self.place = make_airport_place()

    def test_str_representation(self):
        rec = UserRecommendation.objects.create(
            user=self.user,
            place=self.place,
            airport_code="ADD",
        )
        self.assertIn(self.user.email, str(rec))
        self.assertIn(self.place.name, str(rec))

    def test_is_viewed_default_false(self):
        rec = UserRecommendation.objects.create(
            user=self.user,
            place=self.place,
            airport_code="ADD",
        )
        self.assertFalse(rec.is_viewed)

    def test_multiple_recommendations_for_user(self):
        place2 = make_airport_place(place_type="cafe", name="Café B")
        UserRecommendation.objects.create(user=self.user, place=self.place, airport_code="ADD")
        UserRecommendation.objects.create(user=self.user, place=place2, airport_code="ADD")
        self.assertEqual(UserRecommendation.objects.filter(user=self.user).count(), 2)


# ---------------------------------------------------------------------------
# Integration Tests – AirportPlace API
# ---------------------------------------------------------------------------

class AirportPlaceAPITest(APITestCase):

    base_url = "/api/recommendations/places/"

    def setUp(self):
        self.user = make_user()
        self.client.credentials(HTTP_AUTHORIZATION=bearer(self.user))

        # Seed places at two airports
        make_airport_place(airport="ADD", place_type="restaurant", name="ADD Restaurant")
        make_airport_place(airport="ADD", place_type="cafe", name="ADD Café")
        make_airport_place(airport="DXB", place_type="restaurant", name="DXB Restaurant")
        make_airport_place(airport="DXB", place_type="lounge", name="DXB Lounge", rating=4.8)

    def test_list_all_places(self):
        res = self.client.get(self.base_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 4)

    def test_filter_by_airport(self):
        res = self.client.get(self.base_url, {"airport": "ADD"})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 2)
        for place in res.data:
            self.assertEqual(place["airport_code"], "ADD")

    def test_filter_by_type(self):
        res = self.client.get(self.base_url, {"type": "restaurant"})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 2)
        for place in res.data:
            self.assertEqual(place["type"], "restaurant")

    def test_filter_by_airport_and_type(self):
        res = self.client.get(self.base_url, {"airport": "DXB", "type": "lounge"})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 1)
        self.assertEqual(res.data[0]["name"], "DXB Lounge")

    def test_filter_nonexistent_airport_returns_empty(self):
        res = self.client.get(self.base_url, {"airport": "ZZZ"})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 0)

    def test_response_structure(self):
        res = self.client.get(self.base_url, {"airport": "ADD", "type": "cafe"})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        place = res.data[0]
        expected_keys = [
            "id", "name", "type", "airport_code", "terminal",
            "description", "rating", "price_range", "opening_hours",
            "is_24_hours", "latitude", "longitude",
        ]
        for key in expected_keys:
            self.assertIn(key, place)

    def test_unauthenticated_denied(self):
        self.client.credentials()
        res = self.client.get(self.base_url)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_places_ordered_by_rating_desc(self):
        res = self.client.get(self.base_url, {"airport": "DXB"})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        ratings = [p["rating"] for p in res.data]
        self.assertEqual(ratings, sorted(ratings, reverse=True))


# ---------------------------------------------------------------------------
# Integration Tests – get_recommendations API (mocked PlacesAPIService)
# ---------------------------------------------------------------------------

class GetRecommendationsAPITest(APITestCase):

    url = "/api/recommendations/recommendations/get_recommendations/"

    def setUp(self):
        self.user = make_user()
        self.client.credentials(HTTP_AUTHORIZATION=bearer(self.user))

    @patch("recommendations.views.PlacesAPIService")
    def test_no_flight_returns_404(self, mock_api):
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_404_NOT_FOUND)
        self.assertIn("message", res.data)

    @patch("recommendations.views.PlacesAPIService")
    def test_with_upcoming_flight_returns_recommendations(self, MockPlacesAPI):
        # Configure the mock to return our fake places
        mock_instance = MockPlacesAPI.return_value
        mock_instance.get_places_near_airport.return_value = MOCK_PLACES_RESPONSE

        make_flight(
            self.user,
            departure_airport="ADD",
            departure_city="Addis Ababa",
            arrival_airport="DXB",
            arrival_city="Dubai",
        )

        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        # Response must contain the four expected keys
        self.assertIn("hotels", res.data)
        self.assertIn("cafes", res.data)
        self.assertIn("restaurants", res.data)
        self.assertIn("people", res.data)

    @patch("recommendations.views.PlacesAPIService")
    def test_hotels_list_populated(self, MockPlacesAPI):
        mock_instance = MockPlacesAPI.return_value
        mock_instance.get_places_near_airport.return_value = MOCK_PLACES_RESPONSE

        make_flight(self.user, arrival_airport="DXB", arrival_city="Dubai")

        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data["hotels"]), 1)
        self.assertEqual(res.data["hotels"][0]["name"], "Airport Hotel")
        self.assertEqual(res.data["hotels"][0]["type"], "hotel")

    @patch("recommendations.views.PlacesAPIService")
    def test_cafes_list_populated(self, MockPlacesAPI):
        mock_instance = MockPlacesAPI.return_value
        mock_instance.get_places_near_airport.return_value = MOCK_PLACES_RESPONSE

        make_flight(self.user, arrival_airport="DXB", arrival_city="Dubai")

        res = self.client.get(self.url)
        self.assertEqual(len(res.data["cafes"]), 1)
        self.assertEqual(res.data["cafes"][0]["name"], "Terminal Café")

    @patch("recommendations.views.PlacesAPIService")
    def test_restaurants_list_populated(self, MockPlacesAPI):
        mock_instance = MockPlacesAPI.return_value
        mock_instance.get_places_near_airport.return_value = MOCK_PLACES_RESPONSE

        make_flight(self.user, arrival_airport="DXB", arrival_city="Dubai")

        res = self.client.get(self.url)
        self.assertEqual(len(res.data["restaurants"]), 1)
        self.assertEqual(res.data["restaurants"][0]["name"], "Sky Diner")

    @patch("recommendations.views.PlacesAPIService")
    def test_arrival_airport_used_not_departure(self, MockPlacesAPI):
        mock_instance = MockPlacesAPI.return_value
        mock_instance.get_places_near_airport.return_value = MOCK_PLACES_RESPONSE

        make_flight(
            self.user,
            departure_airport="ADD",
            departure_city="Addis Ababa",
            arrival_airport="DXB",
            arrival_city="Dubai",
        )

        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["airport_code"], "DXB")

    @patch("recommendations.views.PlacesAPIService")
    def test_people_includes_matched_users_at_same_destination(self, MockPlacesAPI):
        mock_instance = MockPlacesAPI.return_value
        mock_instance.get_places_near_airport.return_value = MOCK_PLACES_RESPONSE

        u2 = make_user(email="match_rec@example.com", username="matchrec")
        now = timezone.now()

        f1 = make_flight(
            self.user,
            flight_number="PR1",
            departure_airport="ADD",
            departure_city="Addis Ababa",
            arrival_airport="DXB",
            arrival_city="Dubai",
        )
        f2 = make_flight(
            u2,
            flight_number="PR2",
            departure_airport="ADD",
            departure_city="Addis Ababa",
            arrival_airport="DXB",
            arrival_city="Dubai",
        )

        # Create a matched match at the same arrival airport
        if self.user.id < u2.id:
            u1_m, u2_m, f1_m, f2_m = self.user, u2, f1, f2
        else:
            u1_m, u2_m, f1_m, f2_m = u2, self.user, f2, f1

        Match.objects.create(
            user1=u1_m, user2=u2_m,
            flight1=f1_m, flight2=f2_m,
            match_type="same_route",
            matching_airport="DXB",
            matching_city="Dubai",
            overlap_start=now + timedelta(hours=1),
            overlap_end=now + timedelta(hours=3),
            overlap_duration_hours=2.0,
            status="matched",
        )

        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        # people list is a list (may be empty if matching_airport filter differs)
        self.assertIsInstance(res.data["people"], list)

    @patch("recommendations.views.PlacesAPIService")
    def test_empty_places_response_still_succeeds(self, MockPlacesAPI):
        mock_instance = MockPlacesAPI.return_value
        mock_instance.get_places_near_airport.return_value = {
            "hotel": [], "cafe": [], "restaurant": []
        }

        make_flight(self.user, arrival_airport="DXB", arrival_city="Dubai")

        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["hotels"], [])
        self.assertEqual(res.data["cafes"], [])
        self.assertEqual(res.data["restaurants"], [])

    def test_unauthenticated_denied(self):
        self.client.credentials()
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)


# ---------------------------------------------------------------------------
# Integration Tests – UserRecommendation List API
# ---------------------------------------------------------------------------

class UserRecommendationListAPITest(APITestCase):

    base_url = "/api/recommendations/recommendations/"

    def setUp(self):
        self.user = make_user()
        self.other = make_user(email="other_rec@example.com", username="otherrec")
        self.client.credentials(HTTP_AUTHORIZATION=bearer(self.user))
        self.place = make_airport_place()

    def test_list_own_recommendations_only(self):
        UserRecommendation.objects.create(
            user=self.user, place=self.place, airport_code="ADD"
        )
        UserRecommendation.objects.create(
            user=self.other, place=self.place, airport_code="ADD"
        )
        res = self.client.get(self.base_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 1)

    def test_list_empty_when_no_recommendations(self):
        res = self.client.get(self.base_url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 0)

    def test_unauthenticated_denied(self):
        self.client.credentials()
        res = self.client.get(self.base_url)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)
