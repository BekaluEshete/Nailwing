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

  // Validation properties
  String _emailError = '';
  String _passwordError = '';

  // Getters
  LoginData get loginData => _loginData;
  bool get isLoading => _isLoading;
  bool get showPassword => _showPassword;
  String get emailError => _emailError;
  String get passwordError => _passwordError;

  // Check if form is valid
  bool get isFormValid {
    return _emailError.isEmpty &&
        _passwordError.isEmpty &&
        _loginData.email.isNotEmpty &&
        _loginData.password.isNotEmpty;
  }

  // Setters
  void setEmail(String value) {
    _loginData.email = value;
    _validateEmail(value);
    notifyListeners();
  }

  void setPassword(String value) {
    _loginData.password = value;
    _validatePassword(value);
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

  // Validation methods
  void _validateEmail(String email) {
    if (email.isEmpty) {
      _emailError = 'Email is required';
    } else if (!_isValidEmail(email)) {
      _emailError = 'Please enter a valid email address';
    } else {
      _emailError = '';
    }
  }

  void _validatePassword(String password) {
    if (password.isEmpty) {
      _passwordError = 'Password is required';
    } else if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
    } else {
      _passwordError = '';
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegex.hasMatch(email);
  }

  Future<bool> login() async {
    // Validate all fields before attempting login
    _validateEmail(_loginData.email);
    _validatePassword(_loginData.password);

    if (!isFormValid) {
      notifyListeners();
      return false;
    }

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

  void resetForm() {
    _loginData = LoginData(email: '', password: '', rememberMe: false);
    _showPassword = false;
    _emailError = '';
    _passwordError = '';
    notifyListeners();
  }
}
