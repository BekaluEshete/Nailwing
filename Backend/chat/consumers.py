import json
import logging

import jwt
from django.conf import settings
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async

logger = logging.getLogger("chat")


class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        logger.debug("WebSocket CONNECT called")
        self.room_name = self.scope["url_route"]["kwargs"]["room_name"]
        self.room_group_name = f"chat_{self.room_name}"

        # Get token from query string
        query_string = self.scope.get("query_string", b"").decode()
        token = None
        if "token=" in query_string:
            token = query_string.split("token=")[-1]

        if token:
            user = await self.get_user_from_token(token)
            if user:
                self.user = user
                self.user_id = str(user.id)
                self.username = user.username

                if await self.can_access_room():
                    try:
                        await self.channel_layer.group_add(
                            self.room_group_name, self.channel_name
                        )
                        logger.debug("Added to group: %s", self.room_group_name)
                    except Exception as exc:
                        logger.error("Error joining group %s: %s", self.room_group_name, exc)
                        await self.close()
                        return

                    await self.accept()
                    logger.info("WebSocket accepted for user %s in room %s", self.username, self.room_name)

                    await self.update_user_online_status(True)
                    await self.send_previous_messages()

                    try:
                        await self.channel_layer.group_send(
                            self.room_group_name,
                            {
                                "type": "user_joined",
                                "user_id": self.user_id,
                                "username": self.username,
                                "room_name": self.room_name,
                            },
                        )
                        logger.debug("User joined notification sent for %s", self.username)
                    except Exception as exc:
                        logger.warning("Error sending user_joined for %s: %s", self.username, exc)

                    return
                else:
                    await self.close()
                    logger.warning("Access denied to personal room %s for user %s", self.room_name, self.username)
                    return

        await self.close()
        logger.warning("WebSocket connection rejected — no valid token for room %s", self.room_name)

    async def disconnect(self, close_code):
        logger.debug("WebSocket DISCONNECT called (code=%s)", close_code)
        if hasattr(self, "user") and hasattr(self, "room_group_name"):
            await self.update_user_online_status(False)

            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    "type": "user_left",
                    "user_id": self.user_id,
                    "username": self.username,
                    "room_name": self.room_name,
                },
            )

            await self.channel_layer.group_discard(
                self.room_group_name, self.channel_name
            )

    async def receive(self, text_data):
        logger.debug("Received WebSocket data (len=%d)", len(text_data))
        try:
            data = json.loads(text_data)
            message_type = data.get("type", "message")

            if message_type == "message":
                await self.handle_message(data)
            elif message_type == "typing":
                await self.handle_typing(data)
            elif message_type == "read_receipt":
                await self.handle_read_receipt(data)
            elif message_type == "call_signal":
                await self.handle_call_signal(data)

        except Exception as exc:
            logger.error("Error processing WebSocket message: %s", exc)
            await self.send(
                text_data=json.dumps({"type": "error", "error": "Failed to process message"})
            )

    async def handle_message(self, data):
        message_content = data["message"]
        message_type = data.get("message_type", "text")
        client_msg_id = data.get("client_msg_id")  # idempotency key from client

        if not message_content.strip():
            return

        logger.debug(
            "Handling message from %s in room %s: %.50s",
            self.username, self.room_name, message_content,
        )

        message_obj = await self.save_message(message_content, message_type, client_msg_id)
        logger.debug("Message saved to DB with ID: %s", message_obj.id)

        # Cache the message now that we're in async context
        await self.cache_message(message_obj)

        event_data = {
            "type": "chat_message",
            "message": message_content,
            "username": self.username,
            "user_id": self.user_id,
            "message_id": str(message_obj.id),
            "timestamp": message_obj.timestamp.isoformat(),
            "message_type": message_type,
            "room_type": "personal" if self.room_name.startswith("personal_") else "group",
            "room_name": self.room_name,
        }

        try:
            await self.channel_layer.group_send(self.room_group_name, event_data)
            logger.debug("Message broadcasted to group: %s", self.room_group_name)
        except Exception as exc:
            logger.error("Error broadcasting message to group %s: %s", self.room_group_name, exc)
            await self.send(
                text_data=json.dumps({
                    "type": "message",
                    "message": message_content,
                    "username": self.username,
                    "user_id": self.user_id,
                    "message_id": str(message_obj.id),
                    "timestamp": message_obj.timestamp.isoformat(),
                    "message_type": message_type,
                    "room_name": self.room_name,
                })
            )

    async def handle_typing(self, data):
        is_typing = data["typing"]
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "user_typing",
                "user_id": self.user_id,
                "username": self.username,
                "typing": is_typing,
                "room_name": self.room_name,
            },
        )

    async def handle_read_receipt(self, data):
        message_id = data["message_id"]
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "read_receipt",
                "message_id": message_id,
                "user_id": self.user_id,
                "username": self.username,
                "room_name": self.room_name,
            },
        )

    async def handle_call_signal(self, data):
        """Handle video/audio call signaling"""
        signal_type = data.get("signal_type")
        is_video = data.get("is_video", False)

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "call_signal",
                "signal_type": signal_type,
                "is_video": is_video,
                "user_id": self.user_id,
                "username": self.username,
                "room_name": self.room_name,
            },
        )

    async def chat_message(self, event):
        """Broadcast message to all users in the room"""
        message_data = {
            "type": "message",
            "message": event["message"],
            "username": event["username"],
            "user_id": event["user_id"],
            "message_id": event["message_id"],
            "timestamp": event["timestamp"],
            "message_type": event["message_type"],
            "room_type": event["room_type"],
            "room_name": event.get("room_name", self.room_name),
        }
        try:
            await self.send(text_data=json.dumps(message_data))
            logger.debug("Sent message %s to client in room %s", event["message_id"], self.room_name)
        except Exception as exc:
            logger.error("Error sending message to client: %s", exc)

    async def user_joined(self, event):
        try:
            await self.send(
                text_data=json.dumps({
                    "type": "user_joined",
                    "username": event["username"],
                    "user_id": event["user_id"],
                    "room_name": event.get("room_name", self.room_name),
                })
            )
        except Exception as exc:
            logger.error("Error sending user_joined event: %s", exc)

    async def user_left(self, event):
        try:
            await self.send(
                text_data=json.dumps({
                    "type": "user_left",
                    "username": event["username"],
                    "user_id": event["user_id"],
                    "room_name": event.get("room_name", self.room_name),
                })
            )
        except Exception as exc:
            logger.error("Error sending user_left event: %s", exc)

    async def user_typing(self, event):
        try:
            await self.send(
                text_data=json.dumps({
                    "type": "typing",
                    "username": event["username"],
                    "user_id": event["user_id"],
                    "typing": event["typing"],
                    "room_name": self.room_name,
                })
            )
        except Exception as exc:
            logger.error("Error sending typing event: %s", exc)

    async def read_receipt(self, event):
        try:
            await self.send(
                text_data=json.dumps({
                    "type": "read_receipt",
                    "message_id": event["message_id"],
                    "user_id": event["user_id"],
                    "username": event["username"],
                    "room_name": event.get("room_name", self.room_name),
                })
            )
        except Exception as exc:
            logger.error("Error sending read_receipt event: %s", exc)

    async def call_signal(self, event):
        try:
            await self.send(
                text_data=json.dumps({
                    "type": "call_signal",
                    "signal_type": event["signal_type"],
                    "is_video": event["is_video"],
                    "user_id": event["user_id"],
                    "username": event["username"],
                    "room_name": event.get("room_name", self.room_name),
                })
            )
        except Exception as exc:
            logger.error("Error sending call_signal event: %s", exc)

    async def send_previous_messages(self):
        """Send cached messages when user connects"""
        try:
            from .redis_client import redis_client
            cached_messages = redis_client.get_list(f"messages_{self.room_name}", 0, 49)
            for message_data in cached_messages:
                await self.send(
                    text_data=json.dumps({
                        "type": "message",
                        "message": message_data["content"],
                        "username": message_data["username"],
                        "user_id": message_data["user_id"],
                        "message_id": message_data["message_id"],
                        "timestamp": message_data["timestamp"],
                        "message_type": message_data.get("message_type", "text"),
                        "room_type": message_data.get("room_type", "group"),
                        "cached": True,
                    })
                )
        except Exception as exc:
            logger.warning("Error loading previous messages for room %s: %s", self.room_name, exc)

    @database_sync_to_async
    def get_user_from_token(self, token):
        """Get user from JWT token"""
        try:
            from authentication.models import CustomUser
            from rest_framework_simplejwt.tokens import UntypedToken
            from rest_framework_simplejwt.exceptions import InvalidToken, TokenError

            try:
                UntypedToken(token)
            except (InvalidToken, TokenError) as exc:
                logger.warning("Token validation failed: %s", exc)
                return None

            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
            user_id = payload.get("user_id")

            if not user_id:
                logger.warning("No user_id in token payload")
                return None

            return CustomUser.objects.get(id=user_id)
        except (jwt.ExpiredSignatureError, jwt.DecodeError) as exc:
            logger.warning("JWT decode error: %s", exc)
            return None
        except Exception as exc:
            logger.error("Unexpected error in get_user_from_token: %s", exc)
            return None

    @database_sync_to_async
    def can_access_room(self):
        """Check if user can access the room (for personal chats)"""
        if not self.room_name.startswith("personal_"):
            return True
        try:
            parts = self.room_name.split("_")
            if len(parts) == 3:
                user1_id, user2_id = parts[1], parts[2]
                return str(self.user.id) in [user1_id, user2_id]
            return False
        except Exception as exc:
            logger.error("Error checking room access for %s: %s", self.room_name, exc)
            return False

    @database_sync_to_async
    def save_message(self, content, message_type="text", client_msg_id=None):
        """
        Save message to database — idempotent when client_msg_id is provided.
        If client_msg_id already exists (duplicate send), returns the existing
        message instead of creating a new one.
        """
        try:
            from .models import ChatRoom, Message

            room, _ = ChatRoom.objects.get_or_create(
                name=self.room_name,
                defaults={
                    "description": (
                        "Personal chat"
                        if self.room_name.startswith("personal_")
                        else f"Group chat: {self.room_name}"
                    ),
                    "created_by": self.user,
                },
            )

            if client_msg_id:
                # Idempotent: get existing or create new
                message, created = Message.objects.get_or_create(
                    client_msg_id=client_msg_id,
                    defaults={
                        "room": room,
                        "user": self.user,
                        "content": content,
                        "message_type": message_type,
                    },
                )
                if not created:
                    logger.debug(
                        "Duplicate message suppressed (client_msg_id=%s)", client_msg_id
                    )
                return message
            else:
                return Message.objects.create(
                    room=room, user=self.user, content=content, message_type=message_type
                )
        except Exception as exc:
            logger.error("Error saving message in room %s: %s", self.room_name, exc)
            import uuid
            from datetime import datetime

            class MockMessage:
                def __init__(self):
                    self.id = uuid.uuid4()
                    self.timestamp = datetime.now()
                    self.user = self

                    @property
                    def username(inner_self):
                        return "unknown"

            return MockMessage()

    @database_sync_to_async
    def update_user_online_status(self, online):
        """Update user online status"""
        try:
            from .models import UserProfile
            profile, _ = UserProfile.objects.get_or_create(user=self.user)
            profile.online = online
            profile.save()
        except Exception as exc:
            logger.warning("Error updating online status for %s: %s", self.username, exc)

    async def cache_message(self, message):
        """Cache message in Redis — called directly in async context after DB save."""
        try:
            from .redis_client import redis_client

            if not redis_client.available or not redis_client.redis_client:
                return

            message_data = {
                "message_id": str(message.id),
                "user_id": str(message.user.id),
                "username": message.user.username,
                "content": message.content,
                "timestamp": message.timestamp.isoformat(),
                "message_type": message.message_type,
                "room_type": "personal" if self.room_name.startswith("personal_") else "group",
            }
            redis_client.add_to_list(f"messages_{self.room_name}", message_data)
            if redis_client.redis_client:
                redis_client.redis_client.ltrim(f"messages_{self.room_name}", 0, 99)
        except Exception as exc:
            logger.warning("Error caching message in room %s: %s", self.room_name, exc)
