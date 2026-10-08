"""
Health check endpoint.

Returns 200 when the database and Redis cache are reachable.
Returns 503 when any critical dependency is down.

Used by load balancers, Kubernetes liveness/readiness probes, and uptime monitors.
"""
import logging

from django.db import connection, OperationalError as DjangoOperationalError
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework import status

logger = logging.getLogger("core")

# Application version — bump this on each release
APP_VERSION = "1.0.0"


class HealthCheckView(APIView):
    """
    GET /health/

    Checks:
    - Database: executes SELECT 1
    - Redis cache: executes PING via django-redis

    Response 200:
        {"status": "healthy", "database": "ok", "redis": "ok", "version": "1.0.0"}

    Response 503:
        {"status": "unhealthy", "database": "error: ...", "redis": "ok", "version": "1.0.0"}
    """

    permission_classes = [AllowAny]
    # Exempt from throttling — health probes must always get through
    throttle_classes = []

    def get(self, request):
        db_status = self._check_database()
        redis_status = self._check_redis()

        all_healthy = db_status == "ok" and redis_status == "ok"
        http_status = status.HTTP_200_OK if all_healthy else status.HTTP_503_SERVICE_UNAVAILABLE

        if not all_healthy:
            logger.error(
                "Health check failed — database: %s, redis: %s",
                db_status, redis_status,
            )

        return Response(
            {
                "status": "healthy" if all_healthy else "unhealthy",
                "database": db_status,
                "redis": redis_status,
                "version": APP_VERSION,
            },
            status=http_status,
        )

    def _check_database(self):
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
            return "ok"
        except DjangoOperationalError as exc:
            logger.error("Database health check failed: %s", exc)
            return f"error: {exc}"
        except Exception as exc:
            logger.error("Database health check unexpected error: %s", exc)
            return f"error: {exc}"

    def _check_redis(self):
        try:
            from django.core.cache import cache
            cache.set("_health_ping", "pong", timeout=5)
            result = cache.get("_health_ping")
            if result != "pong":
                return "error: unexpected response"
            return "ok"
        except Exception as exc:
            logger.warning("Redis health check failed: %s", exc)
            return f"error: {exc}"
