// features/chat/models/chat_models.dart
class ChatContact {
  final String id;
  final String name;
  final String? avatar;
  final bool isOnline;
  final String lastMessage;
  final String timestamp;
  final int unreadCount;
  final String flight;
  final String gate;

  ChatContact({
    required this.id,
    required this.name,
    this.avatar,
    required this.isOnline,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.flight,
    required this.gate,
  });

  factory ChatContact.fromJson(Map<String, dynamic> json) {
    return ChatContact(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      isOnline: json['isOnline'],
      lastMessage: json['lastMessage'],
      timestamp: json['timestamp'],
      unreadCount: json['unreadCount'],
      flight: json['flight'],
      gate: json['gate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'isOnline': isOnline,
      'lastMessage': lastMessage,
      'timestamp': timestamp,
      'unreadCount': unreadCount,
      'flight': flight,
      'gate': gate,
    };
  }

  ChatContact copyWith({
    String? id,
    String? name,
    String? avatar,
    bool? isOnline,
    String? lastMessage,
    String? timestamp,
    int? unreadCount,
    String? flight,
    String? gate,
  }) {
    return ChatContact(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isOnline: isOnline ?? this.isOnline,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      flight: flight ?? this.flight,
      gate: gate ?? this.gate,
    );
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final String timestamp;
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.type,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['senderId'],
      content: json['content'],
      timestamp: json['timestamp'],
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp,
      'type': type.name,
    };
  }

  bool get isMe => senderId == 'me';
}

enum MessageType {
  text('text'),
  flight('flight'),
  location('location');

  const MessageType(this.name);
  final String name;
}

class ChatState {
  final List<ChatContact> contacts;
  final Map<String, List<ChatMessage>> messages;
  final String? selectedChatId;
  final bool isLoading;
  final String? error;

  const ChatState({
    required this.contacts,
    required this.messages,
    this.selectedChatId,
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatContact>? contacts,
    Map<String, List<ChatMessage>>? messages,
    String? selectedChatId,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      contacts: contacts ?? this.contacts,
      messages: messages ?? this.messages,
      selectedChatId: selectedChatId ?? this.selectedChatId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  ChatContact? get selectedContact {
    if (selectedChatId == null || contacts.isEmpty) return null;
    try {
      return contacts.firstWhere(
        (contact) => contact.id == selectedChatId,
      );
    } catch (e) {
      return null;
    }
  }

  List<ChatMessage> get selectedMessages {
    if (selectedChatId == null) return [];
    return messages[selectedChatId] ?? [];
  }

  List<ChatContact> get onlineContacts {
    return contacts.where((contact) => contact.isOnline).toList();
  }
}
