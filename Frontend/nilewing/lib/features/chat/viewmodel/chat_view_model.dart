// features/chat/viewmodels/chat_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/features/chat/model/chat_model.dart';
import 'package:nilewing/features/chat/service/chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final chatViewModelProvider = StateNotifierProvider<ChatViewModel, ChatState>((
  ref,
) {
  return ChatViewModel(ref);
});

class ChatViewModel extends StateNotifier<ChatState> {
  final Ref _ref;
  late final ChatService _chatService;

  ChatViewModel(this._ref)
    : super(const ChatState(contacts: [], messages: {})) {
    _chatService = _ref.read(chatServiceProvider);
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final contacts = await _chatService.getContacts();
      state = state.copyWith(contacts: contacts, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> selectChat(String contactId) async {
    state = state.copyWith(selectedChatId: contactId, error: null);

    try {
      // Mark messages as read
      await _chatService.markAsRead(contactId);

      // Load messages for this chat
      final messages = await _chatService.getMessages(contactId);

      // Update state with loaded messages
      final updatedMessages = Map<String, List<ChatMessage>>.from(
        state.messages,
      );
      updatedMessages[contactId] = messages;

      state = state.copyWith(messages: updatedMessages);

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

  void clearSelectedChat() {
    print(
      'Clearing selected chat: current selectedChatId = ${state.selectedChatId}',
    );
    state = state.copyWith(selectedChatId: null);
    print(
      'After clearing: selectedChatId = ${state.selectedChatId}, selectedContact = ${state.selectedContact}',
    );
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || state.selectedChatId == null) return;

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      content: message.trim(),
      timestamp: _formatTime(DateTime.now()),
      type: MessageType.text,
    );

    try {
      // Update local state immediately for better UX
      final updatedMessages = Map<String, List<ChatMessage>>.from(
        state.messages,
      );
      final currentMessages = updatedMessages[state.selectedChatId!] ?? [];
      updatedMessages[state.selectedChatId!] = [...currentMessages, newMessage];

      state = state.copyWith(messages: updatedMessages);

      // Send to server
      await _chatService.sendMessage(state.selectedChatId!, message.trim());
    } catch (e) {
      state = state.copyWith(error: 'Failed to send message: $e');
      // Optionally, remove the message from local state if sending fails
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }
}
