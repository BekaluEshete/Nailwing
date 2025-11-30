# 💬 Chat Feature - Complete Technical Documentation

## 📋 Overview

The chat feature is a real-time messaging system that allows users to communicate with matched travelers. It uses **WebSockets** for real-time communication with **HTTP fallback**, **Redis** for message caching, and integrates with the matching system to ensure only matched users can chat.

---

## 🏗️ Architecture

### **Technology Stack**

- **Backend**: Django + Django Channels (WebSocket support)
- **Frontend**: Flutter with `web_socket_channel` package
- **Real-time**: WebSocket connections via Django Channels
- **Caching**: Redis for message caching
- **Database**: PostgreSQL (via Django ORM)
- **Authentication**: JWT tokens passed via query string for WebSocket connections

---

## 🔧 Backend Implementation

### **1. Models** (`Backend/chat/models.py`)

#### **ChatRoom**

```python
- id: UUID (primary key)
- name: String (unique, e.g., "personal_16_18" for personal chats)
- description: Text
- created_by: ForeignKey to CustomUser
- created_at: DateTime
- is_active: Boolean
- room_type: String (choices: "group" or "personal")
```

**Room Naming Convention:**

- Personal chats: `personal_{user1_id}_{user2_id}` (sorted by ID to ensure uniqueness)
- Group chats: Custom names

#### **Message**

```python
- id: UUID (primary key)
- room: ForeignKey to ChatRoom
- user: ForeignKey to CustomUser (sender)
- content: Text
- timestamp: DateTime (auto-created)
- message_type: String (choices: "text", "image", "file")
```

#### **UserProfile**

```python
- user: OneToOneField to CustomUser
- online: Boolean
- last_seen: DateTime
- avatar: ImageField
```

---

### **2. REST API Endpoints** (`Backend/chat/urls.py`)

All endpoints are prefixed with `/chat/`:

| Endpoint                                   | Method    | Purpose                       |
| ------------------------------------------ | --------- | ----------------------------- |
| `/chat/api/rooms/`                         | GET, POST | List/Create chat rooms        |
| `/chat/api/rooms/<uuid:pk>/`               | GET       | Get room details              |
| `/chat/api/rooms/<uuid:room_id>/messages/` | GET, POST | List/Create messages          |
| `/chat/api/users/search/`                  | GET       | Search users for chat         |
| `/chat/api/chats/personal/`                | POST      | Create/get personal chat room |

**Key Endpoints:**

#### **Create Personal Chat** (`CreatePersonalChat`)

```python
POST /chat/api/chats/personal/
Body: {"user_id": "123"}

Process:
1. Validates both users exist
2. Checks if Match exists with status='matched'
3. Creates unique room name: personal_{min_id}_{max_id}
4. Creates ChatRoom with room_type='personal'
5. Returns ChatRoom data
```

**Security:**

- Requires authentication
- Validates match status (must be 'matched')
- Prevents chat with yourself
- For personal chats, validates user is a participant

#### **Message List** (`MessageList`)

```python
GET /chat/api/rooms/<room_id>/messages/?limit=50&offset=0
- Returns paginated messages in ascending order (oldest first)
- Optimized with select_related to avoid N+1 queries
- Default: 50 messages per page

POST /chat/api/rooms/<room_id>/messages/
Body: {"content": "Hello", "message_type": "text"}
- Creates message via HTTP (fallback when WebSocket fails)
- Validates user has access to room
```

---

### **3. WebSocket Consumer** (`Backend/chat/consumers.py`)

#### **Connection Flow**

```
1. Client connects: ws://base_url/ws/chat/{room_name}/?token={jwt_token}
2. Backend validates JWT token from query string
3. Checks user access (for personal chats, verifies user is participant)
4. Adds user to Django Channels group: "chat_{room_name}"
5. Sends previous cached messages (last 50 from Redis)
6. Updates user online status
```

#### **WebSocket URL Pattern**

```
ws://{baseUrl}/ws/chat/{room_name}/?token={jwt_token}
Example: ws://nilewing-backend.onrender.com/ws/chat/personal_16_18/?token=eyJ0eXAi...
```

#### **Message Types**

**1. Message (`type: "message"`)**

```json
{
  "type": "message",
  "message": "Hello!",
  "message_type": "text"
}
```

- Saves message to database
- Caches in Redis (last 100 messages)
- Broadcasts to all users in room group

**2. Typing Indicator (`type: "typing"`)**

```json
{
  "type": "typing",
  "typing": true
}
```

- Broadcasts typing status to room

**3. Read Receipt (`type: "read_receipt"`)**

```json
{
  "type": "read_receipt",
  "message_id": "uuid"
}
```

- Marks message as read

#### **Message Broadcasting**

When a message is received:

