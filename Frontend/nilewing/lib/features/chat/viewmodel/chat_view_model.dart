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
  // Map to track room name to chat ID mapping
  final Map<String, String> _roomNameToChatId = {};

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
      
      // Load room name mappings for real-time message routing
      await _loadRoomMappings();
    } catch (e) {
      print('❌ [ChatViewModel] Error loading contacts: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
  
  // Load room name to chat ID mappings when contacts are loaded
  Future<void> _loadRoomMappings() async {
    try {
      for (final contact in state.contacts) {
        try {
          final roomName = await _chatService.getRoomName(contact.id);
          if (roomName.isNotEmpty) {
            _roomNameToChatId[roomName] = contact.id;
            print('💬 [ChatViewModel] Mapped room $roomName to chat ${contact.id}');
          }
        } catch (e) {
          // Skip if room name can't be loaded for this contact
          print('⚠️ [ChatViewModel] Could not load room name for contact ${contact.id}: $e');
        }
      }
    } catch (e) {
      print('⚠️ [ChatViewModel] Error loading room mappings: $e');
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
      
      // Store mapping of room name to chat ID for real-time message routing
      _roomNameToChatId[_currentRoomName!] = contactId;

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
      final allMessages = [...dbMessages, ...optimisticMessages];

      // Remove duplicates by ID (keep the one with UUID if both exist)
      final uniqueMessages = <String, ChatMessage>{};
      for (final msg in allMessages) {
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
      
      // Sort messages by timestamp
      final sortedMessages = uniqueMessages.values.toList();
      sortedMessages.sort((a, b) {
        try {
          final aTime = DateTime.parse(a.timestamp);
          final bTime = DateTime.parse(b.timestamp);
          return aTime.compareTo(bTime);
        } catch (e) {
          return 0;
        }
      });
      updatedMessages[contactId] = sortedMessages;

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
    print('💬 [ChatViewModel] Received WebSocket message type: $messageType');

    if (messageType == 'message') {
      // Handle real-time messages - REAL-TIME CHAT IMPLEMENTATION
      final serverMessageId = data['message_id']?.toString();
      final messageContent = data['message'] ?? '';
      final userId = data['user_id']?.toString();
      final roomName = data['room_name'] ?? _currentRoomName;
      
      if (serverMessageId == null || messageContent.isEmpty) {
        print('⚠️ [ChatViewModel] Invalid message data received');
        return;
      }

      print('💬 [ChatViewModel] Received message for room: $roomName');

      // Find chat ID from room name mapping - CRITICAL for real-time routing
      String? chatId;
      if (roomName != null) {
        // First try to get from mapping (fastest - synchronous)
        chatId = _roomNameToChatId[roomName];
        
        // If not in mapping, try current room (if this is the selected chat)
        if (chatId == null && roomName == _currentRoomName) {
          chatId = state.selectedChatId;
          // Store mapping for future use
          if (chatId != null) {
            _roomNameToChatId[roomName] = chatId;
          }
        }
      }
      
      // Fallback to selected chat if still not found and room matches
      if (chatId == null && roomName == _currentRoomName) {
        chatId = state.selectedChatId;
      }
      
      // If still no chat ID, try to handle for different room asynchronously
      if (chatId == null && roomName != null) {
        // Load room ID asynchronously but process message immediately if possible
        _chatService.getRoomIdFromName(roomName).then((roomId) {
          if (roomId != null) {
            _roomNameToChatId[roomName] = roomId;
            // Process the message now that we have the room ID
            _processIncomingMessage(roomId, data);
          }
        }).catchError((e) {
          print('⚠️ [ChatViewModel] Could not get room ID from name: $e');
          // Try to handle as different room
          _handleMessageForDifferentRoom(roomName, data);
        });
        return;
      }
      
      if (chatId == null) {
        print('⚠️ [ChatViewModel] Could not determine chat ID for message. Room: $roomName');
        // Try one more time with selected chat as fallback
        chatId = state.selectedChatId;
        if (chatId == null) {
          return;
        }
      }
      
      // Process the message with the found chat ID
      _processIncomingMessage(chatId, data);
    } else if (messageType == 'typing') {
      // Handle typing indicators
      final typingUserId = data['user_id']?.toString();
      final isTyping = data['typing'] == true;
      
      if (typingUserId != null && state.selectedChatId != null) {
        final currentChatId = state.selectedChatId!;
        print('⌨️ [ChatViewModel] User $typingUserId is ${isTyping ? 'typing' : 'not typing'}');
        final updatedTypingUsers = Map<String, bool>.from(state.typingUsers);
        updatedTypingUsers['${currentChatId}_$typingUserId'] = isTyping;
        
        state = state.copyWith(typingUsers: Map<String, bool>.from(updatedTypingUsers));
        
        // Auto-clear typing indicator after 3 seconds
        if (isTyping) {
          Future.delayed(const Duration(seconds: 3), () {
            final currentTypingUsers = Map<String, bool>.from(state.typingUsers);
            currentTypingUsers.remove('${currentChatId}_$typingUserId');
            state = state.copyWith(typingUsers: Map<String, bool>.from(currentTypingUsers));
          });
        }
      }
    } else if (messageType == 'user_joined') {
      // Handle user joined (online status)
      final joinedUserId = data['user_id']?.toString();
      if (joinedUserId != null && state.selectedChatId != null && joinedUserId != _currentUserId) {
        final currentChatId = state.selectedChatId!;
        print('👤 [ChatViewModel] User $joinedUserId joined (online)');
        final updatedOnlineUsers = Map<String, Set<String>>.from(state.onlineUsers);
        final onlineSet = updatedOnlineUsers[currentChatId] ?? <String>{};
        onlineSet.add(joinedUserId);
        updatedOnlineUsers[currentChatId] = onlineSet;
        
        // Update contact online status
        final updatedContacts = state.contacts.map((contact) {
          if (contact.id == currentChatId) {
            return contact.copyWith(isOnline: true);
          }
          return contact;
        }).toList();
        
        state = state.copyWith(
          onlineUsers: Map<String, Set<String>>.from(updatedOnlineUsers),
          contacts: updatedContacts,
        );
      }
    } else if (messageType == 'user_left') {
      // Handle user left (offline status)
      final leftUserId = data['user_id']?.toString();
      if (leftUserId != null && state.selectedChatId != null && leftUserId != _currentUserId) {
        final currentChatId = state.selectedChatId!;
        print('👤 [ChatViewModel] User $leftUserId left (offline)');
        final updatedOnlineUsers = Map<String, Set<String>>.from(state.onlineUsers);
        final onlineSet = updatedOnlineUsers[currentChatId] ?? <String>{};
        onlineSet.remove(leftUserId);
        updatedOnlineUsers[currentChatId] = onlineSet;
        
        // Update contact online status
        final updatedContacts = state.contacts.map((contact) {
          if (contact.id == currentChatId) {
            return contact.copyWith(isOnline: false);
          }
          return contact;
        }).toList();
        
        state = state.copyWith(
          onlineUsers: Map<String, Set<String>>.from(updatedOnlineUsers),
          contacts: updatedContacts,
        );
      }
    }
  }

  // Process incoming message - extracted for reuse
  void _processIncomingMessage(String chatId, Map<String, dynamic> data) {
    final serverMessageId = data['message_id']?.toString();
    final messageContent = data['message'] ?? '';
    final userId = data['user_id']?.toString();
    final isMe = _currentUserId != null && userId == _currentUserId;

    print('💬 [ChatViewModel] Processing REAL-TIME message: $messageContent (isMe: $isMe, chatId: $chatId)');

    // Update state with new message - CRITICAL FOR REAL-TIME UPDATES
    final updatedMessages = Map<String, List<ChatMessage>>.from(state.messages);
    final currentMessages = List<ChatMessage>.from(updatedMessages[chatId] ?? []);

    // Check if message already exists (prevent duplicates)
    final existingIds = currentMessages.map((m) => m.id).toSet();
    
    if (!existingIds.contains(serverMessageId)) {
      // Add new message to the list
      final newMessage = ChatMessage(
        id: serverMessageId!,
        senderId: isMe ? 'me' : userId ?? 'unknown',
        content: messageContent,
        timestamp: _formatTimestamp(data['timestamp']),
        type: _parseMessageType(data['message_type'] ?? 'text'),
      );

      currentMessages.add(newMessage);
      
      // Sort messages by timestamp to ensure proper order
      currentMessages.sort((a, b) {
        try {
          final aTime = DateTime.parse(a.timestamp);
          final bTime = DateTime.parse(b.timestamp);
          return aTime.compareTo(bTime);
        } catch (e) {
          return 0;
        }
      });
      
      updatedMessages[chatId] = currentMessages;

      // Update state - this triggers UI refresh (create new map to ensure change detection)
      state = state.copyWith(messages: Map<String, List<ChatMessage>>.from(updatedMessages));

      print('✅ [ChatViewModel] REAL-TIME message added. Total messages: ${currentMessages.length}');
    } else {
      print('ℹ️ [ChatViewModel] Message already exists, skipping duplicate');
    }
  }

  // Helper to handle messages for a different room (when chat not selected)
  Future<void> _handleMessageForDifferentRoom(String roomName, Map<String, dynamic> messageData) async {
    try {
      // Get the room ID from the service
      final roomId = await _chatService.getRoomIdFromName(roomName);
      if (roomId != null) {
        // Store mapping for future use
        _roomNameToChatId[roomName] = roomId;
        
        final chatId = roomId;
        final serverMessageId = messageData['message_id']?.toString();
        final messageContent = messageData['message'] ?? '';
        final userId = messageData['user_id']?.toString();
        final isMe = _currentUserId != null && userId == _currentUserId;

        final updatedMessages = Map<String, List<ChatMessage>>.from(state.messages);
        final currentMessages = List<ChatMessage>.from(updatedMessages[chatId] ?? []);

        final existingIds = currentMessages.map((m) => m.id).toSet();
        if (!existingIds.contains(serverMessageId)) {
          final newMessage = ChatMessage(
            id: serverMessageId!,
            senderId: isMe ? 'me' : userId ?? 'unknown',
            content: messageContent,
            timestamp: _formatTimestamp(messageData['timestamp']),
            type: _parseMessageType(messageData['message_type'] ?? 'text'),
          );

          currentMessages.add(newMessage);
          
          // Sort messages by timestamp
          currentMessages.sort((a, b) {
            try {
              final aTime = DateTime.parse(a.timestamp);
              final bTime = DateTime.parse(b.timestamp);
              return aTime.compareTo(bTime);
            } catch (e) {
              return 0;
            }
          });
          
          updatedMessages[chatId] = currentMessages;

          // Update unread count for this contact
          if (!isMe) {
            final updatedContacts = state.contacts.map((contact) {
              if (contact.id == chatId) {
                return contact.copyWith(unreadCount: contact.unreadCount + 1);
              }
              return contact;
            }).toList();
            state = state.copyWith(
              messages: Map<String, List<ChatMessage>>.from(updatedMessages),
              contacts: updatedContacts,
            );
          } else {
            state = state.copyWith(messages: Map<String, List<ChatMessage>>.from(updatedMessages));
          }
        }
      }
    } catch (e) {
      print('⚠️ [ChatViewModel] Error handling message for different room: $e');
    }
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
    
    // Sort messages by timestamp
    currentMessages.sort((a, b) {
      try {
        final aTime = DateTime.parse(a.timestamp);
        final bTime = DateTime.parse(b.timestamp);
        return aTime.compareTo(bTime);
      } catch (e) {
        return 0;
      }
    });
    
    updatedMessages[state.selectedChatId!] = currentMessages;

    print(
      '💬 [ChatViewModel] Updated messages count: ${currentMessages.length}',
    );

    // Create new map to ensure state change detection
    state = state.copyWith(messages: Map<String, List<ChatMessage>>.from(updatedMessages));

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
