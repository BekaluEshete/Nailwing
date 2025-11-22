class AppConstants {
  // Backend API Base URL - Production
  static const String baseUrl = 'https://nilewing-backend.onrender.com';

  // For local development, uncomment one of these:
  // Android Emulator: static const String baseUrl = 'http://10.0.2.2:8000';
  // iOS Simulator: static const String baseUrl = 'http://localhost:8000';
  // Physical Device: static const String baseUrl = 'http://YOUR_COMPUTER_IP:8000';

  // API Endpoints
  static const String apiBaseUrl = '$baseUrl/api';
  static const String authBaseUrl = '$apiBaseUrl/auth';

  // Auth Endpoints
  static const String registerEndpoint = '$authBaseUrl/register/';
  static const String loginEndpoint = '$authBaseUrl/login/';
  static const String logoutEndpoint = '$authBaseUrl/logout/';
  static const String profileEndpoint = '$authBaseUrl/profile/';
  static const String tokenRefreshEndpoint = '$apiBaseUrl/token/refresh/';

  // User Endpoints
  static const String userProfileEndpoint = '$authBaseUrl/profile/';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
}
