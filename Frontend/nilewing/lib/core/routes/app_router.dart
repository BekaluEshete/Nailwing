// app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nilewing/features/auth/view/login_screen.dart';
import 'package:nilewing/features/auth/view/registration_screen.dart';
import 'package:nilewing/features/home/view/home_screen.dart';
import 'package:nilewing/features/my_flights/view/flight_list_screen.dart';
import 'package:nilewing/features/onboarding/onboarding_view.dart';
import 'package:nilewing/features/recommendation/view/recommedation_screen.dart';
import 'package:nilewing/features/splash/splash_view.dart';
import 'package:nilewing/features/main_navigation/main_navigation_screen.dart';
// Import other screens when you create them
import 'package:nilewing/features/match/view/match_screen.dart';
import 'package:nilewing/features/chat/view/chat_screen.dart';

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

      GoRoute(
        path: '/registration',
        name: 'registration',
        builder: (context, state) => const RegistrationScreen(),
      ),

      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Main navigation shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationScreen(child: child);
        },
        routes: [
          // Nested routes for bottom navigation tabs
          GoRoute(
            path: '/myflights',
            name: 'myflights',
            builder: (context, state) => MyFlightsScreen(
              onNavigateBack: () {},
              onNavigateToAddFlight: () {
                // Handle navigation to add flight
                context.push('/addflight');
              },
              onNavigateToFlightDetail: (flightId) {
                // Handle navigation to flight detail
                context.push('/flight/$flightId');
              },
            ),
          ),

          GoRoute(
            path: '/match',
            name: 'match',
            builder: (context, state) => const MatchScreen(),
          ),

          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) => const ChatScreen(),
          ),

          GoRoute(
            path: '/recommendations',
            name: 'recommendations',
            builder: (context, state) => const RecommendationsScreen(),
          ),

          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
        ],
      ),

      // Standalone routes (not part of bottom navigation)
      // GoRoute(
      //   path: '/addflight',
      //   name: 'addflight',
      //   builder: (context, state) => const AddFlightScreen(), // Create this screen
      // ),

      // GoRoute(
      //   path: '/flight/:flightId',
      //   name: 'flightDetail',
      //   builder: (context, state) {
      //     final flightId = state.pathParameters['flightId']!;
      //     return FlightDetailScreen(flightId: flightId); // Create this screen
      //   },
      // ),
    ],

    // Optional: Redirect to home after auth
    redirect: (context, state) {
      // Add your authentication logic here
      // Example: if user is authenticated, redirect to home
      // if (isAuthenticated && state.location == '/login') return '/home';
      return null;
    },

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
