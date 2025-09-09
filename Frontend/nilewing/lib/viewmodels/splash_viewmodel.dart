import 'package:flutter/material.dart';
import 'package:nilewing/views/screens/onboarding_flow_screen.dart';

class SplashViewModel {
  Future<void> navigateAfterDelay(BuildContext context) async {
    await Future.delayed(
      const Duration(seconds: 5),
    ); // 5 seconds as in the original
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }
}
