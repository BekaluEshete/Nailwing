// services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nilewing/features/home/model/home_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String baseUrl =
      'https://your-api-domain.com/api'; // Replace with your API

  // Get user profile
  Future<User> getUserProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/profile'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for demo
      return getMockUser();
    }
  }

  // Update user profile
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/profile'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profileData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get user notifications
  Future<List<Notification>> getUserNotifications(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/notifications'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((notification) => Notification.fromJson(notification))
            .toList();
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for demo
      return getMockNotifications();
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(
    String userId,
    String notificationId,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId/notifications/$notificationId/read'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to mark notification as read: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mock data methods
  User getMockUser() {
    return User(
      name: "Markos",
      profileImage: null,
      nationality: "Ethiopian",
      languages: ["English", "Amharic"],
      currentFlight: "EK215",
      flightStatus: "In Transit",
      currentLocation: "Dubai International",
      nextFlight: "ET302",
    );
  }

  List<Notification> getMockNotifications() {
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
    ];
  }
}
