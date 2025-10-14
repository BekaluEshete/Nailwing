import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/login_model.dart';
import '../service/login_service.dart';

/// Riverpod provider for LoginViewModel
final loginViewModelProvider = ChangeNotifierProvider<LoginViewModel>(
  (ref) => LoginViewModel(),
);

class LoginViewModel with ChangeNotifier {
  final LoginService _loginService = LoginService();

  LoginData _loginData = LoginData(email: '', password: '', rememberMe: false);

  bool _isLoading = false;
  bool _showPassword = false;

  // Getters
  LoginData get loginData => _loginData;
  bool get isLoading => _isLoading;
  bool get showPassword => _showPassword;

  // Setters
  void setEmail(String value) {
    _loginData.email = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _loginData.password = value;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _loginData.rememberMe = value;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _showPassword = !_showPassword;
    notifyListeners();
  }

  Future<bool> login() async {
    if (_validateForm()) {
      _isLoading = true;
      notifyListeners();

      try {
        final success = await _loginService.loginUser(_loginData);
        _isLoading = false;
        notifyListeners();
        return success;
      } catch (e) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }
    return false;
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _loginService.loginWithGoogle();
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    if (email.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _loginService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  bool _validateForm() {
    return _loginData.email.isNotEmpty && _loginData.password.isNotEmpty;
  }

  void resetForm() {
    _loginData = LoginData(email: '', password: '', rememberMe: false);
    _showPassword = false;
    notifyListeners();
  }
}
