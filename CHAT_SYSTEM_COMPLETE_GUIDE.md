# 💬 Chat System - Complete Technical Guide

**Complete analysis of the Nilewing real-time chat system (Backend + Frontend)**

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Backend Implementation](#backend-implementation)
3. [Frontend Implementation](#frontend-implementation)
4. [WebSocket Flow](#websocket-flow)
5. [Message Flow](#message-flow)
6. [Room Management](#room-management)
7. [Features](#features)
8. [Integration Points](#integration-points)

---

## 🏗️ Architecture Overview

### **Tech Stack**

| Component | Technology |
|-----------|------------|
| **Backend** | Django Channels (WebSockets) |
| **Channel Layer** | Redis |
| **Database** | PostgreSQL |
| **Frontend** | Flutter (Dart) |
| **WebSocket Library** | `web_socket_channel` |
| **State Management** | Riverpod |

### **System Flow**

```
Flutter App (Frontend)
    ⇅ WebSocket (wss://)
Django Channels (ASGI)
    ⇅
Redis Channel Layer
    ⇅
PostgreSQL Database
```

---

## 🔧 Backend Implementation

### **1. Models** (`Backend/chat/models.py`)

#### **ChatRoom Model**
```python
class ChatRoom(models.Model):
    id = UUIDField(primary_key=True)  # UUID for unique identification
    name = CharField(max_length=100, unique=True)  # e.g., "personal_16_18"
    description = TextField()
    created_by = ForeignKey(CustomUser)
    created_at = DateTimeField(auto_now_add=True)
    is_active = BooleanField(default=True)
    room_type = CharField(choices=[
        ("group", "Group Chat"),
        ("personal", "Personal Chat"),
    ])
```

**Room Naming Convention:**
- **Personal Chat:** `personal_{user1_id}_{user2_id}` (smaller ID first)
- **Group Chat:** Custom name (e.g., "travel_group_1")

#### **Message Model**
```python
class Message(models.Model):
    id = UUIDField(primary_key=True)
    room = ForeignKey(ChatRoom, related_name="messages")
    user = ForeignKey(CustomUser)
    content = TextField()
    timestamp = DateTimeField(auto_now_add=True)
    message_type = CharField(choices=[
        ("text", "Text"),
        ("image", "Image"),
        ("file", "File"),
    ])
```

#### **UserProfile Model**
```python
class UserProfile(models.Model):
    user = OneToOneField(CustomUser)
    online = BooleanField(default=False)
    last_seen = DateTimeField(auto_now=True)
    avatar = ImageField()
```

---

### **2. WebSocket Consumer** (`Backend/chat/consumers.py`)

#### **Connection Flow**

```python
async def connect(self):
    # 1. Extract room name from URL
    self.room_name = self.scope["url_route"]["kwargs"]["room_name"]
    self.room_group_name = f"chat_{self.room_name}"
    
    # 2. Get JWT token from query string
    token = self.scope.get("query_string").decode().split("token=")[-1]
    
    # 3. Authenticate user from token
    user = await self.get_user_from_token(token)
    
    # 4. Check room access (for personal chats)
    if await self.can_access_room():
        # 5. Join Redis channel group
        await self.channel_layer.group_add(
            self.room_group_name, self.channel_name
        )
        
        # 6. Accept WebSocket connection
        await self.accept()
        
        # 7. Update online status
        await self.update_user_online_status(True)
        
        # 8. Send previous messages
        await self.send_previous_messages()
        
        # 9. Notify others user joined
        await self.channel_layer.group_send(...)
```

#### **Message Handling**

```python
async def receive(self, text_data):
    data = json.loads(text_data)
    message_type = data.get("type")
    
    if message_type == "message":
        await self.handle_message(data)
    elif message_type == "typing":
        await self.handle_typing(data)
    elif message_type == "read_receipt":
        await self.handle_read_receipt(data)
```

#### **Message Broadcasting**

```python
async def handle_message(self, data):
    # 1. Save message to database
    message_obj = await self.save_message(content, message_type)
    
    # 2. Cache message in Redis (async, non-blocking)
    await self.cache_message(message_obj)
    
    # 3. Broadcast to all users in room via Redis channel layer
    await self.channel_layer.group_send(
        self.room_group_name,
        {
            "type": "chat_message",  # Calls chat_message() method
            "message": content,
            "username": self.username,
            "user_id": self.user_id,
            "message_id": str(message_obj.id),
            "timestamp": message_obj.timestamp.isoformat(),
            "message_type": message_type,
            "room_name": self.room_name,
        }
    )

async def chat_message(self, event):
    """Called by Channels for each consumer in the group"""
    await self.send(text_data=json.dumps({
        "type": "message",
        "message": event["message"],
        "username": event["username"],
        "user_id": event["user_id"],
        "message_id": event["message_id"],
        "timestamp": event["timestamp"],
        "message_type": event["message_type"],
        "room_name": event["room_name"],
    }))
```

---

### **3. REST API Views** (`Backend/chat/views.py`)

#### **ChatRoomList** - Get User's Chat Rooms
```python
GET /chat/api/rooms/

# Returns only personal chat rooms for matched users
# Filters by Match.status='matched'
```

**Logic:**
1. Get all matches where `status='matched'`
2. Extract matched user IDs
3. Generate room names: `personal_{min_id}_{max_id}`
4. Return ChatRoom objects for those rooms

#### **CreatePersonalChat** - Create Personal Chat
```python
POST /chat/api/chats/personal/
Body: {"user_id": "123"}

# Validates:
# - User exists
# - Match exists with status='matched'
# - Creates room if doesn't exist
```

**Validation:**
- Checks if Match exists with `status='matched'`
- Rejects if connection not established
- Creates room name: `personal_{min_id}_{max_id}`

#### **MessageList** - Get Messages
```python
GET /chat/api/rooms/{room_id}/messages/?limit=50&offset=0

# Returns messages ordered by timestamp (oldest first)
# Supports pagination
```

---

### **4. WebSocket Routing** (`Backend/chat/routing.py`)

```python
websocket_urlpatterns = [
    re_path(r"ws/chat/(?P<room_name>[\w_-]+)/$", 
            consumers.ChatConsumer.as_asgi()),
]
```

**URL Pattern:** `ws://{host}/ws/chat/{room_name}/?token={jwt_token}`

---

### **5. Redis Caching** (`Backend/chat/redis_client.py`)

**Purpose:** Cache recent messages for fast retrieval

**Operations:**
- `add_to_list()` - Add message to cache
- `get_list()` - Retrieve cached messages
- `ltrim()` - Keep only last 100 messages

**Cache Key Format:** `messages_{room_name}`

---

## 📱 Frontend Implementation

### **1. Chat Service** (`Frontend/nilewing/lib/features/chat/service/chat_service.dart`)

#### **WebSocket Connection**

```dart
Future<WebSocketChannel?> connectToRoom(
  String roomName,
  Function(Map<String, dynamic>) onMessage,
) async {
  // 1. Get JWT token
  final token = await _getAuthToken();
  
  // 2. Build WebSocket URL
  final wsUrl = _buildWebSocketUrl(roomName, token);
  // Format: wss://{host}/ws/chat/{room_name}/?token={token}
  
  // 3. Connect
  final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
  
  // 4. Listen for messages
  channel.stream.listen((message) {
    final data = json.decode(message);
    data['room_name'] = roomName;  // Add room name for routing
    onMessage(data);  // Callback to view model
  });
  
  return channel;
}
```

#### **Send Message via WebSocket**

```dart
void sendWebSocketMessage(String roomName, String message) {
  final channel = _activeConnections[roomName];
  channel.sink.add(json.encode({
    'type': 'message',
    'message': message,
    'message_type': 'text',
  }));
}
```

#### **HTTP Fallback**

```dart
Future<ChatMessage> sendMessageViaHttp(String roomId, String message) async {
  final response = await _httpClient.post(
    Uri.parse('${chatMessagesEndpoint}/$roomId/messages/'),
    body: json.encode({
      'content': message,
      'message_type': 'text'
    }),
  );
  return _messageFromJson(json.decode(response.body));
}
```

---

### **2. Chat ViewModel** (`Frontend/nilewing/lib/features/chat/viewmodel/chat_view_model.dart`)

#### **State Management**

```dart
class ChatState {
  final List<ChatContact> contacts;  // Chat rooms/contacts
  final Map<String, List<ChatMessage>> messages;  // Messages by chat ID
  final String? selectedChatId;
  final bool isLoading;
  final String? error;
  final Map<String, bool> typingUsers;  // Typing indicators
  final Map<String, Set<String>> onlineUsers;  // Online status
}
```

#### **Select Chat Flow**

```dart
Future<void> selectChat(String contactId) async {
  // 1. Get room name from contact ID
  final roomName = await _chatService.getRoomName(contactId);
  
  // 2. Load messages from database (HTTP)
  final messages = await _chatService.getMessages(contactId);
  
  // 3. Update state with loaded messages
  state = state.copyWith(messages: updatedMessages);
  
  // 4. Connect WebSocket for real-time updates
  if (!_chatService.isConnected(roomName)) {
    await _chatService.connectToRoom(roomName, _handleWebSocketMessage);
  }
}
```

#### **Send Message Flow**

```dart
Future<void> sendMessage(String message) async {
  // 1. Add optimistic message to state (immediate UI update)
  final tempId = DateTime.now().millisecondsSinceEpoch.toString();
  final newMessage = ChatMessage(
    id: tempId,
    senderId: 'me',
    content: message,
    timestamp: DateTime.now().toString(),
  );
  
  // Update state immediately
  state = state.copyWith(messages: updatedMessages);
  
  // 2. Try WebSocket first
  try {
    _chatService.sendWebSocketMessage(_currentRoomName!, message);
    messageSent = true;
  } catch (e) {
    // 3. Fallback to HTTP if WebSocket fails
    final savedMessage = await _chatService.sendMessageViaHttp(
      state.selectedChatId!,
      message,
    );
    
    // Replace temp message with saved message
    // Update state with server message ID
  }
}
```

#### **Handle WebSocket Messages**

```dart
void _handleWebSocketMessage(Map<String, dynamic> data) {
  final messageType = data['type'];
  
  if (messageType == 'message') {
    // Find chat ID from room name mapping
    final roomName = data['room_name'];
    final chatId = _roomNameToChatId[roomName] ?? state.selectedChatId;
    
    // Process incoming message
    _processIncomingMessage(chatId, data);
  } else if (messageType == 'typing') {
    // Update typing indicator
    // Auto-clear after 3 seconds
  } else if (messageType == 'user_joined') {
    // Update online status
  } else if (messageType == 'user_left') {
    // Update offline status
  }
}
```

---

### **3. UI Components**

#### **ChatScreen** - Chat List
- Shows all chat contacts
- Filters by search query
- Displays unread counts
- Shows online status

#### **ChatDetailScreen** - Chat Conversation
- Displays messages
- Shows typing indicators
- Sends messages
- Auto-scrolls to bottom
- Handles WebSocket connection

---

## 🔄 WebSocket Flow

### **Connection Sequence**

```
1. Frontend: connectToRoom("personal_16_18")
   ↓
2. Build URL: wss://host/ws/chat/personal_16_18/?token=JWT
   ↓
3. Backend: ChatConsumer.connect()
   ↓
4. Authenticate JWT token
   ↓
5. Check room access (can_access_room)
   ↓
6. Join Redis channel group: "chat_personal_16_18"
   ↓
7. Accept WebSocket connection
   ↓
8. Send previous messages (from Redis cache)
   ↓
9. Notify others: user_joined event
```

### **Message Sending Flow**

```
1. User types message → Frontend
   ↓
2. Add optimistic message to state (immediate UI)
   ↓
3. Try WebSocket send
   ├─ Success → Message sent via WebSocket
   │   ↓
   │   Backend receives → Save to DB → Cache in Redis
   │   ↓
   │   Broadcast to all users in room
   │   ↓
   │   Frontend receives → Update state (replace temp ID)
   │
   └─ Failure → HTTP fallback
       ↓
       POST /chat/api/rooms/{id}/messages/
       ↓
       Backend saves to DB
       ↓
       Frontend updates state with server message
```

### **Message Receiving Flow**

```
1. Backend: User sends message
   ↓
2. Save to database
   ↓
3. Cache in Redis
   ↓
4. Broadcast via Redis channel layer
   ↓
5. All consumers in room group receive event
   ↓
6. Each consumer calls chat_message() method
   ↓
7. Send to connected WebSocket clients
   ↓
8. Frontend receives WebSocket message
   ↓
9. Find chat ID from room name mapping
   ↓
10. Add message to state
    ↓
11. UI updates automatically (Riverpod)
```

---

## 📨 Message Flow

### **Complete Message Lifecycle**

```
┌─────────────────────────────────────────────────────────┐
│                    User Types Message                    │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Frontend: Add Optimistic Message (temp ID)             │
│  - Immediate UI update                                  │
│  - Better UX (no delay)                                 │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Try WebSocket Send                                     │
│  ws://host/ws/chat/{room}/?token={jwt}                  │
└───────┬───────────────────────────────────┬─────────────┘
        │                                   │
        │ Success                          │ Failure
        ▼                                   ▼
┌───────────────────────┐    ┌──────────────────────────────┐
│ Backend: Receive      │    │ HTTP Fallback                │
│ - Validate token       │    │ POST /api/rooms/{id}/messages/│
│ - Check room access    │    │ - Save to DB                 │
│ - Save to DB           │    │ - Return saved message       │
│ - Cache in Redis       │    └──────────┬───────────────────┘
│ - Broadcast to group   │                │
└───────────┬────────────┘                │
            │                              │
            ▼                              ▼
┌─────────────────────────────────────────────────────────┐
│  Redis Channel Layer Broadcasts to All Consumers        │
│  - All users in room receive event                      │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Each Consumer Sends to Connected Clients              │
│  - Including sender (for confirmation)                  │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Frontend: Receive WebSocket Message                    │
│  - Find chat ID from room name                         │
│  - Replace temp message with server message             │
│  - Update state                                         │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  UI Updates Automatically (Riverpod)                    │
│  - Message appears in chat                             │
│  - Scrolls to bottom                                    │
└─────────────────────────────────────────────────────────┘
```

---

## 🏠 Room Management

### **Room Creation**

**Personal Chat:**
1. User accepts connection request (Match status → 'matched')
2. User clicks "Chat" button
3. Frontend calls `createPersonalChat(userId)`
4. Backend validates:
   - Match exists with `status='matched'`
   - User IDs are valid
5. Backend creates room: `personal_{min_id}_{max_id}`
6. Returns ChatRoom object

**Room Name Format:**
- Always smaller ID first: `personal_16_18` (not `personal_18_16`)
- Ensures consistent room name regardless of who creates it

### **Room Access Control**

**Backend Validation:**
```python
async def can_access_room(self):
    # Group chats: allow all
    if not self.room_name.startswith("personal_"):
        return True
    
    # Personal chats: check if user is participant
    parts = self.room_name.split("_")
    if len(parts) == 3:
        user1_id, user2_id = parts[1], parts[2]
        return str(self.user.id) in [user1_id, user2_id]
    return False
```

---

## ✨ Features

### **1. Real-Time Messaging** ✅
- WebSocket-based instant messaging
- HTTP fallback for reliability
- Optimistic UI updates

### **2. Typing Indicators** ✅
```dart
// Send typing indicator
sendTypingIndicator(true);  // User started typing
sendTypingIndicator(false); // User stopped typing

// Auto-clear after 3 seconds
```

### **3. Online Status** ✅
- Updates when user connects/disconnects
- Shows in chat list and detail screen
- Stored in UserProfile model

### **4. Message Caching** ✅
- Redis caches last 100 messages per room
- Fast retrieval on reconnect
- Reduces database queries

### **5. Message History** ✅
- Loads from database on chat selection
- Supports pagination (limit/offset)
- Preserves message order

### **6. Unread Counts** ✅
- Tracks unread messages per chat
- Updates when chat is selected
- Shows badge in chat list

### **7. Connection Management** ✅
- Auto-reconnect logic
- Connection cooldown (prevents spam)
- Graceful fallback to HTTP

---

## 🔗 Integration Points

### **1. Matching System Integration**

**Chat Creation:**
- Only matched users can chat (`Match.status='matched'`)
- Chat button appears after connection accepted
- Validates match before creating room

**Flow:**
```
Match → Connection Request → Both Accept → Match.status='matched' → Chat Available
```

### **2. Authentication Integration**

**JWT Token:**
- WebSocket uses JWT from query string
- Token validated on connection
- User authenticated before room access

**Token Format:**
```
ws://host/ws/chat/{room}/?token={jwt_access_token}
```

### **3. User Profile Integration**

**User Information:**
- Fetches user details for chat contacts
- Caches user info (5 minutes)
- Shows avatar, name, online status

---

## 🐛 Error Handling

### **WebSocket Connection Failures**

**Frontend:**
- Falls back to HTTP for sending messages
- Shows connection error banner
- Allows manual retry

**Backend:**
- Validates token before accepting
- Checks room access
- Closes connection if unauthorized

### **Message Send Failures**

**Frontend:**
- Keeps optimistic message in state
- Shows error message
- Retries via HTTP fallback

**Backend:**
- Returns error if room doesn't exist
- Validates user access
- Saves message even if broadcast fails

---

## 📊 Performance Optimizations

### **1. Message Caching**
- Redis caches last 100 messages
- Fast retrieval on reconnect
- Reduces database load

### **2. User Info Caching**
- Frontend caches user info (5 minutes)
- Reduces API calls
- Improves performance

### **3. Optimistic Updates**
- Immediate UI feedback
- Better perceived performance
- Replaced with server message when received

### **4. Connection Management**
- One WebSocket per room
- Reuses connections
- Prevents connection spam

---

## 🔐 Security

### **Authentication**
- JWT token required for WebSocket
- Token validated on connection
- User must be authenticated

### **Authorization**
- Room access checked before connection
- Personal chats: only participants can access
- Group chats: open to all authenticated users

### **Message Validation**
- Content sanitized
- User verified before saving
- Room access verified

---

## 📝 Summary

### **Backend:**
- ✅ Django Channels WebSocket consumer
- ✅ Redis channel layer for broadcasting
- ✅ PostgreSQL for message persistence
- ✅ JWT authentication
- ✅ Room access control
- ✅ Message caching

### **Frontend:**
- ✅ WebSocket connection management
- ✅ HTTP fallback for reliability
- ✅ Optimistic UI updates
- ✅ Real-time message handling
- ✅ Typing indicators
- ✅ Online status
- ✅ State management with Riverpod

### **Key Features:**
1. ✅ Real-time messaging via WebSocket
2. ✅ HTTP fallback for reliability
3. ✅ Typing indicators
4. ✅ Online/offline status
5. ✅ Message history with pagination
6. ✅ Unread message counts
7. ✅ Integration with matching system
8. ✅ Optimistic UI updates

---

**Status:** Fully functional real-time chat system  
**Last Updated:** Complete technical analysis

