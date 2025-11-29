// features/chat/services/chat_service.dart
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:nilewing/core/utils/app_constants.dart';
import 'package:nilewing/core/utils/token_storage.dart';
import 'package:nilewing/core/utils/http_client.dart';
import 'package:nilewing/features/chat/model/chat_model.dart';

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
        
        // Batch process contacts for better performance
        final contacts = <ChatContact>[];
        final userInfoFutures = <Future<ChatContact>>[];
        
        // Process all rooms in parallel
        for (final room in data) {
          userInfoFutures.add(_roomToContact(room));
        }
        
        // Wait for all contacts to be processed
        contacts.addAll(await Future.wait(userInfoFutures));
        
        return contacts;
      }
      throw Exception('Failed to load chat rooms: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting contacts: $e');
    }
  }

  // Get messages for a room with optional pagination
  Future<List<ChatMessage>> getMessages(String roomId, {int limit = 50, int offset = 0}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = '${AppConstants.chatMessagesEndpoint}/$roomId/messages/?limit=$limit&offset=$offset';

      final response = await _httpClient.get(
        Uri.parse(url),
      );

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
        throw Exception('Cannot create chat with yourself. User ID matches current user.');
      }
      
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      print('💬 [ChatService] Sending request to create chat with user_id: $userId');
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

  // Connect to WebSocket for a room with reconnection logic
  Future<WebSocketChannel?> connectToRoom(
    String roomName,
    Function(Map<String, dynamic>) onMessage, {
    int retryCount = 0,
    int maxRetries = 3,
  }) async {
    try {
      // Close existing connection if any
      disconnectFromRoom(roomName);

      // Get token for WebSocket connection
      final token = await _getAuthToken();
      if (token == null) {
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
        
        final channel = WebSocketChannel.connect(uri);
        _activeConnections[roomName] = channel;

        // Listen for messages
        channel.stream.listen(
          (message) {
            try {
              final data = json.decode(message as String);
              onMessage(data);
            } catch (e) {
              // Silently handle parse errors
            }
          },
          onError: (error) {
            _activeConnections.remove(roomName);
            // Attempt reconnection with exponential backoff
            if (retryCount < maxRetries) {
              Future.delayed(Duration(seconds: 2 * (retryCount + 1)), () {
                connectToRoom(roomName, onMessage, retryCount: retryCount + 1);
              });
            }
          },
          onDone: () {
            _activeConnections.remove(roomName);
            // Attempt reconnection if not manually disconnected
            if (retryCount < maxRetries) {
              Future.delayed(Duration(seconds: 2 * (retryCount + 1)), () {
                connectToRoom(roomName, onMessage, retryCount: retryCount + 1);
              });
            }
          },
        );

        return channel;
      } catch (e) {
        _activeConnections.remove(roomName);
        // Retry with exponential backoff
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
          return connectToRoom(roomName, onMessage, retryCount: retryCount + 1);
        }
        return null;
      }
    } catch (e) {
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
        body: json.encode({
          'content': message,
          'message_type': 'text',
        }),
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
        throw Exception('Failed to send message: ${response.statusCode} - $errorBody');
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
  }

  // Disconnect all
  void disconnectAll() {
    print('🔌 [ChatService] Disconnecting all WebSocket connections');
    for (var roomName in _activeConnections.keys.toList()) {
      disconnectFromRoom(roomName);
    }
  }

  // Build WebSocket URL
  String _buildWebSocketUrl(String roomName, String token) {
    final baseUrl = AppConstants.baseUrl;
    print('🔌 [ChatService] Base URL: $baseUrl');
    
    // Determine WebSocket protocol based on base URL
    String wsProtocol = 'wss://';
    String host;
    
    // Parse the base URL to extract host
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
    
    // Remove any trailing slashes
    host = host.replaceAll(RegExp(r'/$'), '');
    
    // Remove port if it's 0 or default ports (for cloud services)
    // Cloud services like Render don't need explicit ports
    if (host.contains(':0') || host.contains(':80') || host.contains(':443')) {
      host = host.split(':')[0];
    }
    
    // For cloud services, ensure no port is included
    if (host.contains('onrender.com') || 
        host.contains('herokuapp.com') ||
        host.contains('railway.app')) {
      // Remove any port that might be in the host
      final parts = host.split(':');
      if (parts.length > 1) {
        host = parts[0];
      }
    }

    // Clean room name (remove any special characters except underscore and hyphen)
    final cleanRoomName = roomName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    
    // Build WebSocket URL
    final wsUrl = '$wsProtocol$host/ws/chat/$cleanRoomName/?token=$token';
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
      print('💬 [ChatService] Sending message via HTTP (WebSocket not connected)');
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Note: Backend doesn't have HTTP endpoint for sending messages
      // Messages should be sent via WebSocket
      print('⚠️ [ChatService] WebSocket not connected, message may not be sent');
    } catch (e) {
      print('❌ [ChatService] Error sending message: $e');
      throw Exception('Error sending message: $e');
    }
  }

  // Mark messages as read
  Future<void> markAsRead(String roomId) async {
    try {
      // This would be implemented if backend has read receipt endpoint
      print('💬 [ChatService] Marking messages as read for room: $roomId');
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('❌ [ChatService] Error marking as read: $e');
    }
  }

  // Helper: Convert backend room to frontend contact
  Future<ChatContact> _roomToContact(Map<String, dynamic> room) async {
    final roomName = room['name']?.toString() ?? '';
    final createdBy = room['created_by'] ?? {};
    final createdById = createdBy['id']?.toString();
    
    // Get current user ID
    final currentUserData = await _tokenStorage.getUserData();
    final currentUserId = currentUserData?['id']?.toString();
    
    String name = 'Unknown';
    String? avatar;
    
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
        
        print('💬 [ChatService] Personal chat - Current user: $currentUserId, Other user: $otherUserId');
        
        // Fetch the other user's information
        if (otherUserId.isNotEmpty) {
          try {
            final otherUserInfo = await _getUserInfo(otherUserId);
            if (otherUserInfo != null) {
              name = otherUserInfo['name'] ?? 'Unknown';
              avatar = otherUserInfo['avatar'];
              print('💬 [ChatService] Found other user: $name (ID: $otherUserId)');
            } else {
              // Fallback: use description which contains the other user's name
              name = _extractOtherUserNameFromDescription(room['description']?.toString() ?? '', currentUserData);
            }
          } catch (e) {
            print('⚠️ [ChatService] Error fetching other user info: $e');
            // Fallback to description parsing
            name = _extractOtherUserNameFromDescription(room['description']?.toString() ?? '', currentUserData);
          }
        } else {
          // If we couldn't determine other user ID, use description
          name = _extractOtherUserNameFromDescription(room['description']?.toString() ?? '', currentUserData);
        }
      }
    } else {
      // For group chats, use created_by or room name
      name = createdBy['first_name'] != null && createdBy['last_name'] != null
          ? '${createdBy['first_name']} ${createdBy['last_name']}'
          : createdBy['username'] ?? roomName;
    }
    
    return ChatContact(
      id: room['id']?.toString() ?? '',
      name: name,
      avatar: avatar,
      isOnline: false, // Would need to check UserProfile
      lastMessage: '', // Would need to get last message
      timestamp: _formatTimestamp(room['created_at']),
      unreadCount: 0, // Would need to calculate
      flight: '', // Not in room data
      gate: '', // Not in room data
    );
  }
  
  // Helper: Extract other user's name from description
  String _extractOtherUserNameFromDescription(String description, Map<String, dynamic>? currentUserData) {
    if (description.contains('between')) {
      // Description format: "Personal chat between be and Abrsh" or "Personal chat between be and be"
      final parts = description.split(' and ');
      if (parts.length >= 2) {
        // Get both names
        final firstPart = parts[0].replaceAll('Personal chat between', '').trim();
        final secondPart = parts[1].trim();
        
        // Get current user's username/name/email for comparison
        final currentUserName = currentUserData?['username']?.toString().toLowerCase() ?? 
                                currentUserData?['first_name']?.toString().toLowerCase() ?? '';
        final currentUserEmail = currentUserData?['email']?.toString().toLowerCase() ?? '';
        
        print('💬 [ChatService] Description: $description');
        print('💬 [ChatService] First part: $firstPart, Second part: $secondPart');
        print('💬 [ChatService] Current user name: $currentUserName, email: $currentUserEmail');
        
        // Determine which name is NOT the current user
        // Check if first part matches current user (more flexible matching)
        final firstPartLower = firstPart.toLowerCase();
        final secondPartLower = secondPart.toLowerCase();
        final currentUserNameLower = currentUserName.toLowerCase();
        
        bool firstPartIsCurrentUser = false;
        bool secondPartIsCurrentUser = false;
        
        // Check various ways the name might match
        if (currentUserNameLower.isNotEmpty) {
          firstPartIsCurrentUser = firstPartLower == currentUserNameLower ||
              firstPartLower.contains(currentUserNameLower) ||
              currentUserNameLower.contains(firstPartLower);
          
          secondPartIsCurrentUser = secondPartLower == currentUserNameLower ||
              secondPartLower.contains(currentUserNameLower) ||
              currentUserNameLower.contains(secondPartLower);
        }
        
        // Also check email prefix
        if (currentUserEmail.isNotEmpty && !firstPartIsCurrentUser) {
          final emailPrefix = currentUserEmail.split('@')[0].toLowerCase();
          firstPartIsCurrentUser = firstPartLower == emailPrefix ||
              firstPartLower.contains(emailPrefix) ||
              emailPrefix.contains(firstPartLower);
        }
        
        if (currentUserEmail.isNotEmpty && !secondPartIsCurrentUser) {
          final emailPrefix = currentUserEmail.split('@')[0].toLowerCase();
          secondPartIsCurrentUser = secondPartLower == emailPrefix ||
              secondPartLower.contains(emailPrefix) ||
              emailPrefix.contains(secondPartLower);
        }
        
        // If both parts match current user (edge case), return the longer one or second part
        if (firstPartIsCurrentUser && secondPartIsCurrentUser) {
          print('💬 [ChatService] Both parts match current user, using second part: "$secondPart"');
          return secondPart.trim();
        } else if (firstPartIsCurrentUser) {
          // First part is current user, so second part is the other user
          print('💬 [ChatService] First part "$firstPart" is current user, using second part: "$secondPart"');
          return secondPart.trim();
        } else if (secondPartIsCurrentUser) {
          // Second part is current user, so first part is the other user
          print('💬 [ChatService] Second part "$secondPart" is current user, using first part: "$firstPart"');
          return firstPart.trim();
        } else {
          // Neither matches, return the second part (usually the other user)
          print('💬 [ChatService] Neither part matches current user, using second part: "$secondPart"');
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
      
      final response = await _httpClient.get(
        Uri.parse(url),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data'] ?? data;
        final fullName = userData['fullName']?.toString().trim();
        final firstName = userData['first_name'] ?? '';
        final lastName = userData['last_name'] ?? '';
        final userName = fullName ?? 
                        (firstName.isNotEmpty || lastName.isNotEmpty 
                         ? '$firstName $lastName'.trim() 
                         : userData['username'] ?? 'Unknown');
        final avatar = userData['profileImageUrl'] ?? userData['profile_image_url'];
        
        final userInfo = {
          'name': userName,
          'avatar': avatar,
        };
        
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

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: userId,
      content: json['content'] ?? '',
      timestamp: _formatTimestamp(json['timestamp']),
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
}
