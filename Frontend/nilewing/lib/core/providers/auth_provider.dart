import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/core/utils/token_storage.dart';

// Authentication state provider
final authStateProvider = StateNotifierProvider<AuthStateNotifier, bool>((ref) {
  return AuthStateNotifier();
});

class AuthStateNotifier extends StateNotifier<bool> {
  final TokenStorage _tokenStorage = TokenStorage();

  AuthStateNotifier() : super(false) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await _tokenStorage.isLoggedIn();
    state = isLoggedIn;
  }

  Future<void> login() async {
    state = true;
  }

  Future<void> logout() async {
    await _tokenStorage.clearAll();
    state = false;
  }

  Future<void> refreshAuthStatus() async {
    await _checkAuthStatus();
  }
}

