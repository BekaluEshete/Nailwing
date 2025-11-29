import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nilewing/core/utils/app_constants.dart';
import 'package:nilewing/core/utils/token_storage.dart';

/// Service to handle token refresh automatically
class TokenRefreshService {
  static final TokenRefreshService _instance = TokenRefreshService._internal();
  factory TokenRefreshService() => _instance;
  TokenRefreshService._internal();

  final TokenStorage _tokenStorage = TokenStorage();
  bool _isRefreshing = false;
  final List<Future<void> Function(String)> _pendingRequests = [];

  /// Refresh the access token using the refresh token
  Future<String?> refreshAccessToken() async {
    // If already refreshing, wait for the current refresh to complete
    if (_isRefreshing) {
      return await _waitForRefresh();
    }

    _isRefreshing = true;
    try {
      print('🔄 [TokenRefresh] Refreshing access token...');
      
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        print('❌ [TokenRefresh] No refresh token found');
        _isRefreshing = false;
        return null;
      }

      final response = await http.post(
        Uri.parse(AppConstants.tokenRefreshEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refreshToken}),
      );

      print('📥 [TokenRefresh] Response status: ${response.statusCode}');
      print('📥 [TokenRefresh] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        final newAccessToken = responseData['access'] as String?;
        
        if (newAccessToken != null) {
          await _tokenStorage.saveAccessToken(newAccessToken);
          print('✅ [TokenRefresh] Access token refreshed successfully');
          
          // Notify all pending requests
          for (var callback in _pendingRequests) {
            try {
              await callback(newAccessToken);
            } catch (e) {
              print('❌ [TokenRefresh] Error in pending request callback: $e');
            }
          }
          _pendingRequests.clear();
          
          _isRefreshing = false;
          return newAccessToken;
        }
      }

      // If refresh failed, clear tokens and logout
      print('❌ [TokenRefresh] Token refresh failed: ${response.statusCode}');
      await _tokenStorage.clearAll();
      _isRefreshing = false;
      return null;
    } catch (e) {
      print('❌ [TokenRefresh] Error refreshing token: $e');
      await _tokenStorage.clearAll();
      _isRefreshing = false;
      return null;
    }
  }

  /// Wait for the current refresh operation to complete
  Future<String?> _waitForRefresh() async {
    // Wait a bit and check if refresh completed
    int attempts = 0;
    while (_isRefreshing && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    return await _tokenStorage.getAccessToken();
  }

  /// Check if token is expired (basic check - in production, decode JWT)
  Future<bool> isTokenExpired() async {
    // For now, we'll rely on 401 responses to detect expiration
    // In production, you could decode the JWT and check the exp claim
    return false;
  }
}

