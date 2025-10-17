// // features/home/services/user_service.dart
import '../model/home_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // Get user profile
  Future<User> getUserProfile(String userId) async {
    // Simulate API delay
    await Future.delayed(Duration(milliseconds: 600));

    return User(
      name: "Markos Tesfaye",
      profileImage: null,
      email: "markos.tesfaye@email.com",
      nationality: "Ethiopian",
    );
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
