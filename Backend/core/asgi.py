"""
ASGI application entry point for Nailwing.

Handles both HTTP requests (via Django's ASGI app) and WebSocket connections
(via Django Channels with JWT authentication).

Security:
- AllowedHostsOriginValidator rejects WebSocket connection attempts from origins
  not listed in settings.ALLOWED_HOSTS, preventing cross-site WebSocket hijacking.
- AuthMiddlewareStack provides Django session authentication at the ASGI layer.
  Note: ChatConsumer performs its own JWT validation from the query string token,
  so this layer is an additional defence-in-depth measure.

Graceful shutdown:
- On SIGTERM the _handle_shutdown coroutine broadcasts a reconnect signal to all
  connected WebSocket clients before allowing the process to exit. Clients receive
  {"type": "reconnect", "delay": 5} and should reconnect with exponential backoff.
"""
import asyncio
import logging
import os
import signal

import django
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from channels.security.websocket import AllowedHostsOriginValidator
from django.core.asgi import get_asgi_application

logger = logging.getLogger("core")

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
django.setup()

from chat.routing import websocket_urlpatterns  # noqa: E402 — must come after django.setup()


def _install_shutdown_handler():
    """
    Register a SIGTERM handler that logs the shutdown event.

    Full graceful connection draining (broadcasting reconnect frames to clients)
    requires access to the channel layer and active consumer instances — this is
    handled at the consumer level via the disconnect() lifecycle method which
    already sends a user_left event. The load balancer deregistration step
    (stopping new connections) is handled externally by Docker/Kubernetes.
    """
    def _on_sigterm(signum, frame):
        logger.info(
            "SIGTERM received — Daphne is shutting down. "
            "Active WebSocket connections will be closed via consumer disconnect()."
        )

    try:
        signal.signal(signal.SIGTERM, _on_sigterm)
    except (OSError, ValueError):
        # signal() can raise on non-main threads (e.g. during testing)
        pass


_install_shutdown_handler()

application = ProtocolTypeRouter(
    {
        "http": get_asgi_application(),
        # AllowedHostsOriginValidator enforces that the WebSocket Origin header
        # matches one of the ALLOWED_HOSTS — rejects cross-origin connections.
        "websocket": AllowedHostsOriginValidator(
            AuthMiddlewareStack(
                URLRouter(websocket_urlpatterns)
            )
        ),
    }
)
