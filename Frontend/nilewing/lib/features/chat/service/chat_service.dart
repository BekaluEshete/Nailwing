// features/chat/services/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nilewing/features/chat/model/chat_model.dart';

class ChatService {
  static const String _baseUrl =
      'https://your-api-url.com/api'; // Replace with actual API

  // Mock data - replace with actual API calls
  final List<ChatContact> _mockContacts = [
    ChatContact(
      id: '1',
      name: 'Elena Rodriguez',
      avatar: null,
      isOnline: true,
      lastMessage: 'See you at the gate! 🛫',
      timestamp: '5 min ago',
      unreadCount: 2,
      flight: 'IB6275',
      gate: 'B12',
    ),
    ChatContact(
      id: '2',
      name: 'Marcus Johnson',
      avatar: null,
      isOnline: true,
      lastMessage: 'Thanks for the coffee recommendation!',
      timestamp: '15 min ago',
      unreadCount: 0,
      flight: 'UA245',
      gate: 'C15',
    ),
    ChatContact(
      id: '3',
      name: 'Yuki Tanaka',
      avatar: null,
      isOnline: false,
      lastMessage:
          'The flight was amazing! Hope to travel together again soon.',
      timestamp: '2 hours ago',
      unreadCount: 1,
      flight: 'NH205',
      gate: 'A7',
    ),
    ChatContact(
      id: '4',
      name: 'Amara Okafor',
      avatar: null,
      isOnline: true,
      lastMessage: 'Let me know when you land safely!',
      timestamp: '1 day ago',
      unreadCount: 0,
      flight: 'AF447',
      gate: 'E8',
    ),
  ];

  final Map<String, List<ChatMessage>> _mockMessages = {
    '1': [
      ChatMessage(
        id: '1',
        senderId: '1',
        content: 'Hey! Are you also on the IB6275 flight to LA?',
        timestamp: '10:30 AM',
        type: MessageType.text,
      ),
      ChatMessage(
        id: '2',
        senderId: 'me',
        content:
            'Yes! I saw your profile and thought we might have a lot in common!',
        timestamp: '10:32 AM',
        type: MessageType.text,
      ),
      ChatMessage(
        id: '3',
        senderId: '1',
        content:
            'Perfect! Want to grab a coffee before boarding? I know a great spot near gate B12.',
        timestamp: '10:35 AM',
        type: MessageType.text,
      ),
      ChatMessage(
        id: '4',
        senderId: 'me',
        content: 'Sounds great! I love your photography work by the way.',
        timestamp: '10:37 AM',
        type: MessageType.text,
      ),
      ChatMessage(
        id: '5',
        senderId: '1',
        content: 'See you at the gate! 🛫',
        timestamp: '10:45 AM',
        type: MessageType.text,
      ),
    ],
    '2': [
      ChatMessage(
        id: '1',
        senderId: '2',
        content:
            'Hi! I noticed we\'re both business professionals. Are you traveling for work?',
        timestamp: '9:15 AM',
        type: MessageType.text,
      ),
      ChatMessage(
        id: '2',
        senderId: 'me',
        content: 'Yes, heading to a conference in Frankfurt. You?',
        timestamp: '9:20 AM',
        type: MessageType.text,
      ),
      ChatMessage(
        id: '3',
        senderId: '2',
        content: 'Client meetings. Maybe we can network during the layover?',
        timestamp: '9:25 AM',
        type: MessageType.text,
      ),
      ChatMessage(
        id: '4',
        senderId: 'me',
        content:
            'Absolutely! Do you know any good coffee spots in the airport?',
        timestamp: '9:30 AM',
        type: MessageType.text,
      ),
      ChatMessage(
        id: '5',
        senderId: '2',
        content: 'Thanks for the coffee recommendation!',
        timestamp: '9:45 AM',
        type: MessageType.text,
      ),
    ],
  };

  Future<List<ChatContact>> getContacts() async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));

      // In real app, make API call:
      // final response = await http.get(Uri.parse('$_baseUrl/contacts'));
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   return (data['contacts'] as List).map((contact) => ChatContact.fromJson(contact)).toList();
      // }

      return _mockContacts;
    } catch (e) {
      throw Exception('Failed to load contacts: $e');
    }
  }

  Future<List<ChatMessage>> getMessages(String contactId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      // In real app:
      // final response = await http.get(Uri.parse('$_baseUrl/contacts/$contactId/messages'));
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   return (data['messages'] as List).map((msg) => ChatMessage.fromJson(msg)).toList();
      // }

      return _mockMessages[contactId] ?? [];
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  Future<void> sendMessage(String contactId, String message) async {
    try {
      // In real app:
      // final response = await http.post(
      //   Uri.parse('$_baseUrl/contacts/$contactId/messages'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({'content': message, 'type': 'text'}),
      // );

      // if (response.statusCode != 200) {
      //   throw Exception('Failed to send message');
      // }

      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> markAsRead(String contactId) async {
    try {
      // In real app:
      // await http.put(Uri.parse('$_baseUrl/contacts/$contactId/read'));

      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }
}
