import json
import jwt
from django.conf import settings
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from authentication.models import CustomUser
from .models import ChatRoom, Message, UserProfile
from .redis_client import redis_client


class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
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
                self.scope["user"] = user
                self.user = user

                # Verify room exists and user can access it
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

                    # Notify others that user joined
                    await self.channel_layer.group_send(
                        self.room_group_name,
                        {
                            "type": "user_joined",
                            "username": user.username,
                            "user_id": str(user.id),
                        },
                    )
                    return

        await self.close()

    async def disconnect(self, close_code):
        if hasattr(self, "user"):
            # Update user online status
            await self.update_user_online_status(False)

            # Notify others that user left
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    "type": "user_left",
                    "username": self.user.username,
                    "user_id": str(self.user.id),
                },
            )

        # Leave room group
        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive(self, text_data):
        try:
            text_data_json = json.loads(text_data)
            message_type = text_data_json.get("type", "message")

            if message_type == "message":
                await self.handle_message(text_data_json)
            elif message_type == "typing":
                await self.handle_typing(text_data_json)
            elif message_type == "read_receipt":
                await self.handle_read_receipt(text_data_json)

        except json.JSONDecodeError:
            await self.send(
                json.dumps({"type": "error", "error": "Invalid JSON format"})
            )
        except Exception as e:
            print(f"Error handling message: {e}")

    async def handle_message(self, data):
        message_content = data["message"]
        message_type = data.get("message_type", "text")

        # Validate message
        if not message_content.strip() or len(message_content) > 1000:
            await self.send(json.dumps({"type": "error", "error": "Invalid message"}))
            return

        # Save message to database
        message_obj = await self.save_message(message_content, message_type)

        # Cache message in Redis
        await self.cache_message(message_obj)

        # Send message to room group
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "chat_message",
                "message": message_content,
                "username": self.user.username,
                "user_id": str(self.user.id),
                "message_id": str(message_obj.id),
                "timestamp": message_obj.timestamp.isoformat(),
                "message_type": message_type,
            },
        )

    async def handle_typing(self, data):
        is_typing = data["typing"]

        await self.channel_layer.group_send(
            self.room_group_name,
            {
                "type": "user_typing",
                "username": self.user.username,
                "user_id": str(self.user.id),
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
                "user_id": str(self.user.id),
                "username": self.user.username,
            },
        )

    async def chat_message(self, event):
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
                }
            )
        )

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
                        "cached": True,
                    }
                )
            )

    @database_sync_to_async
    def get_user_from_token(self, token):
        """Get user from JWT token"""
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
            user_id = payload.get("user_id")
            return CustomUser.objects.get(id=user_id)
        except (jwt.ExpiredSignatureError, jwt.DecodeError, CustomUser.DoesNotExist):
            return None

    @database_sync_to_async
    def can_access_room(self):
        """Check if user can access the room"""
        try:
            room = ChatRoom.objects.get(name=self.room_name, is_active=True)
            # For personal chats, check if user is participant
            if room.name.startswith("personal_"):
                user_ids = room.name.split("_")[1:]
                return str(self.user.id) in user_ids
            return True
        except ChatRoom.DoesNotExist:
            return False

    @database_sync_to_async
    def save_message(self, content, message_type="text"):
        """Save message to database"""
        room = ChatRoom.objects.get(name=self.room_name)
        message = Message.objects.create(
            room=room, user=self.user, content=content, message_type=message_type
        )
        return message

    @database_sync_to_async
    def update_user_online_status(self, online):
        """Update user online status"""
        profile, created = UserProfile.objects.get_or_create(user=self.user)
        profile.online = online
        profile.save()

    async def cache_message(self, message):
        """Cache message in Redis"""
        message_data = {
            "message_id": str(message.id),
            "user_id": str(message.user.id),
            "username": message.user.username,
            "content": message.content,
            "timestamp": message.timestamp.isoformat(),
            "message_type": message.message_type,
        }
        redis_client.add_to_list(f"messages_{self.room_name}", message_data)

        # Keep only last 100 messages in cache
        redis_client.redis_client.ltrim(f"messages_{self.room_name}", 0, 99)
