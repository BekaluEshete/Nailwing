// features/chat/views/chat_detail_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/core/theme/app_colors.dart';
import 'package:nilewing/features/chat/model/chat_model.dart';
import 'package:nilewing/features/chat/viewmodel/chat_view_model.dart';
import 'package:nilewing/features/chat/view/call_screen.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final ChatContact contact;
  final VoidCallback onBack;

  const ChatDetailScreen({
    Key? key,
    required this.contact,
    required this.onBack,
  }) : super(key: key);

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    // Select the chat when screen opens to connect WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatViewModelProvider.notifier).selectChat(widget.contact.id);
    });
    
    // Listen to text changes for typing indicators
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Send typing indicator when user types
    final viewModel = ref.read(chatViewModelProvider.notifier);
    viewModel.sendTypingIndicator(true);
    
    // Cancel previous timer
    _typingTimer?.cancel();
    
    // Send stop typing after 2 seconds of no typing
    _typingTimer = Timer(const Duration(seconds: 2), () {
      viewModel.sendTypingIndicator(false);
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      ref.read(chatViewModelProvider.notifier).sendMessage(message);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatViewModelProvider);
    final messages = chatState.selectedMessages;
    final selectedContact = chatState.selectedContact ?? widget.contact;
    
    // Check if other user is typing - need to get the other user's ID from messages
    bool isTyping = false;
    if (chatState.selectedChatId != null && messages.isNotEmpty) {
      // Find a message from the other user to get their ID
      final otherUserMessage = messages.firstWhere(
        (m) => !m.isMe,
        orElse: () => messages.first,
      );
      if (!otherUserMessage.isMe) {
        final otherUserId = otherUserMessage.senderId;
        isTyping = chatState.typingUsers['${chatState.selectedChatId}_$otherUserId'] == true;
      }
    }

    // Auto-scroll to bottom when messages are loaded or new messages arrive
    if (messages.isNotEmpty && !chatState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Chat Header
            _buildChatHeader(),
            // Error message banner if any
            if (chatState.error != null && chatState.error!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.orange[50],
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[800], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatState.error!,
                        style: TextStyle(color: Colors.orange[800], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            // Messages
            Expanded(
              child: chatState.isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Loading messages...',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : messages.isEmpty
                      ? Center(
                          child: Text(
                            'No messages yet. Start the conversation!',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  return _buildMessageBubble(messages[index]);
                                },
                              ),
                            ),
                        // Typing indicator
                        if (isTyping)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 24,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildTypingDot(0),
                                      const SizedBox(width: 4),
                                      _buildTypingDot(1),
                                      const SizedBox(width: 4),
                                      _buildTypingDot(2),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${selectedContact.name} is typing...',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            // Message Input
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                widget.onBack();
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                _getInitials(widget.contact.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contact.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final chatState = ref.watch(chatViewModelProvider);
                      final contact = chatState.selectedContact ?? widget.contact;
                      return Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: contact.isOnline
                                  ? Colors.green
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            contact.isOnline ? 'Online' : 'Offline',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${contact.flight}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallScreen(
                      channelName: widget.contact.id, // Use contact ID as unique channel
                      contactName: widget.contact.name,
                      isVideoCall: false,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.call, color: Colors.white, size: 20),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallScreen(
                      channelName: widget.contact.id, // Use contact ID as unique channel
                      contactName: widget.contact.name,
                      isVideoCall: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.videocam, color: Colors.white, size: 20),
            ),
            IconButton(
              onPressed: () {
                /* More */
              },
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((n) => n.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.map((n) => n[0]).take(2).join().toUpperCase();
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                _getInitials(widget.contact.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: message.isMe
                    ? LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.accent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: message.isMe ? null : Colors.grey[100],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: message.isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.timestamp,
                    style: TextStyle(
                      color: message.isMe ? Colors.white70 : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // Attachment button with popup menu for message types
          PopupMenuButton<MessageType>(
            icon: const Icon(Icons.add, color: Colors.grey),
            onSelected: (MessageType type) async {
              if (type == MessageType.text) {
                // Text messages are handled by the text input
                return;
              } else if (type == MessageType.flight) {
                // Handle flight information sharing
                await _sendFlightMessage();
              } else if (type == MessageType.location) {
                // Handle location sharing
                await _sendLocationMessage();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: MessageType.flight,
                child: Text('Share Flight Info'),
              ),
              const PopupMenuItem(
                value: MessageType.location,
                child: Text('Share Location'),
              ),
            ],
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            onPressed: _sendMessage,
            icon: Icon(Icons.send, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // Helper method to send flight message
  Future<void> _sendFlightMessage() async {
    // Example: In a real app, this could open a dialog to input flight details
    // For now, we'll use the contact's flight info
    final flightMessage =
        'Flight: ${widget.contact.flight}, Gate: ${widget.contact.gate}';

    await ref.read(chatViewModelProvider.notifier).sendMessage(flightMessage);
    _scrollToBottom();
  }

  // Helper method to send location message
  Future<void> _sendLocationMessage() async {
    // In a real app, this would use a location service (e.g., geolocator package)
    // For now, we'll use a mock location
    const locationMessage = 'Current location: Airport Terminal 1';

    await ref.read(chatViewModelProvider.notifier).sendMessage(locationMessage);
    _scrollToBottom();
  }

  // Build typing indicator dot with animation delay
  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (value * 0.5),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[400]?.withOpacity(0.8 + (value * 0.2)),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}
