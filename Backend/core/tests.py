"""
Core app tests — health check endpoint and API docs
"""
from unittest.mock import patch, MagicMock
from django.test import TestCase
from rest_framework.test import APITestCase
from rest_framework import status


class HealthCheckTest(APITestCase):

    url = "/health/"

    def test_health_check_returns_200_when_healthy(self):
        """Both DB and Redis up → 200 healthy."""
        with patch("core.health.HealthCheckView._check_redis", return_value="ok"):
            res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["status"], "healthy")
        self.assertEqual(res.data["database"], "ok")
        self.assertEqual(res.data["redis"], "ok")

    def test_health_check_returns_503_when_db_down(self):
        """DB unavailable → 503 unhealthy."""
        with patch("core.health.HealthCheckView._check_database", return_value="error: connection refused"):
            with patch("core.health.HealthCheckView._check_redis", return_value="ok"):
                res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)
        self.assertEqual(res.data["status"], "unhealthy")

    def test_health_check_returns_503_when_redis_down(self):
        """Redis unavailable → 503 unhealthy."""
        with patch("core.health.HealthCheckView._check_redis", return_value="error: connection refused"):
            res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)
        self.assertEqual(res.data["status"], "unhealthy")

    def test_health_check_includes_version(self):
        """Response always includes version field."""
        with patch("core.health.HealthCheckView._check_redis", return_value="ok"):
            res = self.client.get(self.url)
        self.assertIn("version", res.data)

    def test_health_check_no_auth_required(self):
        """Health endpoint is public — no JWT needed."""
        # No credentials set
        with patch("core.health.HealthCheckView._check_redis", return_value="ok"):
            res = self.client.get(self.url)
        self.assertNotEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_health_check_not_throttled(self):
        """Health endpoint has no throttle classes."""
        from core.health import HealthCheckView
        view = HealthCheckView()
        self.assertEqual(view.throttle_classes, [])

    def test_database_check_runs_select_1(self):
        """_check_database executes a real SELECT 1 against test DB."""
        from core.health import HealthCheckView
        view = HealthCheckView()
        result = view._check_database()
        self.assertEqual(result, "ok")

    def test_redis_check_uses_cache(self):
        """_check_redis sets and gets a key via Django cache."""
        from core.health import HealthCheckView
        view = HealthCheckView()
        # In test_settings, cache is LocMem — should still pass
        result = view._check_redis()
        self.assertEqual(result, "ok")


class APIDocsTest(APITestCase):

    def test_schema_endpoint_accessible(self):
        """OpenAPI schema endpoint returns 200."""
        res = self.client.get("/api/schema/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)

    def test_swagger_ui_accessible(self):
        """Swagger UI endpoint returns 200."""
        res = self.client.get("/api/docs/")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
