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
import 'package:nilewing/features/match/view/match_screen.dart';
import 'package:nilewing/features/match/view/connection_requests_screen.dart';
import 'package:nilewing/features/chat/view/chat_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
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
          onLoginSuccess: () => context.go('/home'),
        ),
      ),

      // Shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) =>
            MainNavigationScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => HomeScreen(
              onNavigateToProfile: () => context.go('/profile'),
              onNavigateToMyFlights: () => context.go('/myflights'),
              onNavigateToMatch: () => context.go('/match'),
              onNavigateToPreFlightMatching: () => context.go('/match'),
              onNavigateToChat: () => context.go('/chat'),
              onNavigateToRecommendations: () => context.go('/recommendations'),
            ),
          ),
          GoRoute(
            path: '/myflights',
            name: 'myflights',
            builder: (context, state) => MyFlightsScreen(
              onNavigateBack: () {},
              onNavigateToAddFlight: () => context.push('/addflight'),
              onNavigateToFlightDetail: (flightId) =>
                  context.push('/flight/$flightId'),
            ),
          ),
          GoRoute(
            path: '/match',
            name: 'match',
            builder: (context, state) =>
                MatchScreen(onNavigateBack: () => context.go('/home')),
          ),
          GoRoute(
            path: '/connection-requests',
            name: 'connectionRequests',
            builder: (context, state) =>
                ConnectionRequestsScreen(onNavigateBack: () => context.pop()),
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) =>
                ChatScreen(onNavigateBack: () => context.go('/home')),
          ),
          GoRoute(
            path: '/recommendations',
            name: 'recommendations',
            builder: (context, state) => RecommendationsScreen(
                onNavigateBack: () => context.go('/home')),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Chat detail — outside shell (no bottom nav)
      GoRoute(
        path: '/chat/:contactId',
        name: 'chatDetail',
        builder: (context, state) {
          final contactId = state.pathParameters['contactId']!;
          return Consumer(
            builder: (context, ref, _) {
              final chatState = ref.watch(chatViewModelProvider);
              final chatViewModel = ref.read(chatViewModelProvider.notifier);

              ChatContact? contact;
              try {
                contact =
                    chatState.contacts.firstWhere((c) => c.id == contactId);
              } catch (_) {
                chatViewModel.refreshContacts();
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
                            chatViewModel.refreshContacts();
                            Future.delayed(
                                const Duration(milliseconds: 500), () {
                              try {
                                ref
                                    .read(chatViewModelProvider)
                                    .contacts
                                    .firstWhere((c) => c.id == contactId);
                                ref.invalidate(chatViewModelProvider);
                              } catch (_) {
                                if (context.mounted) {
                                  context.pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Chat not found. Please try again.'),
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

              return ChatDetailScreen(
                contact: contact,
                onBack: () => context.pop(),
              );
            },
          );
        },
      ),
    ],
  );
});

final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _subscription = _ref.listen(authStateProvider, (previous, next) {
      if (previous != next) {
        debugPrint('RouterNotifier: Auth state changed from $previous to $next');
        notifyListeners();
      }
    });
  }

  ProviderSubscription? _subscription;

  String? redirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = _ref.read(authStateProvider);
    debugPrint('Router Redirect Check: path=${state.uri.path}, auth=$isAuthenticated');

    const publicRoutes = ['/splash', '/onboarding', '/login', '/registration'];
    final path = state.uri.path;
    final isPublic = publicRoutes.contains(path);

    if (!isAuthenticated && !isPublic) return '/login';
    if (isAuthenticated && (path == '/login' || path == '/registration')) {
      return '/home';
    }
    return null;
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }
}
