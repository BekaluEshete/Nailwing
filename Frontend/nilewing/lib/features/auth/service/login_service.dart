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
      final response = await http
          .post(
            Uri.parse(AppConstants.loginEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(loginData.toJson()),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Connection timeout. Please check your internet connection and try again.',
              );
            },
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
    } on http.ClientException catch (e) {
      String errorMessage = 'Cannot connect to server';
      if (e.message.contains('Failed host lookup') ||
          e.message.contains('SocketException')) {
        errorMessage =
            'Cannot reach the server. Please check:\n'
            '• Your internet connection\n'
            '• The backend server is running\n'
            '• The server URL is correct';
      } else if (e.message.contains('timeout')) {
        errorMessage =
            'Connection timeout. The server may be slow or unavailable. Please try again.';
      }
      return LoginResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      String errorMessage = 'Network error occurred';
      final errorString = e.toString();
      if (errorString.contains('Failed host lookup') ||
          errorString.contains('SocketException')) {
        errorMessage =
            'Cannot reach the server. Please check:\n'
            '• Your internet connection\n'
            '• The backend server is running\n'
            '• The server URL is correct';
      }
      return LoginResponse(
        success: false,
        message: errorMessage,
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
