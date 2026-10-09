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

    def test_metrics_url_registered_in_urls_module(self):
        """django_prometheus.urls must be included in core/urls.py."""
        import inspect
        import core.urls as urls_module
        source = inspect.getsource(urls_module)
        self.assertIn("django_prometheus", source)


class PrometheusEndpointTest(TestCase):

    def _get_metrics_url(self):
        """
        django-prometheus registers the URL as 'metrics' (no trailing slash).
        Try both forms and return the one that works.
        """
        for url in ("/metrics", "/metrics/"):
            res = self.client.get(url)
            if res.status_code == 200:
                return url, res
        return "/metrics", self.client.get("/metrics")

    def test_metrics_endpoint_accessible(self):
        """GET /metrics returns 200 with Prometheus text format."""
        url, res = self._get_metrics_url()
        self.assertEqual(
            res.status_code, 200,
            f"Expected 200 at {url}, got {res.status_code}. "
            "Check that django_prometheus.urls is included in core/urls.py",
        )

    def test_metrics_response_is_text(self):
        """Prometheus endpoint returns plain text."""
        _, res = self._get_metrics_url()
        if res.status_code == 200:
            self.assertIn("text/plain", res.get("Content-Type", ""))

    def test_metrics_response_contains_prometheus_format(self):
        """Response contains standard Prometheus exposition format markers."""
        _, res = self._get_metrics_url()
        if res.status_code != 200:
            self.skipTest("Metrics endpoint not reachable — skipping content check")
        content = res.content.decode()
        # All Prometheus responses contain HELP comments
        self.assertIn("# HELP", content)

    def test_metrics_response_contains_django_metrics(self):
        """Response contains Django-specific Prometheus counters."""
        _, res = self._get_metrics_url()
        if res.status_code != 200:
            self.skipTest("Metrics endpoint not reachable — skipping content check")
        content = res.content.decode()
        self.assertIn("django_", content)


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

    def test_ws_gauge_inc_dec_does_not_raise(self):
        """Calling inc() and dec() on the gauge does not raise exceptions."""
        from chat.consumers import _ws_connections
        try:
            _ws_connections.inc()
            _ws_connections.dec()
        except Exception as e:
            self.fail(f"Gauge inc/dec raised an exception: {e}")

    def test_ws_gauge_name_in_metrics(self):
        """The custom WebSocket gauge appears in the /metrics output."""
        from chat.consumers import _ws_connections
        _ws_connections.inc()
        _ws_connections.dec()

        # Try both URL forms
        for url in ("/metrics", "/metrics/"):
            res = self.client.get(url)
            if res.status_code == 200:
                content = res.content.decode()
                self.assertIn("nailwing_websocket_connections_active", content)
                return

        self.skipTest("Metrics endpoint not reachable — skipping gauge name check")
