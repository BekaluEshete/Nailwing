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
  final String timestamp; // Display timestamp (formatted)
  final String? isoTimestamp; // ISO timestamp for sorting (nullable for backward compatibility)
  final MessageType type;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isoTimestamp,
    required this.type,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['senderId'],
      content: json['content'],
      timestamp: json['timestamp'],
      isoTimestamp: json['isoTimestamp'],
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
      'isoTimestamp': isoTimestamp,
      'type': type.name,
    };
  }
  
  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? content,
    String? timestamp,
    String? isoTimestamp,
    MessageType? type,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isoTimestamp: isoTimestamp ?? this.isoTimestamp,
      type: type ?? this.type,
    );
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
  final Map<String, bool> typingUsers; // Map of chatId -> userId -> isTyping
  final Map<String, Set<String>> onlineUsers; // Map of chatId -> Set of online user IDs

  const ChatState({
    required this.contacts,
    required this.messages,
    this.selectedChatId,
    this.isLoading = false,
    this.error,
    Map<String, bool>? typingUsers,
    Map<String, Set<String>>? onlineUsers,
  }) : typingUsers = typingUsers ?? const {},
       onlineUsers = onlineUsers ?? const {};

  ChatState copyWith({
    List<ChatContact>? contacts,
    Map<String, List<ChatMessage>>? messages,
    String? selectedChatId,
    bool? isLoading,
    String? error,
    Map<String, bool>? typingUsers,
    Map<String, Set<String>>? onlineUsers,
  }) {
    return ChatState(
      contacts: contacts ?? this.contacts,
      messages: messages ?? this.messages,
      selectedChatId: selectedChatId ?? this.selectedChatId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      typingUsers: typingUsers ?? this.typingUsers,
      onlineUsers: onlineUsers ?? this.onlineUsers,
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
