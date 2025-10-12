import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final splashViewModelProvider = StateNotifierProvider<SplashViewModel, bool>((
  ref,
) {
  return SplashViewModel();
});

class SplashViewModel extends StateNotifier<bool> {
  SplashViewModel() : super(false);

  void navigateToOnboarding(BuildContext context) {
    context.go('/onboarding');
  }
}
