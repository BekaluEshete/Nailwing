from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    # Allow room names with underscores and hyphens (e.g., personal_16_18)
    re_path(r"ws/chat/(?P<room_name>[\w_-]+)/$", consumers.ChatConsumer.as_asgi()),
]
