// // features/home/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nilewing/core/utils/app_constants.dart';
import 'package:nilewing/core/utils/token_storage.dart';
import '../model/home_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final TokenStorage _tokenStorage = TokenStorage();

  Future<String?> _getAuthToken() async {
    return await _tokenStorage.getAccessToken();
  }

  // Get user profile from backend
  Future<User> getUserProfile(String userId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(AppConstants.profileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] != null) {
          final userData = responseData['data'] as Map<String, dynamic>;
          
          // Map backend user data to home User model
          return User(
            name: userData['fullName'] ?? 'User',
            profileImage: userData['profileImageUrl'] ?? userData['profileImage'],
            email: userData['email'] ?? '',
            nationality: userData['nationality'] ?? '',
          );
        }
        throw Exception('Failed to load profile');
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading user profile: $e');
      // Fallback to stored user data if available
      final storedUserData = await _tokenStorage.getUserData();
      if (storedUserData != null) {
        return User(
          name: storedUserData['fullName'] ?? 'User',
          profileImage: storedUserData['profileImageUrl'] ?? storedUserData['profileImage'],
          email: storedUserData['email'] ?? '',
          nationality: storedUserData['nationality'] ?? '',
        );
      }
      // Last resort fallback
      return User(
        name: "User",
        profileImage: null,
        email: "",
        nationality: "",
      );
    }
  }

  // Get user notifications
  Future<List<Notification>> getUserNotifications(String userId) async {
    await Future.delayed(Duration(milliseconds: 400));

    return [
      Notification(
        id: '1',
        title: 'Flight ET302 Reminder',
        message: 'Your flight to Paris departs in 5 hours',
        type: 'flight_reminder',
        isRead: false,
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
      ),
      Notification(
        id: '2',
        title: 'New Match Found',
        message: 'You have a new travel companion match',
        type: 'match',
        isRead: false,
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
      ),
      Notification(
        id: '3',
        title: 'Check-in Available',
        message: 'Check-in is now available for your flight',
        type: 'checkin',
        isRead: true,
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
      ),
    ];
  }

  // Get notification count
  Future<int> getNotificationCount(String userId) async {
    final notifications = await getUserNotifications(userId);
    return notifications.where((n) => !n.isRead).length;
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(
    String notificationId,
    String userId,
  ) async {
    await Future.delayed(Duration(milliseconds: 200));
    // Simulate successful update
    return true;
  }

  // Update user profile
  Future<bool> updateUserProfile(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    await Future.delayed(Duration(seconds: 1));
    // Simulate successful update
    return true;
  }

  // Get user preferences
  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    await Future.delayed(Duration(milliseconds: 300));

    return {
      'language': 'English',
      'currency': 'USD',
      'notifications': {
        'flightUpdates': true,
        'matches': true,
        'promotions': false,
      },
      'privacy': {'profileVisible': true, 'locationSharing': true},
    };
  }
}
