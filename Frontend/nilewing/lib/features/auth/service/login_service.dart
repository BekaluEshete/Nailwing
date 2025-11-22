import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nilewing/features/auth/model/login_model.dart';
import 'package:nilewing/core/utils/app_constants.dart';
import 'package:nilewing/core/utils/token_storage.dart';

class LoginService {
  static final LoginService _instance = LoginService._internal();
  factory LoginService() => _instance;
  LoginService._internal();

  final TokenStorage _tokenStorage = TokenStorage();

  Future<LoginResponse> loginUser(LoginData loginData) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(loginData.toJson()),
      );

      final responseData = json.decode(response.body) as Map<String, dynamic>;
      final loginResponse = LoginResponse.fromJson(responseData);

      if (loginResponse.success && loginResponse.data != null) {
        // Save tokens
        await _tokenStorage.saveAccessToken(loginResponse.data!.tokens.access);
        await _tokenStorage.saveRefreshToken(
          loginResponse.data!.tokens.refresh,
        );

        // Save user data
        await _tokenStorage.saveUserData(loginResponse.data!.user.toJson());
      }

      return loginResponse;
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<bool> loginWithGoogle() async {
    // TODO: Implement Google OAuth when backend supports it
    await Future.delayed(Duration(seconds: 2));
    print('Google login initiated');
    return false;
  }

  Future<bool> resetPassword(String email) async {
    // TODO: Implement password reset when backend supports it
    await Future.delayed(Duration(seconds: 2));
    print('Password reset requested for: $email');
    return false;
  }

  Future<bool> logout() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken != null) {
        final response = await http.post(
          Uri.parse(AppConstants.logoutEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'refresh_token': refreshToken}),
        );

        if (response.statusCode == 200 || response.statusCode == 205) {
          await _tokenStorage.clearAll();
          return true;
        }
      }

      // Clear tokens even if API call fails
      await _tokenStorage.clearAll();
      return true;
    } catch (e) {
      // Clear tokens even if API call fails
      await _tokenStorage.clearAll();
      return true;
    }
  }

  Future<String?> getAccessToken() async {
    return await _tokenStorage.getAccessToken();
  }

  Future<bool> isLoggedIn() async {
    return await _tokenStorage.isLoggedIn();
  }
}
