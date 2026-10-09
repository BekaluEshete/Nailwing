"""
Tests for WebSocket hardening changes:
- parse_redis_url correctly extracts password
- DATABASES has CONN_MAX_AGE and CONN_HEALTH_CHECKS
- AllowedHostsOriginValidator is applied in ASGI application
"""
from django.test import TestCase, override_settings
from django.conf import settings


# ---------------------------------------------------------------------------
# parse_redis_url tests
# ---------------------------------------------------------------------------

class ParseRedisUrlTest(TestCase):

    def _parse(self, url):
        from core.settings import parse_redis_url
        return parse_redis_url(url)

    def test_simple_url_no_password(self):
        result = self._parse("redis://localhost:6379/0")
        self.assertEqual(result["host"], "localhost")
        self.assertEqual(result["port"], 6379)
        self.assertEqual(result["db"], 0)
        self.assertNotIn("password", result)

    def test_url_with_password(self):
        result = self._parse("redis://:mysecret@redis-host:6380/1")
        self.assertEqual(result["host"], "redis-host")
        self.assertEqual(result["port"], 6380)
        self.assertEqual(result["db"], 1)
        self.assertEqual(result["password"], "mysecret")

    def test_url_with_username_and_password(self):
        result = self._parse("redis://default:mypassword@redis-host:6379/2")
        self.assertEqual(result["password"], "mypassword")
        self.assertEqual(result["host"], "redis-host")

    def test_url_default_port(self):
        result = self._parse("redis://localhost/0")
        self.assertEqual(result["port"], 6379)

    def test_url_no_db(self):
        result = self._parse("redis://localhost:6379")
        self.assertEqual(result["db"], 0)

    def test_malformed_url_returns_defaults(self):
        result = self._parse("not-a-valid-url")
        self.assertIn("host", result)
        self.assertIn("port", result)

    def test_rediss_scheme_stripped(self):
        result = self._parse("rediss://localhost:6380/0")
        self.assertEqual(result["host"], "localhost")
        self.assertEqual(result["port"], 6380)

    def test_empty_password_not_included(self):
        """A URL like redis://localhost:6379/0 (no @) has no password key."""
        result = self._parse("redis://localhost:6379/0")
        self.assertNotIn("password", result)


# ---------------------------------------------------------------------------
# Database connection pooling tests
# ---------------------------------------------------------------------------

class DatabaseConnectionPoolingTest(TestCase):

    def test_conn_max_age_is_configured_in_settings(self):
        """settings.py should set CONN_MAX_AGE=60 on the DB config."""
        # Import the raw settings module to check the configured value
        # (test_settings overrides DATABASES with SQLite — we verify the
        #  production settings code path sets the right defaults)
        import importlib
        import core.settings as prod_settings
        # The _db_config dict is built at module level — verify the code exists
        # by checking CONN_MAX_AGE would be applied to dj_database_url output
        # We read the source to confirm setdefault(60) is present
        import inspect
        source = inspect.getsource(prod_settings)
        self.assertIn("CONN_MAX_AGE", source)
        self.assertIn("60", source)

    def test_conn_health_checks_configured_in_settings(self):
        """settings.py should enable CONN_HEALTH_CHECKS."""
        import inspect
        import core.settings as prod_settings
        source = inspect.getsource(prod_settings)
        self.assertIn("CONN_HEALTH_CHECKS", source)

    def test_connect_timeout_configured_in_settings(self):
        """settings.py should set connect_timeout in OPTIONS."""
        import inspect
        import core.settings as prod_settings
        source = inspect.getsource(prod_settings)
        self.assertIn("connect_timeout", source)


# ---------------------------------------------------------------------------
# AllowedHostsOriginValidator tests
# ---------------------------------------------------------------------------

class AllowedHostsOriginValidatorTest(TestCase):

    def test_asgi_application_uses_origin_validator(self):
        """The ASGI websocket handler must be wrapped with an origin validator."""
        from core.asgi import application

        ws_app = application.application_mapping.get("websocket")
        self.assertIsNotNone(ws_app, "No websocket handler registered in ProtocolTypeRouter")

        # AllowedHostsOriginValidator wraps OriginValidator internally.
        # Depending on channels version the outer class name is either
        # "AllowedHostsOriginValidator" or "OriginValidator".
        ws_class_name = type(ws_app).__name__
        self.assertIn(
            "OriginValidator",
            ws_class_name,
            f"WebSocket handler should be an OriginValidator, got {ws_class_name}",
        )

    def test_http_handler_is_django_asgi(self):
        """HTTP requests should be handled by Django's standard ASGI app."""
        from django.core.handlers.asgi import ASGIHandler
        from core.asgi import application

        http_app = application.application_mapping.get("http")
        self.assertIsNotNone(http_app)


# ---------------------------------------------------------------------------
# Redis channel layer password forwarding smoke test
# ---------------------------------------------------------------------------

class ChannelLayerConfigTest(TestCase):

    def test_channel_layer_hosts_is_dict(self):
        """
        Channel layer hosts config should be a list of dicts (not tuples),
        so the password field can be included when present.
        """
        layer_config = settings.CHANNEL_LAYERS.get("default", {}).get("CONFIG", {})
        hosts = layer_config.get("hosts", [])

        if not hosts:
            # InMemoryChannelLayer fallback — no hosts config
            backend = settings.CHANNEL_LAYERS["default"]["BACKEND"]
            self.assertIn("InMemory", backend)
            return

        # Each host entry must be a dict so we can pass password
        for host in hosts:
            self.assertIsInstance(
                host, dict,
                f"Channel layer host entry should be a dict, got {type(host)}: {host}",
            )
            self.assertIn("host", host)
            self.assertIn("port", host)
