// features/chat/services/chat_service.dart
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:nilewing/core/utils/app_constants.dart';
import 'package:nilewing/core/utils/token_storage.dart';
import 'package:nilewing/core/utils/http_client.dart';
import 'package:nilewing/features/chat/model/chat_model.dart';

// Internal class to track reconnection state
class _ReconnectionState {
  int retryCount = 0;
  bool isRetrying = false;
  DateTime? lastRetryTime;

  static const Duration _initialRetryDelay = Duration(seconds: 1);

  Duration getRetryDelay() {
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s
    final delaySeconds = _initialRetryDelay.inSeconds * (1 << retryCount);
    return Duration(seconds: delaySeconds.clamp(1, 30)); // Max 30 seconds
  }

  void reset() {
    retryCount = 0;
    isRetrying = false;
    lastRetryTime = null;
  }
}

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final TokenStorage _tokenStorage = TokenStorage();
  final HttpClient _httpClient = HttpClient();
  final Map<String, WebSocketChannel?> _activeConnections = {};

  Future<String?> _getAuthToken() async {
    return await _tokenStorage.getAccessToken();
  }

  // Get chat rooms (contacts) - Optimized with batch user info fetching
  Future<List<ChatContact>> getContacts() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _httpClient.get(
        Uri.parse(AppConstants.chatRoomsEndpoint),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('📥 [ChatService] Received ${data.length} chat rooms from API');

        // Batch process contacts for better performance
        final contacts = <ChatContact>[];
        final userInfoFutures = <Future<ChatContact>>[];

        // Process all rooms in parallel
        for (final room in data) {
          userInfoFutures.add(_roomToContact(room));
        }

        // Wait for all contacts to be processed
        contacts.addAll(await Future.wait(userInfoFutures));
        print('✅ [ChatService] Processed ${contacts.length} contacts');

        return contacts;
      }
      print(
        '❌ [ChatService] Failed to load chat rooms: ${response.statusCode} - ${response.body}',
      );
      throw Exception('Failed to load chat rooms: ${response.statusCode}');
    } catch (e) {
      print('❌ [ChatService] Error getting contacts: $e');
      throw Exception('Error getting contacts: $e');
    }
  }

  // Get messages for a room with optional pagination
  Future<List<ChatMessage>> getMessages(
    String roomId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url =
          '${AppConstants.chatMessagesEndpoint}/$roomId/messages/?limit=$limit&offset=$offset';

      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((msg) => _messageFromJson(msg)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Create or get personal chat room
  Future<ChatContact> createPersonalChat(String userId) async {
    try {
      print('💬 [ChatService] Creating personal chat with user ID: $userId');

      // Verify user ID is valid
      if (userId.isEmpty || userId == '0' || userId == 'null') {
        throw Exception('Invalid user ID provided: $userId');
      }

      // Get current user ID to verify we're not chatting with ourselves
      final currentUserData = await _tokenStorage.getUserData();
      final currentUserId = currentUserData?['id']?.toString();

      print('💬 [ChatService] Current user ID: $currentUserId');
      print('💬 [ChatService] Target user ID: $userId');

      if (currentUserId != null && userId == currentUserId) {
        throw Exception(
          'Cannot create chat with yourself. User ID matches current user.',
        );
      }

      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      print(
        '💬 [ChatService] Sending request to create chat with user_id: $userId',
      );
      final response = await _httpClient.post(
        Uri.parse('${AppConstants.chatBaseUrl}/api/chats/personal/'),
        body: json.encode({'user_id': userId}),
      );

      print('📥 [ChatService] Response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return await _roomToContact(data);
      }
      throw Exception('Failed to create chat: ${response.statusCode}');
    } catch (e) {
      print('❌ [ChatService] Error creating personal chat: $e');
      throw Exception('Error creating personal chat: $e');
    }
  }

  // Track connection attempts to prevent infinite loops
  static final Map<String, DateTime> _lastConnectionAttempt = {};
  static const Duration _connectionCooldown = Duration(seconds: 10);

  // Track reconnection state per room
  static final Map<String, _ReconnectionState> _reconnectionStates = {};
  static const int _maxAutoRetries = 5;

  // Connect to WebSocket for a room with reconnection logic
  Future<WebSocketChannel?> connectToRoom(
    String roomName,
    Function(Map<String, dynamic>) onMessage, {
    int retryCount = 0,
    int maxRetries = 3,
    bool isManualRetry = false,
    bool isAutoReconnect = false,
  }) async {
    try {
      // Prevent connection spam - check cooldown
      if (!isManualRetry && _lastConnectionAttempt.containsKey(roomName)) {
        final lastAttempt = _lastConnectionAttempt[roomName]!;
        if (DateTime.now().difference(lastAttempt) < _connectionCooldown) {
          print(
            '⚠️ [ChatService] Connection cooldown active for $roomName, skipping...',
          );
          return null;
        }
      }
      _lastConnectionAttempt[roomName] = DateTime.now();

      // Close existing connection if any
      disconnectFromRoom(roomName);

      // Get token for WebSocket connection
      final token = await _getAuthToken();
      if (token == null) {
        print('⚠️ [ChatService] No auth token available');
        return null;
      }

      // Build WebSocket URL with token
      final wsUrl = _buildWebSocketUrl(roomName, token);

      try {
        final uri = Uri.parse(wsUrl);

        // Validate the URI before connecting
        if (uri.scheme != 'ws' && uri.scheme != 'wss') {
          throw Exception('Invalid WebSocket scheme: ${uri.scheme}');
        }

        if (uri.host.isEmpty) {
          throw Exception('Invalid WebSocket host: empty');
        }

        print('🔌 [ChatService] Attempting WebSocket connection to: $wsUrl');
        final channel = WebSocketChannel.connect(uri);
        _activeConnections[roomName] = channel;

        // Reset reconnection state on successful connection
        _reconnectionStates[roomName]?.reset();

        // Listen for messages in real-time
        channel.stream.listen(
          (message) {
            try {
              final messageStr = message as String;
              print('📨 [ChatService] Received WebSocket message: $messageStr');
              final data = json.decode(messageStr);

              // Add room name to the data so view model knows which chat it belongs to
              data['room_name'] = roomName;

              // Call the callback to handle the message
              onMessage(data);
            } catch (e) {
              print('⚠️ [ChatService] Error parsing WebSocket message: $e');
              print('⚠️ [ChatService] Raw message: $message');
            }
          },
          onError: (error) {
            print('❌ [ChatService] WebSocket error for $roomName: $error');
            _activeConnections.remove(roomName);
            // Attempt automatic reconnection with exponential backoff
            _attemptReconnection(roomName, onMessage);
          },
          onDone: () {
            print('🔌 [ChatService] WebSocket connection closed for $roomName');
            _activeConnections.remove(roomName);
            // Attempt automatic reconnection if this was an established connection
            if (!isAutoReconnect) {
              _attemptReconnection(roomName, onMessage);
            }
          },
          cancelOnError: false, // Keep listening even if there's an error
        );

        print('✅ [ChatService] WebSocket connected successfully to $roomName');
        return channel;
      } catch (e) {
        print('❌ [ChatService] WebSocket connection failed for $roomName: $e');
        _activeConnections.remove(roomName);
        // Only retry once manually, not automatically
        if (retryCount < 1 && isManualRetry) {
          await Future.delayed(Duration(seconds: 2));
          return connectToRoom(
            roomName,
            onMessage,
            retryCount: retryCount + 1,
            isManualRetry: true,
          );
        }
        return null;
      }
    } catch (e) {
      print('❌ [ChatService] Error in connectToRoom: $e');
      return null;
    }
  }

  // Send message via WebSocket
  void sendWebSocketMessage(String roomName, String message) {
    final channel = _activeConnections[roomName];
    if (channel == null) {
      throw Exception('WebSocket not connected for room: $roomName');
    }

    try {
      final messageData = json.encode({
        'type': 'message',
        'message': message,
        'message_type': 'text',
      });
      channel.sink.add(messageData);
    } catch (e) {
      // If sending fails, remove the connection and rethrow
      _activeConnections.remove(roomName);
      throw Exception('Failed to send message: $e');
    }
  }

  // Send call signaling via WebSocket
  void sendCallSignal(String roomName, bool isVideoCall, String type) {
    final channel = _activeConnections[roomName];
    if (channel == null) return;

    try {
      final signalData = json.encode({
        'type': 'call_signal',
        'signal_type': type, // 'offer', 'answer', 'hangup'
        'is_video': isVideoCall,
      });
      channel.sink.add(signalData);
    } catch (e) {
      print('⚠️ [ChatService] Error sending call signal: $e');
    }
  }

  // Send typing indicator via WebSocket
  void sendTypingIndicator(String roomName, bool isTyping) {
    final channel = _activeConnections[roomName];
    if (channel == null) {
      return; // Silently fail if not connected
    }

    try {
      final typingData = json.encode({'type': 'typing', 'typing': isTyping});
      channel.sink.add(typingData);
    } catch (e) {
      print('⚠️ [ChatService] Error sending typing indicator: $e');
    }
  }

  // Send message via HTTP (fallback when WebSocket fails)
  Future<ChatMessage> sendMessageViaHttp(String roomId, String message) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = '${AppConstants.chatMessagesEndpoint}/$roomId/messages/';

      print('📡 [ChatService] Sending message via HTTP to: $url');
      print('📡 [ChatService] Message: $message');

      final response = await _httpClient.post(
        Uri.parse(url),
        body: json.encode({'content': message, 'message_type': 'text'}),
      );

      print('📥 [ChatService] HTTP response status: ${response.statusCode}');
      print('📥 [ChatService] HTTP response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [ChatService] Message saved via HTTP');
        return _messageFromJson(data);
      } else {
        // Log error details
        final errorBody = response.body;
        print('❌ [ChatService] HTTP error response: $errorBody');
        throw Exception(
          'Failed to send message: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      print('❌ [ChatService] Error sending message via HTTP: $e');
      throw Exception('Error sending message via HTTP: $e');
    }
  }

  // Disconnect from room
  void disconnectFromRoom(String roomName) {
    final channel = _activeConnections[roomName];
    if (channel != null) {
      print('🔌 [ChatService] Disconnecting from room: $roomName');
      channel.sink.close();
      _activeConnections.remove(roomName);
    }
    // Reset reconnection state when manually disconnecting
    _reconnectionStates[roomName]?.reset();
  }

  // Attempt automatic reconnection with exponential backoff
  Future<void> _attemptReconnection(
    String roomName,
    Function(Map<String, dynamic>) onMessage,
  ) async {
    // Get or create reconnection state
    final state = _reconnectionStates.putIfAbsent(
      roomName,
      () => _ReconnectionState(),
    );

    // Check if we should retry
    if (state.isRetrying || state.retryCount >= _maxAutoRetries) {
      if (state.retryCount >= _maxAutoRetries) {
        print(
          '⚠️ [ChatService] Max reconnection attempts ($_maxAutoRetries) reached for $roomName. Giving up.',
        );
      }
      return;
    }

    state.isRetrying = true;
    state.retryCount++;
    final delay = state.getRetryDelay();
    state.lastRetryTime = DateTime.now();

    print(
      '🔄 [ChatService] Attempting to reconnect to $roomName (attempt ${state.retryCount}/$_maxAutoRetries) after ${delay.inSeconds}s...',
    );

    // Wait for exponential backoff delay
    await Future.delayed(delay);

    state.isRetrying = false;

    // Attempt reconnection
    try {
      final channel = await connectToRoom(
        roomName,
        onMessage,
        isAutoReconnect: true,
      );

      if (channel == null) {
        // Connection failed, will retry again if under limit
        _attemptReconnection(roomName, onMessage);
      } else {
        print('✅ [ChatService] Successfully reconnected to $roomName');
        state.reset();
      }
    } catch (e) {
      print('❌ [ChatService] Reconnection attempt failed for $roomName: $e');
      // Will retry again if under limit
      _attemptReconnection(roomName, onMessage);
    }
  }

  // Disconnect all
  void disconnectAll() {
    print('🔌 [ChatService] Disconnecting all WebSocket connections');
    for (var roomName in _activeConnections.keys.toList()) {
      disconnectFromRoom(roomName);
    }
    // Clear reconnection states
    _reconnectionStates.clear();
  }

  // Check if WebSocket is connected for a room
  bool isConnected(String roomName) {
    return _activeConnections.containsKey(roomName) &&
        _activeConnections[roomName] != null;
  }

  // Build WebSocket URL
  String _buildWebSocketUrl(String roomName, String token) {
    final baseUrl = AppConstants.baseUrl;
    print('🔌 [ChatService] Base URL: $baseUrl');

    // Determine WebSocket protocol based on base URL
    String wsProtocol = 'wss://';
    String host;
    int? port;

    // Parse the base URL to extract host and port
    if (baseUrl.startsWith('https://')) {
      wsProtocol = 'wss://';
      host = baseUrl.replaceAll('https://', '');
    } else if (baseUrl.startsWith('http://')) {
      wsProtocol = 'ws://';
      host = baseUrl.replaceAll('http://', '');
    } else {
      // Assume https if no protocol specified
      wsProtocol = 'wss://';
      host = baseUrl;
    }

    // Remove any trailing slashes and query strings
    host = host.replaceAll(RegExp(r'/$'), '');
    host = host.split('?').first;

    // Extract port if present
    if (host.contains(':')) {
      final parts = host.split(':');
      host = parts[0];
      try {
        final portNum = int.parse(parts[1]);
        // Only include non-standard ports
        if (portNum != 80 && portNum != 443 && portNum != 0) {
          port = portNum;
        }
      } catch (e) {
        // Invalid port, ignore
      }
    }

    // Port handling is already done above via extraction from host


    // Clean room name (remove any special characters except underscore and hyphen)
    final cleanRoomName = roomName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    // Build WebSocket URL with proper formatting
    final portStr = port != null ? ':$port' : '';
    final wsUrl =
        '$wsProtocol$host$portStr/ws/chat/$cleanRoomName/?token=$token';
    print('🔌 [ChatService] Built WebSocket URL: $wsUrl');
    return wsUrl;
  }

  // Send message (HTTP fallback or WebSocket)
  Future<void> sendMessage(String roomId, String message) async {
    try {
      // Try WebSocket first - get room name
      final roomName = await getRoomName(roomId);
      if (_activeConnections.containsKey(roomName)) {
        sendWebSocketMessage(roomName, message);
        return;
      }

      // Fallback to HTTP
      print(
        '💬 [ChatService] Sending message via HTTP (WebSocket not connected)',
      );
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Note: Backend doesn't have HTTP endpoint for sending messages
      // Messages should be sent via WebSocket
      print(
        '⚠️ [ChatService] WebSocket not connected, message may not be sent',
      );
    } catch (e) {
      print('❌ [ChatService] Error sending message: $e');
      throw Exception('Error sending message: $e');
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String roomId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      print('💬 [ChatService] Marking messages as read for room: $roomId');

      // Call the backend endpoint to mark all messages in the room as read
      final url = '${AppConstants.chatMessagesEndpoint}/$roomId/mark_read/';

      final response = await _httpClient.post(
        Uri.parse(url),
        body: json.encode({}), // Empty body, endpoint doesn't need data
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final markedCount = data['marked_count'] ?? 0;
        print(
          '✅ [ChatService] Marked $markedCount messages as read for room: $roomId',
        );
      } else {
        print(
          '⚠️ [ChatService] Failed to mark messages as read: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ [ChatService] Error marking as read: $e');
      // Don't throw - marking as read is not critical for chat functionality
    }
  }

  // Helper: Convert backend room to frontend contact
  Future<ChatContact> _roomToContact(Map<String, dynamic> room) async {
    try {
      final roomName = room['name']?.toString() ?? '';
      final createdBy = room['created_by'] ?? {};
      final createdById = createdBy['id']?.toString();

      // Get current user ID
      final currentUserData = await _tokenStorage.getUserData();
      final currentUserId = currentUserData?['id']?.toString();

      String name = 'Unknown';
      String? avatar;
      String? partnerUserId;

      // For personal chats, parse the room name to find the other user
      if (roomName.startsWith('personal_')) {
        // Room name format: personal_16_18 (where 16 and 18 are user IDs)
        final parts = roomName.split('_');
        if (parts.length >= 3) {
          final user1Id = parts[1];
          final user2Id = parts[2];

          // Determine which user is the "other" user
          String otherUserId;
          if (currentUserId == user1Id) {
            otherUserId = user2Id;
          } else if (currentUserId == user2Id) {
            otherUserId = user1Id;
          } else {
            // If current user is not in the room name, use the one that's not created_by
            otherUserId = createdById == user1Id ? user2Id : user1Id;
          }
          
          partnerUserId = otherUserId;

          print(
            '💬 [ChatService] Personal chat - Current user: $currentUserId, Other user: $otherUserId',
          );

          // Fetch the other user's information
          if (otherUserId.isNotEmpty) {
            try {
              final otherUserInfo = await _getUserInfo(otherUserId);
              if (otherUserInfo != null) {
                name = otherUserInfo['name'] ?? 'Unknown';
                avatar = otherUserInfo['avatar'];
                print(
                  '💬 [ChatService] Found other user: $name (ID: $otherUserId)',
                );
              } else {
                // Fallback: use description which contains the other user's name
                name = _extractOtherUserNameFromDescription(
                  room['description']?.toString() ?? '',
                  currentUserData,
                );
              }
            } catch (e) {
              print('⚠️ [ChatService] Error fetching other user info: $e');
              // Fallback to description parsing
              name = _extractOtherUserNameFromDescription(
                room['description']?.toString() ?? '',
                currentUserData,
              );
            }
          } else {
            // If we couldn't determine other user ID, use description
            name = _extractOtherUserNameFromDescription(
              room['description']?.toString() ?? '',
              currentUserData,
            );
          }
        }
      } else {
        // For group chats, use created_by or room name
        name = createdBy['first_name'] != null && createdBy['last_name'] != null
            ? '${createdBy['first_name']} ${createdBy['last_name']}'
            : createdBy['username'] ?? roomName;
      }

      // Extract unread_count from API response (backend uses snake_case)
      final unreadCount = room['unread_count'] is int
          ? room['unread_count'] as int
          : (room['unreadCount'] is int ? room['unreadCount'] as int : 0);

      return ChatContact(
        id: room['id']?.toString() ?? '',
        userId: partnerUserId,
        name: name,
        avatar: avatar,
        isOnline: false, // Would need to check UserProfile
        lastMessage: '', // Would need to get last message
        timestamp: _formatTimestamp(room['created_at']),
        unreadCount: unreadCount, // From backend API
        flight: '', // Not in room data
        gate: '', // Not in room data
      );
    } catch (e) {
      print('❌ [ChatService] Error converting room to contact: $e');
      print('❌ [ChatService] Room data: $room');
      // Return a minimal contact to prevent complete failure
      return ChatContact(
        id: room['id']?.toString() ?? 'unknown',
        userId: null,
        name: 'Unknown User',
        avatar: null,
        isOnline: false,
        lastMessage: '',
        timestamp: _formatTimestamp(room['created_at']),
        unreadCount: 0,
        flight: '',
        gate: '',
      );
    }
  }

  // Helper: Extract other user's name from description
  String _extractOtherUserNameFromDescription(
    String description,
    Map<String, dynamic>? currentUserData,
  ) {
    if (description.contains('between')) {
      // Description format: "Personal chat between be and Abrsh" or "Personal chat between be and be"
      final parts = description.split(' and ');
      if (parts.length >= 2) {
        // Get both names
        final firstPart = parts[0]
            .replaceAll('Personal chat between', '')
            .trim();
        final secondPart = parts[1].trim();

        // Get current user's username/name/email for comparison
        final currentUserName =
            currentUserData?['username']?.toString().toLowerCase() ??
            currentUserData?['first_name']?.toString().toLowerCase() ??
            '';
        final currentUserEmail =
            currentUserData?['email']?.toString().toLowerCase() ?? '';

        print('💬 [ChatService] Description: $description');
        print(
          '💬 [ChatService] First part: $firstPart, Second part: $secondPart',
        );
        print(
          '💬 [ChatService] Current user name: $currentUserName, email: $currentUserEmail',
        );

        // Determine which name is NOT the current user
        // Check if first part matches current user (more flexible matching)
        final firstPartLower = firstPart.toLowerCase();
        final secondPartLower = secondPart.toLowerCase();
        final currentUserNameLower = currentUserName.toLowerCase();

        bool firstPartIsCurrentUser = false;
        bool secondPartIsCurrentUser = false;

        // Check various ways the name might match
        if (currentUserNameLower.isNotEmpty) {
          firstPartIsCurrentUser =
              firstPartLower == currentUserNameLower ||
              firstPartLower.contains(currentUserNameLower) ||
              currentUserNameLower.contains(firstPartLower);

          secondPartIsCurrentUser =
              secondPartLower == currentUserNameLower ||
              secondPartLower.contains(currentUserNameLower) ||
              currentUserNameLower.contains(secondPartLower);
        }

        // Also check email prefix
        if (currentUserEmail.isNotEmpty && !firstPartIsCurrentUser) {
          final emailPrefix = currentUserEmail.split('@')[0].toLowerCase();
          firstPartIsCurrentUser =
              firstPartLower == emailPrefix ||
              firstPartLower.contains(emailPrefix) ||
              emailPrefix.contains(firstPartLower);
        }

        if (currentUserEmail.isNotEmpty && !secondPartIsCurrentUser) {
          final emailPrefix = currentUserEmail.split('@')[0].toLowerCase();
          secondPartIsCurrentUser =
              secondPartLower == emailPrefix ||
              secondPartLower.contains(emailPrefix) ||
              emailPrefix.contains(secondPartLower);
        }

        // If both parts match current user (edge case), return the longer one or second part
        if (firstPartIsCurrentUser && secondPartIsCurrentUser) {
          print(
            '💬 [ChatService] Both parts match current user, using second part: "$secondPart"',
          );
          return secondPart.trim();
        } else if (firstPartIsCurrentUser) {
          // First part is current user, so second part is the other user
          print(
            '💬 [ChatService] First part "$firstPart" is current user, using second part: "$secondPart"',
          );
          return secondPart.trim();
        } else if (secondPartIsCurrentUser) {
          // Second part is current user, so first part is the other user
          print(
            '💬 [ChatService] Second part "$secondPart" is current user, using first part: "$firstPart"',
          );
          return firstPart.trim();
        } else {
          // Neither matches, return the second part (usually the other user)
          print(
            '💬 [ChatService] Neither part matches current user, using second part: "$secondPart"',
          );
          return secondPart.trim();
        }
      }
    }

    // Fallback: return a default name
    return 'Unknown User';
  }

  // Helper: Get user information by ID (with caching to reduce API calls)
  static final Map<String, Map<String, dynamic>> _userInfoCache = {};
  static final Map<String, DateTime> _userInfoCacheTime = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  Future<Map<String, dynamic>?> _getUserInfo(String userId) async {
    // Check cache first
    if (_userInfoCache.containsKey(userId)) {
      final cacheTime = _userInfoCacheTime[userId];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheExpiry) {
        return _userInfoCache[userId];
      }
      // Cache expired, remove it
      _userInfoCache.remove(userId);
      _userInfoCacheTime.remove(userId);
    }

    try {
      final token = await _getAuthToken();
      if (token == null) {
        return null;
      }

      final url = '${AppConstants.authBaseUrl}/$userId/user_profile/';

      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data'] ?? data;
        final fullName = userData['fullName']?.toString().trim();
        final firstName = userData['first_name'] ?? '';
        final lastName = userData['last_name'] ?? '';
        final userName =
            fullName ??
            (firstName.isNotEmpty || lastName.isNotEmpty
                ? '$firstName $lastName'.trim()
                : userData['username'] ?? 'Unknown');
        final avatar =
            userData['profileImageUrl'] ?? userData['profile_image_url'];

        final userInfo = {'name': userName, 'avatar': avatar};

        // Cache the result
        _userInfoCache[userId] = userInfo;
        _userInfoCacheTime[userId] = DateTime.now();

        return userInfo;
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  // Helper: Convert backend message to frontend message
  ChatMessage _messageFromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    final userId = user['id']?.toString() ?? '';

    // Get current user ID to determine if message is from me
    _getAuthToken().then((token) {
      if (token != null) {
        // Decode JWT to get user ID (simplified - in production use proper JWT decoder)
        // For now, we'll compare with senderId
      }
    });

    // Store original ISO timestamp for sorting
    final isoTime = json['timestamp']?.toString();
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: userId,
      content: json['content'] ?? '',
      timestamp: _formatTimestamp(isoTime),
      isoTimestamp: isoTime, // Store original ISO timestamp for sorting
      type: _parseMessageType(json['message_type'] ?? 'text'),
    );
  }

  // Helper: Parse message type
  MessageType _parseMessageType(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.location; // Map image to location for now
      case 'file':
        return MessageType.text;
      case 'flight':
        return MessageType.flight;
      case 'location':
        return MessageType.location;
      default:
        return MessageType.text;
    }
  }

  // Helper: Format timestamp
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return 'Just now';
    }
  }

  // Helper: Get room name from room ID
  Future<String> getRoomName(String roomId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Get room details to extract room name
      final response = await _httpClient.get(
        Uri.parse('${AppConstants.chatRoomsEndpoint}$roomId/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['name'] ?? 'room_$roomId';
      }
      return 'room_$roomId';
    } catch (e) {
      print('❌ [ChatService] Error getting room name: $e');
      return 'room_$roomId';
    }
  }

  // Get room ID from room name
  Future<String?> getRoomIdFromName(String roomName) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Get all rooms and find the one with matching name
      final response = await _httpClient.get(
        Uri.parse(AppConstants.chatRoomsEndpoint),
      );

      if (response.statusCode == 200) {
        final List<dynamic> rooms = json.decode(response.body);
        for (final room in rooms) {
          if (room['name']?.toString() == roomName) {
            return room['id']?.toString();
          }
        }
      }
      return null;
    } catch (e) {
      print('❌ [ChatService] Error getting room ID from name: $e');
      return null;
    }
  }
}
