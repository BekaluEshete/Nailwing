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
  static const String changePasswordEndpoint = '$authBaseUrl/change_password/';
  static const String tokenRefreshEndpoint = '$apiBaseUrl/token/refresh/';

  // User Endpoints
  static const String userProfileEndpoint = '$authBaseUrl/profile/';

  // Flight Endpoints
  static const String flightsBaseUrl = '$apiBaseUrl/flights';
  static const String flightsEndpoint = '$flightsBaseUrl/flights/';
  static const String upcomingFlightsEndpoint = '$flightsEndpoint/upcoming/';
  static const String currentFlightEndpoint = '$flightsEndpoint/current/';
  static const String interestsEndpoint = '$flightsBaseUrl/interests/';
  static const String preferencesEndpoint = '$flightsBaseUrl/preferences/';

  // Matching Endpoints
  static const String matchingBaseUrl = '$apiBaseUrl/matching';
  static const String matchesEndpoint = '$matchingBaseUrl/matches';
  static const String findMatchesEndpoint = '$matchesEndpoint/find_matches/';
  static const String matchFiltersEndpoint = '$matchingBaseUrl/filters';

  // Recommendations Endpoints
  static const String recommendationsBaseUrl = '$apiBaseUrl/recommendations';
  static const String placesEndpoint = '$recommendationsBaseUrl/places/';
  static const String recommendationsEndpoint =
      '$recommendationsBaseUrl/recommendations/';
  
  // Google Maps API
  static const String googleMapsApiKey = 'AIzaSyDHzbqstWXpYy7ce4IN-J-2YYKBxKrE2dk';

  // Chat Endpoints
  static const String chatBaseUrl = '$baseUrl/chat';
  static const String chatRoomsEndpoint = '$chatBaseUrl/api/rooms/';
  static const String chatMessagesEndpoint = '$chatBaseUrl/api/rooms';
  // WebSocket URL (computed, not const)
  static String get chatWebSocketUrl {
    final wsBase = baseUrl.replaceAll('https://', '').replaceAll('http://', '');
    return 'ws://$wsBase/ws/chat';
  }

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
}
