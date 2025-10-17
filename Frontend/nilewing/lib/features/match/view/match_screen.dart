// features/match/screens/match_screen.dart
import 'package:flutter/material.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Travel Matches'),
        backgroundColor: Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: Center(child: Text('Match Screen - Under Development')),
    );
  }
}
