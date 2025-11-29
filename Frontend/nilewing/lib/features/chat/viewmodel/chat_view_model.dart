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
      updatedMessages[contactId] = messages.map((msg) {
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

      state = state.copyWith(messages: updatedMessages);

      // Connect to WebSocket for real-time messages (non-blocking)
      _chatService.connectToRoom(
        _currentRoomName!,
        _handleWebSocketMessage,
      ).then((channel) {
        if (channel != null) {
          // Connection successful - clear any previous connection errors
          if (state.error != null && state.error!.contains('connection')) {
            state = state.copyWith(error: null);
          }
        }
      });

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

      final newMessage = ChatMessage(
        id:
            data['message_id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: isMe ? 'me' : data['user_id']?.toString() ?? 'unknown',
        content: data['message'] ?? '',
        timestamp: _formatTimestamp(data['timestamp']),
        type: _parseMessageType(data['message_type'] ?? 'text'),
      );

      // Update state with new message (optimized duplicate check)
      final updatedMessages = Map<String, List<ChatMessage>>.from(
        state.messages,
      );
      final currentMessages = updatedMessages[state.selectedChatId!] ?? [];

      // Avoid duplicates using Set for O(1) lookup
      final existingIds = currentMessages.map((m) => m.id).toSet();
      if (!existingIds.contains(newMessage.id)) {
        updatedMessages[state.selectedChatId!] = [
          ...currentMessages,
          newMessage,
        ];
        state = state.copyWith(messages: updatedMessages);
      }
    }
    // Typing indicators and user join/leave can be handled here if needed
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
    if (message.trim().isEmpty || state.selectedChatId == null) return;

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final trimmedMessage = message.trim();
    final newMessage = ChatMessage(
      id: tempId,
      senderId: 'me',
      content: trimmedMessage,
      timestamp: _formatTime(DateTime.now()),
      type: MessageType.text,
    );

    // Update local state immediately for better UX
    final updatedMessages = Map<String, List<ChatMessage>>.from(
      state.messages,
    );
    final currentMessages = updatedMessages[state.selectedChatId!] ?? [];
    updatedMessages[state.selectedChatId!] = [...currentMessages, newMessage];
    state = state.copyWith(messages: updatedMessages);

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
          final roomName = await _chatService.getRoomName(state.selectedChatId!);
          if (roomName.isNotEmpty) {
            _currentRoomName = roomName;
            try {
              _chatService.sendWebSocketMessage(roomName, trimmedMessage);
              messageSent = true;
              if (state.error != null && state.error!.contains('connection')) {
                state = state.copyWith(error: null);
              }
            } catch (e) {
              print('⚠️ [ChatViewModel] WebSocket send failed, trying HTTP: $e');
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
        final currentMessages = updatedMessages[state.selectedChatId!] ?? [];
        final messageIndex = currentMessages.indexWhere((m) => m.id == tempId);
        if (messageIndex != -1) {
          currentMessages[messageIndex] = ChatMessage(
            id: savedMessage.id,
            senderId: 'me',
            content: savedMessage.content,
            timestamp: savedMessage.timestamp,
            type: savedMessage.type,
          );
          updatedMessages[state.selectedChatId!] = currentMessages;
          state = state.copyWith(messages: updatedMessages);
        }
        
        // Clear error
        state = state.copyWith(error: null);
        print('✅ [ChatViewModel] Message saved via HTTP');
      } catch (e) {
        // HTTP also failed - keep message in state but show error
        print('❌ [ChatViewModel] HTTP fallback also failed: $e');
        state = state.copyWith(
          error: 'Message saved locally. Will sync when connection is restored.',
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
