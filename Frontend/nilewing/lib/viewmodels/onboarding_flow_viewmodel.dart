import 'package:flutter/material.dart';

class OnboardingViewModel {
  int _currentScreen = 0;
  int get currentScreen => _currentScreen;

  final List<Map<String, dynamic>> screens = [
    {
      'title': 'Meet People While Travelling',
      'description':
          'Connect with fellow travelers during layovers and flights. Share experiences and make new friends on your journey.',
    },
    {
      'title': 'Real Time Location Matching',
      'description':
          'Get matched with travelers at your current airport or destination. Find people with similar interests nearby.',
    },
    {
      'title': 'Chat and Explore Together',
      'description':
          'Start conversations, share travel tips, and plan activities together. Make your layover time more enjoyable and productive.',
    },
  ];

  void nextScreen() {
    if (_currentScreen < screens.length - 1) {
      _currentScreen++;
    }
  }

  void prevScreen() {
    if (_currentScreen > 0) {
      _currentScreen--;
    }
  }

  void completeOnboarding(BuildContext context) {
    // Navigator.of(context).pushReplacement(
    //   MaterialPageRoute(builder: (context) => const RegistrationScreen()),
    // );
  }
}
