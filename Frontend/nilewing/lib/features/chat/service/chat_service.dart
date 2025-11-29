// features/chat/services/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:nilewing/core/utils/app_constants.dart';
import 'package:nilewing/core/utils/token_storage.dart';
import 'package:nilewing/features/chat/model/chat_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final TokenStorage _tokenStorage = TokenStorage();
  final Map<String, WebSocketChannel?> _activeConnections = {};

  Future<String?> _getAuthToken() async {
    return await _tokenStorage.getAccessToken();
  }

  // Get chat rooms (contacts)
  Future<List<ChatContact>> getContacts() async {
    try {
      print('💬 [ChatService] Getting chat rooms...');
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ [ChatService] No auth token found');
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(AppConstants.chatRoomsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 [ChatService] Response status: ${response.statusCode}');
      print('📥 [ChatService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final contacts = data.map((room) => _roomToContact(room)).toList();
        print('✅ [ChatService] Loaded ${contacts.length} chat rooms');
        return contacts;
      }
      print('❌ [ChatService] Failed with status: ${response.statusCode}');
      throw Exception('Failed to load chat rooms: ${response.statusCode}');
    } catch (e) {
      print('❌ [ChatService] Error getting contacts: $e');
      throw Exception('Error getting contacts: $e');
    }
  }

  // Get messages for a room
  Future<List<ChatMessage>> getMessages(String roomId) async {
    try {
      print('💬 [ChatService] Getting messages for room: $roomId');
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = '${AppConstants.chatMessagesEndpoint}/$roomId/messages/';
      print('📡 [ChatService] Calling: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 [ChatService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final messages = data.map((msg) => _messageFromJson(msg)).toList();
        print('✅ [ChatService] Loaded ${messages.length} messages');
        return messages;
      }
      return [];
    } catch (e) {
      print('❌ [ChatService] Error getting messages: $e');
      return [];
    }
  }

  // Create or get personal chat room
  Future<ChatContact> createPersonalChat(String userId) async {
    try {
      print('💬 [ChatService] Creating personal chat with user: $userId');
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConstants.chatBaseUrl}/api/chats/personal/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'user_id': userId}),
      );

      print('📥 [ChatService] Response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return _roomToContact(data);
      }
      throw Exception('Failed to create chat: ${response.statusCode}');
    } catch (e) {
      print('❌ [ChatService] Error creating personal chat: $e');
      throw Exception('Error creating personal chat: $e');
    }
  }

  // Connect to WebSocket for a room
  Future<WebSocketChannel?> connectToRoom(String roomName, Function(Map<String, dynamic>) onMessage) async {
    try {
      print('🔌 [ChatService] Connecting to room: $roomName');
      
      // Close existing connection if any
      disconnectFromRoom(roomName);

      // Get token for WebSocket connection
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ [ChatService] No token for WebSocket');
        return null;
      }

      // Build WebSocket URL with token
      final wsUrl = _buildWebSocketUrl(roomName, token);
      print('🔌 [ChatService] WebSocket URL: $wsUrl');

      try {
        final uri = Uri.parse(wsUrl);
        print('🔌 [ChatService] Parsed URI: scheme=${uri.scheme}, host=${uri.host}, port=${uri.port}, path=${uri.path}');
        
        final channel = WebSocketChannel.connect(uri);
        _activeConnections[roomName] = channel;

        // Listen for messages
        channel.stream.listen(
          (message) {
            try {
              final data = json.decode(message as String);
              print('📨 [ChatService] Received WebSocket message: $data');
              onMessage(data);
            } catch (e) {
              print('❌ [ChatService] Error parsing WebSocket message: $e');
            }
          },
          onError: (error) {
            print('❌ [ChatService] WebSocket error: $error');
            _activeConnections.remove(roomName);
          },
          onDone: () {
            print('🔌 [ChatService] WebSocket connection closed');
            _activeConnections.remove(roomName);
          },
        );

        print('✅ [ChatService] WebSocket connected to $roomName');
        return channel;
      } catch (e) {
        print('❌ [ChatService] Error connecting WebSocket: $e');
        _activeConnections.remove(roomName);
        return null;
      }
    } catch (e) {
      print('❌ [ChatService] Error in connectToRoom: $e');
      return null;
    }
  }

  // Send message via WebSocket
  void sendWebSocketMessage(String roomName, String message) {
    try {
      final channel = _activeConnections[roomName];
      if (channel != null) {
        final messageData = json.encode({
          'type': 'message',
          'message': message,
          'message_type': 'text',
        });
        print('📤 [ChatService] Sending WebSocket message: $messageData');
        channel.sink.add(messageData);
      } else {
        print('❌ [ChatService] No WebSocket connection for room: $roomName');
      }
    } catch (e) {
      print('❌ [ChatService] Error sending WebSocket message: $e');
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
    
    // Parse the base URL to extract components
    Uri? baseUri;
    try {
      baseUri = Uri.parse(baseUrl);
    } catch (e) {
      print('❌ [ChatService] Error parsing base URL: $e');
      // Fallback: manual parsing
      String wsProtocol = 'wss://';
      String host = baseUrl.replaceAll('https://', '').replaceAll('http://', '');
      if (baseUrl.startsWith('http://')) {
        wsProtocol = 'ws://';
      }
      final cleanRoomName = roomName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      return '$wsProtocol$host/ws/chat/$cleanRoomName/?token=$token';
    }
    
    // Determine WebSocket protocol
    String wsProtocol = baseUri.scheme == 'https' ? 'wss://' : 'ws://';
    
    // Build host (without port for default ports)
    String host = baseUri.host;
    // Only include port if it's not a default port
    if (baseUri.hasPort && baseUri.port != 80 && baseUri.port != 443) {
      host = '${baseUri.host}:${baseUri.port}';
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
  ChatContact _roomToContact(Map<String, dynamic> room) {
    final createdBy = room['created_by'] ?? {};
    final name = createdBy['first_name'] != null && createdBy['last_name'] != null
        ? '${createdBy['first_name']} ${createdBy['last_name']}'
        : createdBy['username'] ?? createdBy['email'] ?? 'Unknown';
    
    return ChatContact(
      id: room['id']?.toString() ?? '',
      name: name,
      avatar: null, // Backend doesn't return avatar in room serializer
      isOnline: false, // Would need to check UserProfile
      lastMessage: '', // Would need to get last message
      timestamp: _formatTimestamp(room['created_at']),
      unreadCount: 0, // Would need to calculate
      flight: '', // Not in room data
      gate: '', // Not in room data
    );
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
      final response = await http.get(
        Uri.parse('${AppConstants.chatRoomsEndpoint}$roomId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