1. Saves to database via `save_message()`
2. Caches in Redis (asynchronously, doesn't block)
3. Broadcasts to room group via `channel_layer.group_send()`
4. All connected clients receive via `chat_message()` handler

**Broadcast Format:**

```json
{
  "type": "message",
  "message": "Hello!",
  "username": "john",
  "user_id": "123",
  "message_id": "uuid",
  "timestamp": "2024-01-01T12:00:00Z",
  "message_type": "text",
  "room_type": "personal"
}
```

#### **Redis Caching**

**Purpose:** Fast retrieval of recent messages when user connects

**Implementation:**

- Messages cached in Redis list: `messages_{room_name}`
- Stores last 100 messages per room
- Format: JSON string with message data
- Retrieved when user connects: `get_list("messages_{room_name}", 0, 49)`

**Caching Flow:**

```
1. Message saved to database
2. Async task caches message in Redis
3. Redis list trimmed to last 100 messages
4. On connection, sends cached messages to client
```

---

### **4. ASGI Configuration** (`Backend/core/asgi.py`)

**WebSocket Routing:**

```python
application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AllowedHostsOriginValidator(
        AuthMiddlewareStack(URLRouter(websocket_urlpatterns))
    ),
})
```

**Security:**

- `AllowedHostsOriginValidator`: Validates origin
- `AuthMiddlewareStack`: Provides authentication context
- Token authentication handled in consumer (not middleware)

---

### **5. Redis Client** (`Backend/chat/redis_client.py`)

**Singleton pattern** for Redis connection:

- Stores/retrieves messages as JSON
- List operations for message caching
- Health check functionality

---

## 📱 Frontend Implementation

### **1. Service Layer** (`Frontend/nilewing/lib/features/chat/service/chat_service.dart`)

**Singleton pattern** - Single instance manages all chat operations.

#### **Key Methods:**

**1. `getContacts()`**

```dart
- Fetches all chat rooms for current user
- GET /chat/api/rooms/
- Converts rooms to ChatContact objects
- For personal chats, fetches other user's info
- Returns List<ChatContact>
```

**2. `getMessages(roomId, {limit, offset})`**

```dart
- Fetches paginated messages from database
- GET /chat/api/rooms/{roomId}/messages/?limit=50&offset=0
- Returns List<ChatMessage>
- Used when opening a chat (loads history)
```

**3. `createPersonalChat(userId)`**

```dart
- Creates personal chat room with another user
- POST /chat/api/chats/personal/ with {"user_id": userId}
- Validates user ID (not self, not empty)
- Returns ChatContact
```

**4. `connectToRoom(roomName, onMessage)`**

```dart
- Establishes WebSocket connection
- URL: ws://{baseUrl}/ws/chat/{roomName}/?token={jwt_token}
- Handles reconnection with exponential backoff (max 3 retries)
- Listens for messages and calls onMessage callback
- Returns WebSocketChannel
```

**5. `sendWebSocketMessage(roomName, message)`**

```dart
- Sends message via WebSocket
- JSON format: {"type": "message", "message": "...", "message_type": "text"}
- Throws exception if WebSocket not connected
```

**6. `sendMessageViaHttp(roomId, message)`**

```dart
- Fallback method when WebSocket fails
- POST /chat/api/rooms/{roomId}/messages/
- Body: {"content": "...", "message_type": "text"}
- Returns ChatMessage (with server-generated ID)
```

**7. `getRoomName(roomId)`**

```dart
- Fetches room details to get room name
- GET /chat/api/rooms/{roomId}/
- Extracts "name" field
- Used to determine WebSocket room name from room ID
```

#### **User Info Caching**

**Purpose:** Reduce API calls when displaying contact names

**Implementation:**

- Static cache: `Map<String, Map<String, dynamic>>`
- Cache expiry: 5 minutes
- Fetches from: `/api/auth/{userId}/user_profile/`

#### **Contact Conversion**

**Personal Chats:**

1. Parses room name: `personal_{user1_id}_{user2_id}`
2. Identifies "other user" (not current user)
3. Fetches other user's info (with caching)
4. Sets contact name/avatar from other user
5. Falls back to description parsing if fetch fails

**Group Chats:**

- Uses room name or created_by user info

---

### **2. ViewModel** (`Frontend/nilewing/lib/features/chat/viewmodel/chat_view_model.dart`)

**State Management:** Riverpod `StateNotifier`

#### **State Structure**

```dart
ChatState {
  List<ChatContact> contacts;          // All chat rooms
  Map<String, List<ChatMessage>> messages;  // Messages by room ID
  String? selectedChatId;              // Currently open chat
  bool isLoading;
  String? error;
}
```

#### **Key Methods:**

**1. `_loadContacts()`**

```dart
- Loads all chat rooms on initialization
- Updates state.contacts
```

**2. `selectChat(contactId)`**

```dart
1. Sets selectedChatId in state
2. Fetches room name from roomId
3. Loads messages from database (GET /chat/api/rooms/{roomId}/messages/)
4. Updates state.messages
5. Connects to WebSocket (non-blocking)
6. Sets up message handler (_handleWebSocketMessage)
7. Marks messages as read
8. Resets unread count
```

**3. `sendMessage(message)`**

```dart
1. Adds message to local state immediately (optimistic update)
2. Generates temporary ID
3. Tries WebSocket first:
   - sendWebSocketMessage(roomName, message)
4. If WebSocket fails, tries HTTP fallback:
   - sendMessageViaHttp(roomId, message)
   - Updates message ID with server response
5. Shows error if both fail
```

**4. `_handleWebSocketMessage(data)`**

```dart
- Handles incoming WebSocket messages
- Checks message type (e.g., "message", "typing")
- For messages:
  - Determines if from current user (senderId == currentUserId)
  - Creates ChatMessage object
  - Adds to state.messages (with duplicate prevention)
  - Updates UI via Riverpod
```

**5. `createPersonalChat(userId)`**

```dart
1. Calls chatService.createPersonalChat(userId)
2. Checks if contact already exists
3. Adds to contacts list if new
4. Selects the new chat automatically
5. Returns ChatContact
```

**6. `clearSelectedChat()`**

```dart
- Disconnects from WebSocket
- Clears selectedChatId
- Called when leaving chat screen
```

---

### **3. UI Components**

#### **ChatScreen** (`Frontend/nilewing/lib/features/chat/view/chat_screen.dart`)

**Purpose:** List of all chats (contacts)

**Features:**

- Search bar (filters contacts by name/flight)
- Active conversations section (online contacts)
- Chat list with:
  - Contact name/avatar
  - Last message preview
  - Timestamp
  - Unread count badge
  - Flight/gate info
- Empty state when no chats

**Navigation:**

- Tapping a contact calls `selectChat(contactId)`
- Shows `ChatDetailScreen` when chat selected

#### **ChatDetailScreen** (`Frontend/nilewing/lib/features/chat/view/chat_detail_screen.dart`)

**Purpose:** Individual chat conversation

**Features:**

- Chat header with contact info
- Message list (scrollable)
- Message input field
- Send button
- Attachment menu (flight info, location)
- Auto-scroll to bottom on new messages
- Error banner if connection issues

**Message Display:**

- Different styling for sent/received
- Sent messages: Right-aligned, gradient background
- Received messages: Left-aligned, gray background
- Shows timestamp and sender info

**Message Sending:**

```dart
1. User types message
2. Presses send or Enter
3. Calls viewModel.sendMessage(message)
4. Message appears immediately (optimistic)
5. Sent to server (WebSocket or HTTP)
```

---

### **4. Models** (`Frontend/nilewing/lib/features/chat/model/chat_model.dart`)

**ChatContact:**

```dart
- id: String (room ID)
- name: String
- avatar: String?
- isOnline: bool
- lastMessage: String
- timestamp: String
- unreadCount: int
- flight: String
- gate: String
```

**ChatMessage:**

```dart
- id: String
- senderId: String ("me" if from current user)
- content: String
- timestamp: String (formatted)
- type: MessageType (text, flight, location)
```

**ChatState:**

```dart
- contacts: List<ChatContact>
- messages: Map<String, List<ChatMessage>>
- selectedChatId: String?
- isLoading: bool
- error: String?
```

---

## 🔄 Complete Message Flow

### **Scenario 1: User A sends message to User B (WebSocket)**

```
1. User A types message → ChatDetailScreen
2. viewModel.sendMessage() called
3. Message added to local state immediately (optimistic)
4. chatService.sendWebSocketMessage(roomName, message) called
5. WebSocket sends: {"type": "message", "message": "...", "message_type": "text"}
6. Backend ChatConsumer.receive() receives message
7. ChatConsumer.handle_message() saves to database
8. Message cached in Redis (async)
9. Backend broadcasts to room group
10. User B's WebSocket receives broadcast
11. chatService.onMessage callback called
12. viewModel._handleWebSocketMessage() processes
13. Message added to User B's state
14. UI updates (Riverpod notifies listeners)
15. User B sees new message
```

### **Scenario 2: WebSocket fails, HTTP fallback**

```
1. User A sends message
2. WebSocket not connected (or send fails)
3. Exception caught in viewModel
4. chatService.sendMessageViaHttp(roomId, message) called
5. POST /chat/api/rooms/{roomId}/messages/
6. Backend saves message to database
7. Returns saved message with server ID
8. viewModel updates local message ID
9. Message persists, but no real-time broadcast
10. User B receives when they reconnect/open chat
```

### **Scenario 3: User opens chat**

```
1. User taps contact in ChatScreen
2. viewModel.selectChat(contactId) called
3. Fetches room name: GET /chat/api/rooms/{roomId}/
4. Loads messages: GET /chat/api/rooms/{roomId}/messages/
5. Messages displayed (from database)
6. WebSocket connection established: ws://.../ws/chat/{roomName}/?token=...
7. Backend validates token
8. Backend sends cached messages (last 50 from Redis)
9. User sees full chat history
10. Real-time updates enabled
```

---

## 🔗 Integration with Matching System

### **Match Requirement**

Users can only create personal chats if:

1. Match exists between the two users
2. Match status is `'matched'` (both users liked each other)

**Backend Validation** (`CreatePersonalChat.create()`):

```python
match = Match.objects.filter(
    user1=user1,
    user2=user2,
    status='matched'
).first()

if not match:
    return Response(
        {"error": "Connection not established..."},
        status=400
    )
```

**Frontend Integration** (`match_detail_screen.dart`):

```dart
// When user taps "Chat" button on match:
1. Verify match.status == 'connected' or 'matched'
2. Call chatViewModel.createPersonalChat(matchedUserId)
3. Navigate to chat screen
```

**Error Handling:**

- If match doesn't exist: "Connection not established. Please send a connection request first."
- If pending: "Connection request not yet accepted. Please wait..."

---

## 🔒 Security Features

### **Authentication**

- All endpoints require JWT token (except WebSocket, uses query param)
- WebSocket: Token passed via query string (`?token=...`)
- HTTP: Token in Authorization header

### **Authorization**

- **Personal Chats:** Validates user is participant (user_id in room name)
- **Message Access:** Validates user can access room before sending/receiving
- **Room Access:** `can_access_room()` checks room name format

### **WebSocket Security**

- Origin validation via `AllowedHostsOriginValidator`
- Token validation in consumer before accepting connection
- Room access check before joining group

---

## 📊 Performance Optimizations

### **Backend**

- `select_related()` to avoid N+1 queries
- Redis caching for recent messages
- Async message caching (doesn't block response)
- Message pagination (50 per page)

### **Frontend**

- Optimistic UI updates (message appears immediately)
- User info caching (5-minute expiry)
- Batch contact processing
- Duplicate message prevention (Set-based)
- WebSocket reconnection with exponential backoff

---

## 🐛 Error Handling

### **Backend**

- Graceful Redis failures (caching is non-critical)
- Mock message if DB save fails
- Connection rejection with clear error messages

### **Frontend**

- WebSocket failure → HTTP fallback
- Connection errors shown in UI banner
- Retry logic with exponential backoff
- Local message persistence on failure

---

## 🔧 Configuration

### **Backend Settings** (`Backend/core/settings.py`)

- Django Channels configured
- Redis URL for channel layers
- CORS settings for WebSocket

### **Frontend Constants** (`Frontend/nilewing/lib/core/utils/app_constants.dart`)

```dart
static const String chatBaseUrl = '$baseUrl/chat';
static const String chatRoomsEndpoint = '$chatBaseUrl/api/rooms/';
static const String chatMessagesEndpoint = '$chatBaseUrl/api/rooms';
```

---

## 📝 Key Files Summary

### **Backend**

- `Backend/chat/models.py` - Database models
- `Backend/chat/views.py` - REST API endpoints
- `Backend/chat/consumers.py` - WebSocket consumer
- `Backend/chat/routing.py` - WebSocket URL patterns
- `Backend/chat/serializers.py` - API serializers
- `Backend/chat/urls.py` - URL routing
- `Backend/chat/redis_client.py` - Redis caching
- `Backend/core/asgi.py` - ASGI configuration

### **Frontend**

- `Frontend/nilewing/lib/features/chat/service/chat_service.dart` - API service
- `Frontend/nilewing/lib/features/chat/viewmodel/chat_view_model.dart` - State management
- `Frontend/nilewing/lib/features/chat/view/chat_screen.dart` - Chat list UI
- `Frontend/nilewing/lib/features/chat/view/chat_detail_screen.dart` - Chat UI
- `Frontend/nilewing/lib/features/chat/model/chat_model.dart` - Data models

---

## 🚀 Future Enhancements

**Potential improvements:**

- Read receipts implementation
- Typing indicators (partial, needs UI)
- Image/file message support (model supports, UI needs)
- Push notifications for new messages
- Message search
- Message reactions
- Group chat support (model supports, needs UI)

---

## 📖 Summary

The chat feature is a **real-time messaging system** that:

1. Uses **WebSockets** for instant communication
2. Falls back to **HTTP** when WebSocket fails
3. Integrates with **matching system** to ensure security
4. Caches messages in **Redis** for fast loading
5. Provides **optimistic UI updates** for better UX
6. Supports **personal chats** (1-on-1) with room-based architecture

The architecture is scalable, secure, and provides a seamless user experience with real-time updates and reliable message delivery.
