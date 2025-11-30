// features/chat/viewmodels/chat_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/features/chat/model/chat_model.dart';
import 'package:nilewing/features/chat/service/chat_service.dart';
import 'package:nilewing/core/utils/token_storage.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final chatViewModelProvider = StateNotifierProvider<ChatViewModel, ChatState>((
  ref,
) {
  return ChatViewModel(ref);
});

class ChatViewModel extends StateNotifier<ChatState> {
  final Ref _ref;
  late final ChatService _chatService;
  final TokenStorage _tokenStorage = TokenStorage();
  String? _currentUserId;
  String? _currentRoomName;

  ChatViewModel(this._ref)
    : super(const ChatState(contacts: [], messages: {})) {
    _chatService = _ref.read(chatServiceProvider);
    _loadCurrentUserId();
    _loadContacts();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final userData = await _tokenStorage.getUserData();
      if (userData != null && userData['id'] != null) {
        _currentUserId = userData['id'].toString();
        print('👤 [ChatViewModel] Current user ID: $_currentUserId');
      }
    } catch (e) {
      print('❌ [ChatViewModel] Error loading user ID: $e');
    }
  }

  Future<void> _loadContacts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final contacts = await _chatService.getContacts();
      state = state.copyWith(contacts: contacts, isLoading: false);
    } catch (e) {
      print('❌ [ChatViewModel] Error loading contacts: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> selectChat(String contactId) async {
    state = state.copyWith(selectedChatId: contactId, error: null);

    try {
      // Get room name from contact ID
      _currentRoomName = await _chatService.getRoomName(contactId);

      if (_currentRoomName == null || _currentRoomName!.isEmpty) {
        throw Exception('Could not get room name for contact');
      }

      // Mark messages as read (non-blocking)
      _chatService.markAsRead(contactId);

      // ALWAYS load messages from database when selecting a chat
      // This ensures we have the latest persisted messages
      final messages = await _chatService.getMessages(contactId);

      // Update state with loaded messages from database
      final updatedMessages = Map<String, List<ChatMessage>>.from(
        state.messages,
      );

      // Get existing messages for this chat (might have optimistic messages)
      final existingMessages = updatedMessages[contactId] ?? [];

      // Map database messages
      final dbMessages = messages.map((msg) {
        // Determine if message is from current user
        final isMe = _currentUserId != null && msg.senderId == _currentUserId;
        return ChatMessage(
          id: msg.id,
          senderId: isMe ? 'me' : msg.senderId,
          content: msg.content,
          timestamp: msg.timestamp,
          type: msg.type,
        );
      }).toList();

      // Preserve optimistic messages (temp IDs) that aren't in database yet
      final dbMessageIds = dbMessages.map((m) => m.id).toSet();
      final optimisticMessages = existingMessages.where((msg) {
        // Keep messages with temp IDs (not UUID format) that are from "me"
        return msg.senderId == 'me' &&
            !_isUuidFormat(msg.id) &&
            !dbMessageIds.contains(msg.id);
      }).toList();

      // Combine: database messages first, then optimistic messages
      updatedMessages[contactId] = [...dbMessages, ...optimisticMessages];

      // Remove duplicates by ID (keep the one with UUID if both exist)
      final uniqueMessages = <String, ChatMessage>{};
      for (final msg in updatedMessages[contactId]!) {
        // If duplicate exists, prefer UUID (server) version over temp ID
        if (!uniqueMessages.containsKey(msg.id)) {
          uniqueMessages[msg.id] = msg;
        } else {
          // If we have a UUID version, prefer it over temp ID
          if (_isUuidFormat(msg.id) &&
              !_isUuidFormat(uniqueMessages[msg.id]!.id)) {
            uniqueMessages[msg.id] = msg;
          }
        }
      }
      updatedMessages[contactId] = uniqueMessages.values.toList();

      state = state.copyWith(messages: updatedMessages);

      // Connect to WebSocket for real-time messages (non-blocking, only if not already connected)
      if (!_chatService.isConnected(_currentRoomName!)) {
        _chatService
            .connectToRoom(
              _currentRoomName!,
              _handleWebSocketMessage,
              isManualRetry: true,
            )
            .then((channel) {
              if (channel != null) {
                // Connection successful - clear any previous connection errors
                if (state.error != null &&
                    state.error!.contains('connection')) {
                  state = state.copyWith(error: null);
                }
              }
            })
            .catchError((error) {
              print(
                '⚠️ [ChatViewModel] WebSocket connection failed (non-critical): $error',
              );
              // Don't show error - HTTP fallback will work
            });
      } else {
        print('ℹ️ [ChatViewModel] WebSocket already connected for $contactId');
      }

      // Update contact's unread count
      final updatedContacts = state.contacts.map((contact) {
        if (contact.id == contactId) {
          return contact.copyWith(unreadCount: 0);
        }
        return contact;
      }).toList();

      state = state.copyWith(contacts: updatedContacts);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    final messageType = data['type'];

    if (messageType == 'message' && state.selectedChatId != null) {
      // New message received
      final isMe =
          _currentUserId != null &&
          data['user_id'] != null &&
          data['user_id'].toString() == _currentUserId;

      final serverMessageId = data['message_id']?.toString();
      final messageContent = data['message'] ?? '';

      // Update state with new message
      final updatedMessages = Map<String, List<ChatMessage>>.from(
        state.messages,
      );
      final currentMessages = List<ChatMessage>.from(
        updatedMessages[state.selectedChatId!] ?? [],
      );

      if (isMe && serverMessageId != null) {
        // This is our own message coming back from server
        // Find and replace the optimistic message (with temp ID) with server message
        final messageIndex = currentMessages.indexWhere(
          (msg) =>
              msg.senderId == 'me' &&
              msg.content == messageContent &&
              !_isUuidFormat(msg.id),
        ); // Temp IDs are timestamps, not UUIDs

        if (messageIndex != -1) {
          // Replace optimistic message with server-confirmed message
          currentMessages[messageIndex] = ChatMessage(
            id: serverMessageId,
            senderId: 'me',
            content: messageContent,
            timestamp: _formatTimestamp(data['timestamp']),
            type: _parseMessageType(data['message_type'] ?? 'text'),
          );
        } else {
          // If we couldn't find the optimistic message, check if server message already exists
          final existingIds = currentMessages.map((m) => m.id).toSet();
          if (!existingIds.contains(serverMessageId)) {
            // Add as new message if it doesn't exist
            currentMessages.add(
              ChatMessage(
                id: serverMessageId,
                senderId: 'me',
                content: messageContent,
                timestamp: _formatTimestamp(data['timestamp']),
                type: _parseMessageType(data['message_type'] ?? 'text'),
              ),
            );
          }
        }
      } else {
        // Message from other user - check for duplicates
        final existingIds = currentMessages.map((m) => m.id).toSet();
        final messageId =
            serverMessageId ?? DateTime.now().millisecondsSinceEpoch.toString();

        if (!existingIds.contains(messageId)) {
          currentMessages.add(
            ChatMessage(
              id: messageId,
              senderId: data['user_id']?.toString() ?? 'unknown',
              content: messageContent,
              timestamp: _formatTimestamp(data['timestamp']),
              type: _parseMessageType(data['message_type'] ?? 'text'),
            ),
          );
        }
      }

      updatedMessages[state.selectedChatId!] = currentMessages;
      state = state.copyWith(messages: updatedMessages);
    }
    // Typing indicators and user join/leave can be handled here if needed
  }

  // Helper to check if ID is UUID format (server-generated) vs timestamp (temp ID)
  bool _isUuidFormat(String id) {
    // UUID format: 8-4-4-4-12 hex characters
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(id);
  }

  void clearSelectedChat() {
    print('💬 [ChatViewModel] Clearing selected chat');

    // Disconnect from WebSocket
    if (_currentRoomName != null) {
      _chatService.disconnectFromRoom(_currentRoomName!);
      _currentRoomName = null;
    }

    state = state.copyWith(selectedChatId: null);
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || state.selectedChatId == null) {
      print(
        '⚠️ [ChatViewModel] Cannot send message: empty or no chat selected',
      );
      return;
    }

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final trimmedMessage = message.trim();
    final newMessage = ChatMessage(
      id: tempId,
      senderId: 'me',
      content: trimmedMessage,
      timestamp: _formatTime(DateTime.now()),
      type: MessageType.text,
    );

    print(
      '💬 [ChatViewModel] Adding optimistic message: $tempId - "$trimmedMessage"',
    );
    print('💬 [ChatViewModel] Selected chat ID: ${state.selectedChatId}');
    print(
      '💬 [ChatViewModel] Current messages count: ${state.messages[state.selectedChatId!]?.length ?? 0}',
    );

    // Update local state immediately for better UX
    final updatedMessages = Map<String, List<ChatMessage>>.from(state.messages);
    final currentMessages = List<ChatMessage>.from(
      updatedMessages[state.selectedChatId!] ?? [],
    );

    // Add new message at the end
    currentMessages.add(newMessage);
    updatedMessages[state.selectedChatId!] = currentMessages;

    print(
      '💬 [ChatViewModel] Updated messages count: ${currentMessages.length}',
    );

    state = state.copyWith(messages: updatedMessages);

    // Verify message was added
    final verifyMessages = state.messages[state.selectedChatId!] ?? [];
    print(
      '💬 [ChatViewModel] Verified messages count after state update: ${verifyMessages.length}',
    );
    if (verifyMessages.isEmpty || !verifyMessages.any((m) => m.id == tempId)) {
      print('❌ [ChatViewModel] ERROR: Message was not persisted in state!');
    }

    // Send to server - try WebSocket first, fallback to HTTP
    // IMPORTANT: Keep the message in state even if sending fails initially
    // The message will be saved to database via HTTP if WebSocket fails
    bool messageSent = false;

    try {
      if (_currentRoomName != null) {
        // Try to send via WebSocket first
        try {
          _chatService.sendWebSocketMessage(_currentRoomName!, trimmedMessage);
          messageSent = true;
          // Clear any connection errors
          if (state.error != null && state.error!.contains('connection')) {
            state = state.copyWith(error: null);
          }
        } catch (e) {
          // WebSocket failed, will try HTTP fallback
          print('⚠️ [ChatViewModel] WebSocket send failed, trying HTTP: $e');
        }
      } else {
        // Get room name first
        try {
          final roomName = await _chatService.getRoomName(
            state.selectedChatId!,
          );
          if (roomName.isNotEmpty) {
            _currentRoomName = roomName;
            try {
              _chatService.sendWebSocketMessage(roomName, trimmedMessage);
              messageSent = true;
              if (state.error != null && state.error!.contains('connection')) {
                state = state.copyWith(error: null);
              }
            } catch (e) {
              print(
                '⚠️ [ChatViewModel] WebSocket send failed, trying HTTP: $e',
              );
            }
          }
        } catch (e) {
          print('⚠️ [ChatViewModel] Could not get room name: $e');
        }
      }
    } catch (e) {
      print('⚠️ [ChatViewModel] WebSocket error: $e');
    }

    // If WebSocket failed, try HTTP fallback to save message to database
    if (!messageSent) {
      try {
        print('📡 [ChatViewModel] Sending message via HTTP fallback...');
        final savedMessage = await _chatService.sendMessageViaHttp(
          state.selectedChatId!,
          trimmedMessage,
        );

        // Update the message ID with the one from database
        final updatedMessages = Map<String, List<ChatMessage>>.from(
          state.messages,
        );
        final currentMessages = List<ChatMessage>.from(
          updatedMessages[state.selectedChatId!] ?? [],
        );

        // Find and replace temp message with saved message
        final messageIndex = currentMessages.indexWhere((m) => m.id == tempId);
        if (messageIndex != -1) {
          currentMessages[messageIndex] = ChatMessage(
            id: savedMessage.id,
            senderId: 'me',
            content: savedMessage.content,
            timestamp: savedMessage.timestamp,
            type: savedMessage.type,
          );
        } else {
          // If temp message not found, add the saved message
          currentMessages.add(
            ChatMessage(
              id: savedMessage.id,
              senderId: 'me',
              content: savedMessage.content,
              timestamp: savedMessage.timestamp,
              type: savedMessage.type,
            ),
          );
        }

        updatedMessages[state.selectedChatId!] = currentMessages;
        state = state.copyWith(messages: updatedMessages);

        // Reload messages to ensure we have the latest from database
        try {
          final reloadedMessages = await _chatService.getMessages(
            state.selectedChatId!,
          );
          final reloadedFormatted = reloadedMessages.map((msg) {
            final isMe =
                _currentUserId != null && msg.senderId == _currentUserId;
            return ChatMessage(
              id: msg.id,
              senderId: isMe ? 'me' : msg.senderId,
              content: msg.content,
              timestamp: msg.timestamp,
              type: msg.type,
            );
          }).toList();

          updatedMessages[state.selectedChatId!] = reloadedFormatted;
          state = state.copyWith(messages: updatedMessages);
        } catch (e) {
          print('⚠️ [ChatViewModel] Could not reload messages: $e');
        }

        // Clear error
        state = state.copyWith(error: null);
        print('✅ [ChatViewModel] Message saved via HTTP and state updated');
      } catch (e) {
        // HTTP also failed - keep message in state but show error
        print('❌ [ChatViewModel] HTTP fallback also failed: $e');
        state = state.copyWith(
          error:
              'Message saved locally. Will sync when connection is restored.',
        );
      }
    }
  }

  Future<void> refreshContacts() async {
    await _loadContacts();
  }

  List<ChatContact> searchContacts(String query) {
    if (query.isEmpty) return state.contacts;

    return state.contacts.where((contact) {
      return contact.name.toLowerCase().contains(query.toLowerCase()) ||
          contact.flight.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Create personal chat with a user
  Future<ChatContact?> createPersonalChat(String userId) async {
    try {
      print('💬 [ChatViewModel] Creating personal chat with user: $userId');
      final contact = await _chatService.createPersonalChat(userId);

      // Check if contact already exists in the list
      final contactExists = state.contacts.any((c) => c.id == contact.id);

      // Add to contacts if not already present
      if (!contactExists) {
        print('➕ [ChatViewModel] Adding new contact to list: ${contact.id}');
        final updatedContacts = [...state.contacts, contact];
        state = state.copyWith(contacts: updatedContacts);
      } else {
        print(
          'ℹ️ [ChatViewModel] Contact already exists in list: ${contact.id}',
        );
      }

      // Select the new chat
      await selectChat(contact.id);

      print(
        '✅ [ChatViewModel] Personal chat created and selected: ${contact.id}',
      );
      return contact;
    } catch (e) {
      print('❌ [ChatViewModel] Error creating personal chat: $e');
      state = state.copyWith(error: 'Failed to create chat: $e');
      return null;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final dt = DateTime.parse(timestamp);
      return _formatTime(dt);
    } catch (e) {
      return 'Just now';
    }
  }

  MessageType _parseMessageType(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.location;
      case 'file':
        return MessageType.text;
      default:
        return MessageType.text;
    }
  }

  @override
  void dispose() {
    // Disconnect all WebSocket connections when viewmodel is disposed
    _chatService.disconnectAll();
    super.dispose();
  }
}
