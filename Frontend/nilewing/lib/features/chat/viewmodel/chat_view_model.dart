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
    // Set loading state BEFORE selecting chat to show loading indicator
    state = state.copyWith(
      isLoading: true,
      selectedChatId: contactId,
      error: null,
    );

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
      // Load messages BEFORE updating state to prevent empty screen
      print('📥 [ChatViewModel] Loading messages for chat: $contactId');
      final messages = await _chatService.getMessages(contactId);
      print('✅ [ChatViewModel] Loaded ${messages.length} messages from database');

      // Update state with loaded messages from database
      final updatedMessages = Map<String, List<ChatMessage>>.from(
        state.messages,
      );

      // Get existing messages for this chat (might have optimistic messages)
      final existingMessages = updatedMessages[contactId] ?? [];

      // Map database messages
      // Note: Messages from backend are already sorted by timestamp (oldest first)
      // We preserve that order and only sort when combining with optimistic messages
      final dbMessages = messages.map((msg) {
        // Determine if message is from current user
        final isMe = _currentUserId != null && msg.senderId == _currentUserId;
        return ChatMessage(
          id: msg.id,
          senderId: isMe ? 'me' : msg.senderId,
          content: msg.content,
          timestamp: msg.timestamp,  // Already formatted by service
          isoTimestamp: msg.isoTimestamp,  // Preserve ISO timestamp for sorting
          type: msg.type,
        );
      }).toList();
      
      // Backend returns messages sorted by timestamp (oldest first)
      // No need to re-sort dbMessages - they're already in correct order

      // Preserve optimistic messages (temp IDs) that aren't in database yet
      final dbMessageIds = dbMessages.map((m) => m.id).toSet();
      final optimisticMessages = existingMessages.where((msg) {
        // Keep messages with temp IDs (not UUID format) that are from "me"
        return msg.senderId == 'me' &&
            !_isUuidFormat(msg.id) &&
            !dbMessageIds.contains(msg.id);
      }).toList();

      // Combine: database messages first, then optimistic messages
      // Database messages are already sorted (oldest first) from backend
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
      
      // Convert to list
      // Backend returns messages sorted by timestamp (oldest first)
      // Optimistic messages (temp IDs) should go at the end
      final sortedMessages = <ChatMessage>[];
      
      // Add database messages first (already sorted from backend)
      for (final msg in dbMessages) {
        if (uniqueMessages.containsKey(msg.id)) {
          sortedMessages.add(uniqueMessages[msg.id]!);
        }
      }
      
      // Add optimistic messages at the end (they're newer)
      for (final msg in optimisticMessages) {
        if (uniqueMessages.containsKey(msg.id)) {
          sortedMessages.add(uniqueMessages[msg.id]!);
        }
      }
      
      updatedMessages[contactId] = sortedMessages;

      // Update state with messages AND clear loading state
      // This ensures messages are displayed immediately when chat opens
      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,  // Clear loading state after messages are loaded
      );
      
      print('✅ [ChatViewModel] State updated with ${sortedMessages.length} messages. Loading: false');

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

      state = state.copyWith(
        contacts: updatedContacts,
        isLoading: false,  // Ensure loading is cleared even if WebSocket fails
      );
    } catch (e) {
      print('❌ [ChatViewModel] Error selecting chat: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,  // Clear loading state on error
      );
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    final messageType = data['type'];
    print('💬 [ChatViewModel] Received WebSocket message type: $messageType');

    if (messageType == 'message') {
      // Handle real-time messages - REAL-TIME CHAT IMPLEMENTATION
      final serverMessageId = data['message_id']?.toString();
      final messageContent = data['message'] ?? '';
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
      // Handle typing indicators - use room_name for proper routing
      final typingUserId = data['user_id']?.toString();
      final isTyping = data['typing'] == true;
      final roomName = data['room_name'] ?? _currentRoomName;
      
      if (typingUserId != null && roomName != null && typingUserId != _currentUserId) {
        // Find chat ID from room name
        String? chatId = _roomNameToChatId[roomName];
        
        // If not in mapping, try current room
        if (chatId == null && roomName == _currentRoomName) {
          chatId = state.selectedChatId;
        }
        
        if (chatId != null) {
          print('⌨️ [ChatViewModel] User $typingUserId in room $roomName is ${isTyping ? 'typing' : 'not typing'}');
          final updatedTypingUsers = Map<String, bool>.from(state.typingUsers);
          if (isTyping) {
            updatedTypingUsers['${chatId}_$typingUserId'] = true;
          } else {
            updatedTypingUsers.remove('${chatId}_$typingUserId');
          }
          
          state = state.copyWith(typingUsers: Map<String, bool>.from(updatedTypingUsers));
          
          // Auto-clear typing indicator after 3 seconds
          if (isTyping) {
            Future.delayed(const Duration(seconds: 3), () {
              final currentTypingUsers = Map<String, bool>.from(state.typingUsers);
              currentTypingUsers.remove('${chatId}_$typingUserId');
              state = state.copyWith(typingUsers: Map<String, bool>.from(currentTypingUsers));
            });
          }
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
      final isoTime = data['timestamp']?.toString();
      final newMessage = ChatMessage(
        id: serverMessageId!,
        senderId: isMe ? 'me' : userId ?? 'unknown',
        content: messageContent,
        timestamp: _formatTimestamp(isoTime),
        isoTimestamp: isoTime, // Store original ISO timestamp for sorting
        type: _parseMessageType(data['message_type'] ?? 'text'),
      );

      currentMessages.add(newMessage);
      
      // Sort messages by ISO timestamp to ensure proper order
      currentMessages.sort(_compareMessagesByTimestamp);
      
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
        final isoTime = messageData['timestamp']?.toString();
        final newMessage = ChatMessage(
          id: serverMessageId!,
          senderId: isMe ? 'me' : userId ?? 'unknown',
          content: messageContent,
          timestamp: _formatTimestamp(isoTime),
          isoTimestamp: isoTime, // Store original ISO timestamp for sorting
          type: _parseMessageType(messageData['message_type'] ?? 'text'),
        );

          currentMessages.add(newMessage);
          
          // Sort messages by ISO timestamp
          currentMessages.sort(_compareMessagesByTimestamp);
          
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

  // Send typing indicator via WebSocket
  void sendTypingIndicator(bool isTyping) {
    if (_currentRoomName == null || state.selectedChatId == null) {
      return; // Can't send typing indicator if no room is selected
    }

    try {
      _chatService.sendTypingIndicator(_currentRoomName!, isTyping);
      print('⌨️ [ChatViewModel] Sent typing indicator: $isTyping');
    } catch (e) {
      print('⚠️ [ChatViewModel] Error sending typing indicator: $e');
    }
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || state.selectedChatId == null) {
      print(
        '⚠️ [ChatViewModel] Cannot send message: empty or no chat selected',
      );
      return;
    }

    final now = DateTime.now();
    final tempId = now.millisecondsSinceEpoch.toString();
    final trimmedMessage = message.trim();
    final isoTime = now.toIso8601String();
    final newMessage = ChatMessage(
      id: tempId,
      senderId: 'me',
      content: trimmedMessage,
      timestamp: _formatTime(now),
      isoTimestamp: isoTime, // Store ISO timestamp for sorting
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
    
    // Sort messages by ISO timestamp
    currentMessages.sort(_compareMessagesByTimestamp);
    
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
            isoTimestamp: savedMessage.isoTimestamp, // Preserve ISO timestamp
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
              isoTimestamp: savedMessage.isoTimestamp, // Preserve ISO timestamp
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
              isoTimestamp: msg.isoTimestamp, // Preserve ISO timestamp
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
  
  // Helper to sort messages by ISO timestamp (oldest first)
  int _compareMessagesByTimestamp(ChatMessage a, ChatMessage b) {
    try {
      // Use ISO timestamp if available, otherwise try to parse formatted timestamp
      String? aIso = a.isoTimestamp;
      String? bIso = b.isoTimestamp;
      
      // If no ISO timestamp, try parsing the formatted timestamp (backward compatibility)
      if (aIso == null) {
        // For formatted strings like "Just now", use current time
        // This is not ideal but maintains backward compatibility
        if (a.timestamp == 'Just now') {
          aIso = DateTime.now().toIso8601String();
        }
      }
      if (bIso == null) {
        if (b.timestamp == 'Just now') {
          bIso = DateTime.now().toIso8601String();
        }
      }
      
      if (aIso != null && bIso != null) {
        final aTime = DateTime.parse(aIso);
        final bTime = DateTime.parse(bIso);
        return aTime.compareTo(bTime);
      }
      
      // Fallback: compare by ID if timestamps are unavailable
      return a.id.compareTo(b.id);
    } catch (e) {
      // If parsing fails, use ID comparison as fallback
      return a.id.compareTo(b.id);
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
      case 'flight':
        return MessageType.flight;
      case 'location':
        return MessageType.location;
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
