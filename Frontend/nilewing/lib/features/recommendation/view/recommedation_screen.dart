// features/recommendations/screens/recommendations_screen.dart
import 'package:flutter/material.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recommendations'),
        backgroundColor: Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: Center(child: Text('Recommendations Screen - Under Development')),
    );
  }
}
