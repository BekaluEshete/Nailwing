// features/chat/views/chat_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nilewing/core/theme/app_colors.dart';
import 'package:nilewing/features/chat/model/chat_model.dart';
import 'package:nilewing/features/chat/viewmodel/chat_view_model.dart';

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

  @override
  void dispose() {
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
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatViewModelProvider);
    final messages = chatState.selectedMessages;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Chat Header
            _buildChatHeader(),
            // Messages
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
          colors: [AppColors.primary, AppColors.accent ?? AppColors.primary],
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
                print('ChatDetailScreen back button pressed');
                widget.onBack();
                print('After calling onBack');
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
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.contact.isOnline
                              ? Colors.green
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.contact.isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${widget.contact.flight}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                /* Call */
              },
              icon: const Icon(Icons.call, color: Colors.white, size: 20),
            ),
            IconButton(
              onPressed: () {
                /* Video */
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
    return name.split(' ').map((n) => n[0]).take(2).join().toUpperCase();
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
                          AppColors.accent ?? AppColors.primary,
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
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      content: flightMessage,
      timestamp: _formatTime(DateTime.now()),
      type: MessageType.flight,
    );

    await ref.read(chatViewModelProvider.notifier).sendMessage(flightMessage);
    _scrollToBottom();
  }

  // Helper method to send location message
  Future<void> _sendLocationMessage() async {
    // In a real app, this would use a location service (e.g., geolocator package)
    // For now, we'll use a mock location
    const locationMessage = 'Current location: Airport Terminal 1';
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      content: locationMessage,
      timestamp: _formatTime(DateTime.now()),
      type: MessageType.location,
    );

    await ref.read(chatViewModelProvider.notifier).sendMessage(locationMessage);
    _scrollToBottom();
  }

  // Add this helper method to format time (copied from ChatViewModel for consistency)
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }
}
