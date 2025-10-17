// features/chat/screens/chat_screen.dart
import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        backgroundColor: Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: Center(child: Text('Chat Screen - Under Development')),
    );
  }
}
