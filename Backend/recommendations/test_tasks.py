"""
Tests for recommendations Celery tasks.
CELERY_TASK_ALWAYS_EAGER=True in test_settings makes tasks run synchronously.
"""
from unittest.mock import patch, MagicMock

from django.test import TestCase

from recommendations.tasks import fetch_airport_recommendations

MOCK_PLACES = {
    "hotel": [{"name": "Airport Hotel", "rating": 4.5, "latitude": 25.25,
               "longitude": 55.36, "address": "DXB Terminal 3", "distance": 500,
               "price_range": "$$", "opening_hours": "24/7", "is_24_hours": True,
               "description": "Hotel", "photos": []}],
    "cafe": [],
    "restaurant": [],
}


class FetchAirportRecommendationsTaskTest(TestCase):

    def setUp(self):
        from django.core.cache import cache
        cache.clear()

    @patch("recommendations.places_api_service.PlacesAPIService")
    def test_task_fetches_and_caches_places(self, MockAPI):
        """Task calls PlacesAPIService and stores result in cache."""
        from recommendations.views import _recommendations_cache_key
        from django.core.cache import cache

        mock_instance = MockAPI.return_value
        mock_instance.get_places_near_airport.return_value = MOCK_PLACES

        result = fetch_airport_recommendations.delay("DXB")
        data = result.get()

        self.assertEqual(data["status"], "ok")
        self.assertEqual(data["airport"], "DXB")
        self.assertEqual(data["total_places"], 1)

        cached = cache.get(_recommendations_cache_key("DXB"))
        self.assertIsNotNone(cached)
        self.assertIn("hotel", cached)

    @patch("recommendations.places_api_service.PlacesAPIService")
    def test_task_normalises_airport_code_to_uppercase(self, MockAPI):
        """Task converts lowercase airport code to uppercase."""
        from recommendations.views import _recommendations_cache_key
        from django.core.cache import cache

        mock_instance = MockAPI.return_value
        mock_instance.get_places_near_airport.return_value = MOCK_PLACES

        result = fetch_airport_recommendations.delay("dxb")
        result.get()

        cached = cache.get(_recommendations_cache_key("DXB"))
        self.assertIsNotNone(cached)

    @patch("recommendations.places_api_service.PlacesAPIService")
    def test_task_retries_on_api_failure(self, MockAPI):
        """Task raises Retry or Exception when the API service fails."""
        MockAPI.return_value.get_places_near_airport.side_effect = Exception("API error")
        from celery.exceptions import Retry
        with self.assertRaises((Retry, Exception)):
            fetch_airport_recommendations("DXB")
