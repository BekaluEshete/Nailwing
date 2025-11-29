// app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nilewing/features/auth/view/login_screen.dart';
import 'package:nilewing/features/auth/view/registration_screen.dart';
import 'package:nilewing/features/chat/view/chat_detail_screen.dart';
import 'package:nilewing/features/chat/viewmodel/chat_view_model.dart';
import 'package:nilewing/features/chat/model/chat_model.dart';
import 'package:nilewing/features/home/view/home_screen.dart';
import 'package:nilewing/features/my_flights/view/flight_list_screen.dart';
import 'package:nilewing/features/onboarding/onboarding_view.dart';
import 'package:nilewing/features/recommendation/view/recommemdation_screen.dart';
import 'package:nilewing/features/splash/splash_view.dart';
import 'package:nilewing/features/main_navigation/main_navigation_screen.dart';
import 'package:nilewing/core/providers/auth_provider.dart';
import 'package:nilewing/features/user/view/profile_screen.dart';
// Import other screens when you create them
import 'package:nilewing/features/match/view/match_screen.dart';
import 'package:nilewing/features/match/view/connection_requests_screen.dart';
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
        builder: (context, state) => LoginScreen(
          onLoginSuccess: () {
            context.go('/home');
          },
        ),
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
            builder: (context, state) => MatchScreen(
              onNavigateBack: () {
                // Navigate back to home or another route when back is pressed
                context.go('/home');
              },
            ),
          ),

          GoRoute(
            path: '/connection-requests',
            name: 'connectionRequests',
            builder: (context, state) => ConnectionRequestsScreen(
              onNavigateBack: () {
                context.pop();
              },
            ),
          ),

          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) => ChatScreen(
              onNavigateBack: () {
                // Navigate back to home or another route when back is pressed
                context.go('/home');
              },
            ),
          ),

          GoRoute(
            path: '/recommendations',
            name: 'recommendations',
            builder: (context, state) => RecommendationsScreen(
              onNavigateBack: () {
                // Navigate back to home or another route when back is pressed
                context.go('/home');
              },
            ),
          ),

          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => HomeScreen(
              onNavigateToProfile: () {
                context.go('/profile');
              },
            ),
          ),

          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/chat/:contactId',
        name: 'chatDetail',
        builder: (context, state) {
          final contactId = state.pathParameters['contactId']!;
          // Use a Consumer to access Riverpod providers (we're in a regular builder)
          return Consumer(
            builder: (context, ref, _) {
              final chatState = ref.watch(chatViewModelProvider);
              final chatViewModel = ref.read(chatViewModelProvider.notifier);
              
              // Try to find the contact
              ChatContact? contact;
              try {
                contact = chatState.contacts.firstWhere(
                  (c) => c.id == contactId,
                );
                print('✅ [AppRouter] Found contact: ${contact.name}');
              } catch (e) {
                // Contact not found - refresh contacts and show loading
                print('⚠️ [AppRouter] Contact $contactId not found, refreshing contacts...');
                chatViewModel.refreshContacts();
                
                // Show loading screen while we wait
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Loading Chat...'),
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const Text('Loading chat...'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Try to refresh and navigate again
                            chatViewModel.refreshContacts();
                            Future.delayed(const Duration(milliseconds: 500), () {
                              final updatedState = ref.read(chatViewModelProvider);
                              try {
                                updatedState.contacts.firstWhere(
                                  (c) => c.id == contactId,
                                );
                                // If found, refresh to trigger rebuild
                                ref.invalidate(chatViewModelProvider);
                              } catch (e) {
                                // Still not found, go back
                                if (context.mounted) {
                                  context.pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Chat not found. Please try again.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Contact found - show chat screen
              return ChatDetailScreen(
                contact: contact,
                onBack: () => context.pop(),
              );
            },
          );
        },
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

    // Authentication guard - redirect based on auth status
    redirect: (BuildContext context, GoRouterState state) {
      try {
        final container = ProviderScope.containerOf(context);
        final isAuthenticated = container.read(authStateProvider);

        // List of public routes that don't require authentication
        final publicRoutes = [
          '/splash',
          '/onboarding',
          '/login',
          '/registration',
        ];
        final currentLocation = state.uri.path;
        final isPublicRoute = publicRoutes.contains(currentLocation);

        // If user is not authenticated and trying to access protected route
        if (!isAuthenticated && !isPublicRoute) {
          return '/login';
        }

        // If user is authenticated and trying to access auth pages
        if (isAuthenticated &&
            (currentLocation == '/login' ||
                currentLocation == '/registration')) {
          return '/home';
        }

        return null; // No redirect needed
      } catch (e) {
        // If there's an error accessing the provider, allow navigation
        // This can happen during initial app load
        return null;
      }
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
