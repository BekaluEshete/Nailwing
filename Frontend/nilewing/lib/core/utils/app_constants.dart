class AppConstants {
  // Backend API Base URL
  // For Android Emulator, use: http://10.0.2.2:8000
  // For iOS Simulator, use: http://localhost:8000
  // For Physical Device, use: http://YOUR_COMPUTER_IP:8000
  static const String baseUrl = 'http://10.0.2.2:8000';

  // API Endpoints
  static const String apiBaseUrl = '$baseUrl/api';
  static const String authBaseUrl = '$apiBaseUrl/auth';

  // Auth Endpoints
  static const String registerEndpoint = '$authBaseUrl/register/';
  static const String loginEndpoint = '$authBaseUrl/login/';
  static const String logoutEndpoint = '$authBaseUrl/logout/';
  static const String profileEndpoint = '$authBaseUrl/profile/';
  static const String tokenRefreshEndpoint = '$apiBaseUrl/token/refresh/';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
}
