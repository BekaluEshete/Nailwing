import json
import jwt
from django.conf import settings
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async


class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        print("🔌 WebSocket CONNECT called")
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

                # Check if user can access this room (for personal chats)
                if await self.can_access_room():
                    # Join room group
                    await self.channel_layer.group_add(
                        self.room_group_name, self.channel_name
                    )

                    await self.accept()

                    # Update user online status
                    await self.update_user_online_status(True)

                    # Send last messages
                    await self.send_previous_messages()

                    # Notify others that user joined (only in group chats)
                    if not self.room_name.startswith("personal_"):
                        await self.channel_layer.group_send(
                            self.room_group_name,
                            {
                                "type": "user_joined",
                                "user_id": self.user_id,
                                "username": self.username,
                            },
                        )

                    print(f"✅ {self.username} connected to {self.room_name}")
                    return
                else:
                    await self.close()
                    print(f"❌ Access denied to personal room: {self.room_name}")
                    return

        # Reject connection if no valid token
        await self.close()
        print("❌ Connection rejected - no valid token")

    async def disconnect(self, close_code):
        print("❌ WebSocket DISCONNECT called")
        if hasattr(self, "user") and hasattr(self, "room_group_name"):
            # Update user online status
            await self.update_user_online_status(False)

            # Notify others that user left (only in group chats)
            if not self.room_name.startswith("personal_"):
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {
                        "type": "user_left",
                        "user_id": self.user_id,
                        "username": self.username,
                    },
                )

            await self.channel_layer.group_discard(
                self.room_group_name, self.channel_name
            )

    async def receive(self, text_data):
        print(f"📨 Received: {text_data}")
        try:
            data = json.loads(text_data)
            message_type = data.get("type", "message")

            if message_type == "message":
                await self.handle_message(data)
            elif message_type == "typing":
                await self.handle_typing(data)
            elif message_type == "read_receipt":
                await self.handle_read_receipt(data)

        except Exception as e:
            print(f"Error processing message: {e}")
            await self.send(
                text_data=json.dumps(
                    {"type": "error", "error": "Failed to process message"}
                )
            )

    async def handle_message(self, data):
        message_content = data["message"]
        message_type = data.get("message_type", "text")

        if not message_content.strip():
            return

        # Save message to database (this also caches it)
        message_obj = await self.save_message(message_content, message_type)

        # Send message to room group
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "chat_message",
                "message": message_content,
                "username": self.username,
                "user_id": self.user_id,
                "message_id": str(message_obj.id),
                "timestamp": message_obj.timestamp.isoformat(),
                "message_type": message_type,
                "room_type": (
                    "personal" if self.room_name.startswith("personal_") else "group"
                ),
            },
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
            },
        )

    async def chat_message(self, event):
        """Broadcast message to all users in the room"""
        # Send to all connected clients in this room (including sender)
        # This ensures real-time updates for all users
        await self.send(
            text_data=json.dumps(
                {
                    "type": "message",
                    "message": event["message"],
                    "username": event["username"],
                    "user_id": event["user_id"],
                    "message_id": event["message_id"],
                    "timestamp": event["timestamp"],
                    "message_type": event["message_type"],
                    "room_type": event["room_type"],
                    "room_name": self.room_name,  # Add room name so frontend knows which chat
                }
            )
        )
        print(f"📤 [ChatConsumer] Broadcasted message {event['message_id']} to room {self.room_name}")

    async def user_joined(self, event):
        await self.send(
            text_data=json.dumps(
                {
                    "type": "user_joined",
                    "username": event["username"],
                    "user_id": event["user_id"],
                }
            )
        )

    async def user_left(self, event):
        await self.send(
            text_data=json.dumps(
                {
                    "type": "user_left",
                    "username": event["username"],
                    "user_id": event["user_id"],
                }
            )
        )

    async def user_typing(self, event):
        await self.send(
            text_data=json.dumps(
                {
                    "type": "typing",
                    "username": event["username"],
                    "user_id": event["user_id"],
                    "typing": event["typing"],
                }
            )
        )

    async def read_receipt(self, event):
        await self.send(
            text_data=json.dumps(
                {
                    "type": "read_receipt",
                    "message_id": event["message_id"],
                    "user_id": event["user_id"],
                    "username": event["username"],
                }
            )
        )

    async def send_previous_messages(self):
        """Send cached messages when user connects"""
        try:
            from .redis_client import redis_client

            cached_messages = redis_client.get_list(f"messages_{self.room_name}", 0, 49)

            for message_data in cached_messages:
                await self.send(
                    text_data=json.dumps(
                        {
                            "type": "message",
                            "message": message_data["content"],
                            "username": message_data["username"],
                            "user_id": message_data["user_id"],
                            "message_id": message_data["message_id"],
                            "timestamp": message_data["timestamp"],
                            "message_type": message_data.get("message_type", "text"),
                            "room_type": message_data.get("room_type", "group"),
                            "cached": True,
                        }
                    )
                )
        except Exception as e:
            print(f"Error loading previous messages: {e}")

    @database_sync_to_async
    def get_user_from_token(self, token):
        """Get user from JWT token - LAZY IMPORT"""
        try:
            from authentication.models import CustomUser
            from rest_framework_simplejwt.tokens import UntypedToken
            from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
            from django.contrib.auth import get_user_model

            # Validate token using Simple JWT
            try:
                UntypedToken(token)
            except (InvalidToken, TokenError) as e:
                print(f"Token validation failed: {e}")
                return None

            # Decode token to get user_id
            # Simple JWT uses SECRET_KEY for signing
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
            user_id = payload.get("user_id")
            
            if not user_id:
                print("No user_id in token payload")
                return None
                
            return CustomUser.objects.get(id=user_id)
        except (jwt.ExpiredSignatureError, jwt.DecodeError, Exception) as e:
            print(f"Token validation failed: {e}")
            return None

    @database_sync_to_async
    def can_access_room(self):
        """Check if user can access the room (for personal chats)"""
        # Allow all group chats (non-personal rooms)
        if not self.room_name.startswith("personal_"):
            return True

        # For personal chats: check if user is a participant
        try:
            # personal_1_2 format - check if current user is 1 or 2
            parts = self.room_name.split("_")
            if len(parts) == 3:
                user1_id, user2_id = parts[1], parts[2]
                return str(self.user.id) in [user1_id, user2_id]
            return False
        except Exception as e:
            print(f"Error checking room access: {e}")
            return False

    @database_sync_to_async
    def save_message(self, content, message_type="text"):
        """Save message to database"""
        try:
            from .models import ChatRoom, Message

            # Get or create room (optimized)
            room, created = ChatRoom.objects.get_or_create(
                name=self.room_name,
                defaults={
                    "description": (
                        f"Personal chat"
                        if self.room_name.startswith("personal_")
                        else f"Group chat: {self.room_name}"
                    ),
                    "created_by": self.user,
                },
            )
            message = Message.objects.create(
                room=room, user=self.user, content=content, message_type=message_type
            )
            
            # Cache message in Redis asynchronously (don't wait)
            # This improves response time
            import asyncio
            asyncio.create_task(self.cache_message(message))
            
            return message
        except Exception as e:
            print(f"Error saving message: {e}")
            # Return a mock message if DB save fails
            import uuid
            from datetime import datetime

            class MockMessage:
                def __init__(self):
                    self.id = uuid.uuid4()
                    self.timestamp = datetime.now()

            return MockMessage()

    @database_sync_to_async
    def update_user_online_status(self, online):
        """Update user online status"""
        try:
            from .models import UserProfile

            profile, created = UserProfile.objects.get_or_create(user=self.user)
            profile.online = online
            profile.save()
        except Exception as e:
            print(f"Error updating online status: {e}")

    async def cache_message(self, message):
        """Cache message in Redis asynchronously"""
        try:
            from .redis_client import redis_client

            message_data = {
                "message_id": str(message.id),
                "user_id": str(message.user.id),
                "username": message.user.username,
                "content": message.content,
                "timestamp": message.timestamp.isoformat(),
                "message_type": message.message_type,
                "room_type": (
                    "personal" if self.room_name.startswith("personal_") else "group"
                ),
            }
            # Use async Redis operations if available, otherwise sync
            redis_client.add_to_list(f"messages_{self.room_name}", message_data)
            # Keep only last 100 messages in cache
            redis_client.redis_client.ltrim(f"messages_{self.room_name}", 0, 99)
        except Exception:
            # Silently fail caching - not critical
            pass
