import 'package:nilewing/features/auth/model/login_model.dart';

class LoginService {
  static final LoginService _instance = LoginService._internal();
  factory LoginService() => _instance;
  LoginService._internal();

  Future<bool> loginUser(LoginData loginData) async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 2));
    print('Login attempt: ${loginData.toJson()}');

    // Simulate successful login for demo
    // In real app, you would make actual API call here
    return true;
  }

  Future<bool> loginWithGoogle() async {
    // Simulate Google OAuth
    await Future.delayed(Duration(seconds: 2));
    print('Google login initiated');
    return true;
  }

  Future<bool> resetPassword(String email) async {
    // Simulate password reset
    await Future.delayed(Duration(seconds: 2));
    print('Password reset requested for: $email');
    return true;
  }
}
