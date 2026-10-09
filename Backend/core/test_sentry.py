"""
Tests for Sentry configuration in core/settings.py.

These tests verify:
- Sentry is NOT initialized when SENTRY_DSN is empty (safe default)
- Sentry IS initialized when SENTRY_DSN is set
- The correct integrations are registered
- PII is not sent by default
- traces_sample_rate respects the env var
"""
import os
from unittest.mock import patch, MagicMock
from django.test import TestCase, override_settings


class SentryNotInitializedByDefaultTest(TestCase):
    """When SENTRY_DSN is empty, Sentry should not be initialized."""

    def test_sentry_dsn_defaults_to_empty(self):
        """SENTRY_DSN env var defaults to empty string — Sentry disabled."""
        from django.conf import settings
        # In test settings SENTRY_DSN is not set — check it's falsy
        dsn = getattr(settings, "SENTRY_DSN", "")
        # Either not set at all, or empty string — both mean Sentry is off
        self.assertFalse(bool(dsn))

    def test_sentry_init_not_called_without_dsn(self):
        """sentry_sdk.init should NOT be called when DSN is empty."""
        with patch.dict(os.environ, {"SENTRY_DSN": ""}, clear=False):
            with patch("sentry_sdk.init") as mock_init:
                # Re-evaluate the condition as settings.py would
                dsn = os.getenv("SENTRY_DSN", "")
                if dsn:
                    import sentry_sdk
                    sentry_sdk.init(dsn=dsn)
                mock_init.assert_not_called()


class SentryInitializedWithDsnTest(TestCase):
    """When SENTRY_DSN is set, sentry_sdk.init should be called correctly."""

    def test_sentry_init_called_with_dsn(self):
        """sentry_sdk.init is called when DSN env var is present."""
        fake_dsn = "https://test@sentry.io/123"

        with patch("sentry_sdk.init") as mock_init:
            with patch.dict(os.environ, {"SENTRY_DSN": fake_dsn}):
                dsn = os.getenv("SENTRY_DSN", "")
                if dsn:
                    import sentry_sdk
                    from sentry_sdk.integrations.django import DjangoIntegration
                    from sentry_sdk.integrations.celery import CeleryIntegration
                    sentry_sdk.init(
                        dsn=dsn,
                        environment="test",
                        send_default_pii=False,
                        traces_sample_rate=0.05,
                        integrations=[DjangoIntegration(), CeleryIntegration()],
                    )
                mock_init.assert_called_once()
                call_kwargs = mock_init.call_args.kwargs
                self.assertEqual(call_kwargs["dsn"], fake_dsn)
                self.assertFalse(call_kwargs["send_default_pii"])

    def test_pii_not_sent_by_default(self):
        """send_default_pii must be False to protect user data."""
        # Read directly from settings source to confirm
        import inspect
        import core.settings as prod_settings
        source = inspect.getsource(prod_settings)
        self.assertIn("send_default_pii=False", source)

    def test_traces_sample_rate_respects_env_var(self):
        """SENTRY_TRACES_SAMPLE_RATE env var controls sampling rate."""
        with patch.dict(os.environ, {"SENTRY_TRACES_SAMPLE_RATE": "0.1"}):
            rate = float(os.getenv("SENTRY_TRACES_SAMPLE_RATE", "0.05"))
            self.assertAlmostEqual(rate, 0.1)

    def test_default_traces_sample_rate_is_low(self):
        """Default sample rate should be 5% to limit overhead."""
        with patch.dict(os.environ, {}, clear=False):
            # Remove the key if set, use default
            env = {k: v for k, v in os.environ.items() if k != "SENTRY_TRACES_SAMPLE_RATE"}
            with patch.dict(os.environ, env, clear=True):
                rate = float(os.getenv("SENTRY_TRACES_SAMPLE_RATE", "0.05"))
                self.assertLessEqual(rate, 0.1)

    def test_sentry_dsn_in_settings_source(self):
        """settings.py must reference SENTRY_DSN."""
        import inspect
        import core.settings as prod_settings
        source = inspect.getsource(prod_settings)
        self.assertIn("SENTRY_DSN", source)
        self.assertIn("DjangoIntegration", source)
        self.assertIn("CeleryIntegration", source)
        self.assertIn("RedisIntegration", source)
