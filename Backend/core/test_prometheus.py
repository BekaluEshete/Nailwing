"""
Tests for Prometheus metrics configuration.

Verifies:
- django_prometheus is in INSTALLED_APPS
- PrometheusBeforeMiddleware is first in MIDDLEWARE
- PrometheusAfterMiddleware is last in MIDDLEWARE
- /metrics endpoint is accessible and returns Prometheus format
- WebSocket connection gauge is defined in consumers
"""
from django.test import TestCase
from django.conf import settings


class PrometheusInstalledTest(TestCase):

    def test_django_prometheus_in_installed_apps(self):
        """django_prometheus must be in INSTALLED_APPS."""
        self.assertIn(
            "django_prometheus",
            settings.INSTALLED_APPS,
            "django_prometheus missing from INSTALLED_APPS",
        )

    def test_before_middleware_is_first(self):
        """PrometheusBeforeMiddleware must be the FIRST middleware."""
        self.assertEqual(
            settings.MIDDLEWARE[0],
            "django_prometheus.middleware.PrometheusBeforeMiddleware",
            "PrometheusBeforeMiddleware must be first in MIDDLEWARE to capture all requests",
        )

    def test_after_middleware_is_last(self):
        """PrometheusAfterMiddleware must be the LAST middleware."""
        self.assertEqual(
            settings.MIDDLEWARE[-1],
            "django_prometheus.middleware.PrometheusAfterMiddleware",
            "PrometheusAfterMiddleware must be last in MIDDLEWARE to capture response codes",
        )

    def test_before_and_after_both_present(self):
        """Both Before and After middleware must be present."""
        middleware_str = " ".join(settings.MIDDLEWARE)
        self.assertIn("PrometheusBeforeMiddleware", middleware_str)
        self.assertIn("PrometheusAfterMiddleware", middleware_str)


class PrometheusEndpointTest(TestCase):

    def test_metrics_endpoint_returns_200(self):
        """GET /metrics/ returns 200 with Prometheus text format."""
        res = self.client.get("/metrics/")
        self.assertEqual(res.status_code, 200)

    def test_metrics_response_contains_django_metrics(self):
        """Response body contains standard Django Prometheus metrics."""
        res = self.client.get("/metrics/")
        content = res.content.decode()
        # django-prometheus always exports these counters
        self.assertIn("django_http_requests_total", content)

    def test_metrics_content_type_is_prometheus(self):
        """Response Content-Type should be Prometheus text format."""
        res = self.client.get("/metrics/")
        self.assertIn("text/plain", res.get("Content-Type", ""))


class WebSocketGaugeTest(TestCase):

    def test_ws_connection_gauge_defined(self):
        """Active WebSocket connection gauge must be importable from consumers."""
        from chat.consumers import _ws_connections
        self.assertIsNotNone(_ws_connections)

    def test_ws_gauge_has_inc_and_dec(self):
        """The gauge must have inc() and dec() methods."""
        from chat.consumers import _ws_connections
        self.assertTrue(callable(getattr(_ws_connections, "inc", None)))
        self.assertTrue(callable(getattr(_ws_connections, "dec", None)))

    def test_ws_gauge_name_in_metrics(self):
        """The custom WebSocket gauge appears in the /metrics output."""
        # Trigger a connect + disconnect to ensure the gauge is registered
        from chat.consumers import _ws_connections
        _ws_connections.inc()
        _ws_connections.dec()

        res = self.client.get("/metrics/")
        content = res.content.decode()
        self.assertIn("nailwing_websocket_connections_active", content)
