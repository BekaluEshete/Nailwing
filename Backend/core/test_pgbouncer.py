"""
Tests for PgBouncer configuration.

Verifies:
- docker-compose.yml contains the pgbouncer service definition
- pgbouncer service uses transaction pool mode (correct for Django)
- pgbouncer service uses the profiles feature (opt-in, not always-on)
- The Neon DATABASE_URL uses the pooler endpoint
"""
import os
from django.test import TestCase


class PgBouncerDockerComposeTest(TestCase):

    def _read_compose(self):
        base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        compose_path = os.path.join(base, "docker-compose.yml")
        with open(compose_path) as f:
            return f.read()

    def test_pgbouncer_service_defined(self):
        """docker-compose.yml must define a pgbouncer service."""
        content = self._read_compose()
        self.assertIn("pgbouncer", content)

    def test_pgbouncer_uses_transaction_pool_mode(self):
        """PgBouncer must use transaction pool mode — required for Django."""
        content = self._read_compose()
        self.assertIn("PGBOUNCER_POOL_MODE: transaction", content)

    def test_pgbouncer_uses_profiles(self):
        """PgBouncer must be opt-in via Docker Compose profiles, not always-on."""
        content = self._read_compose()
        self.assertIn("profiles:", content)

    def test_pgbouncer_max_client_conn_is_high(self):
        """MAX_CLIENT_CONN must be >= 100 to handle concurrent app connections."""
        content = self._read_compose()
        self.assertIn("PGBOUNCER_MAX_CLIENT_CONN", content)
        # Extract the value
        for line in content.splitlines():
            if "PGBOUNCER_MAX_CLIENT_CONN" in line and ":" in line:
                val = line.split(":")[-1].strip().strip('"')
                self.assertGreaterEqual(int(val), 100)
                break

    def test_pgbouncer_exposes_port(self):
        """PgBouncer must expose a port for the app to connect to."""
        content = self._read_compose()
        # We use 5433 to avoid conflict with a local Postgres
        self.assertIn("5433", content)


class NeonPoolerTest(TestCase):

    def test_database_url_uses_neon_pooler(self):
        """
        The current DATABASE_URL should use Neon's built-in pooler endpoint.
        Neon pooler URLs contain '-pooler.' in the hostname.
        This test only runs when DATABASE_URL is set.
        """
        db_url = os.getenv("DATABASE_URL", "")
        if not db_url or "neon.tech" not in db_url:
            self.skipTest("Not using Neon — skipping pooler endpoint check")
        self.assertIn(
            "-pooler.",
            db_url,
            "DATABASE_URL should use Neon's pooler endpoint (*-pooler.*) "
            "for connection pooling. Update your DATABASE_URL to the pooler endpoint.",
        )

    def test_pgbouncer_env_vars_documented(self):
        """PgBouncer env vars must be in settings source for documentation."""
        import inspect
        import core.settings as prod_settings
        source = inspect.getsource(prod_settings)
        # The settings.py should reference the pooling strategy
        self.assertIn("pooler", source.lower())
