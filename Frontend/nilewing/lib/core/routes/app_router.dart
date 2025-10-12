import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nilewing/features/onboarding/onboarding_view.dart';
import 'package:nilewing/features/splash/splash_view.dart';

// Import your feature views

/// Centralized app router using GoRouter.
/// Works perfectly with Riverpod and MVVM structure.
class AppRouter {
  static final GoRouter router = GoRouter(
    // The first screen shown when the app starts
    initialLocation: '/splash',

    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashView(),
      ),

      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingView(),
      ),

      // GoRoute(
      //   path: '/home',
      //   name: 'home',
      //   builder: (context, state) => const HomeView(),
      // ),
    ],

    // Optional: Handle wrong URLs gracefully
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          '404 — Page not found',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    ),
  );
}
