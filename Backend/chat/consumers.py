import json
import jwt
from django.conf import settings
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        print(" WebSocket CONNECT called")
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
                
                # Join room group
                await self.channel_layer.group_add(
                    self.room_group_name,
                    self.channel_name
                )
                
                await self.accept()
                print(f" Connected to room: {self.room_name}")
                return
        
        # Reject connection if no valid token
        await self.close()
        print(" Connection rejected - no valid token")

    async def disconnect(self, close_code):
        print(" WebSocket DISCONNECT called")
        if hasattr(self, "user") and hasattr(self, "room_group_name"):
            await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive(self, text_data):
        print(f" Received: {text_data}")
        try:
            text_data_json = json.loads(text_data)
            message = text_data_json.get("message", "")
            
            if message.strip():
                await self.channel_layer.group_send(self.room_group_name, {
                    "type": "chat_message", 
                    "message": message,
                    "username": getattr(self, "user", "anonymous").username if hasattr(self, "user") else "anonymous"
                })
                
        except Exception as e:
            print(f"Error processing message: {e}")

    async def chat_message(self, event):
        message = event["message"]
        username = event["username"]
        print(f" Sending message: {message} from {username}")
        
        await self.send(text_data=json.dumps({
            "message": message,
            "username": username
        }))

    @database_sync_to_async
    def get_user_from_token(self, token):
        """Get user from JWT token - LAZY IMPORT"""
        try:
            # Import inside method to avoid circular imports
            from authentication.models import CustomUser
            
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
            user_id = payload.get("user_id")
            return CustomUser.objects.get(id=user_id)
        except (jwt.ExpiredSignatureError, jwt.DecodeError, Exception) as e:
            print(f"Token validation failed: {e}")
            return None
