// features/home/model/home_model.dart
import 'dart:ui';

class User {
  final String name;
  final String? profileImage;
  final String email;
  final String nationality;

  User({
    required this.name,
    this.profileImage,
    required this.email,
    required this.nationality,
  });
}

class Flight {
  final String flightNumber;
  final String airline;
  final String route;
  final FlightLeg departure;
  final FlightLeg arrival;
  final String duration;
  final String aircraft;
  final String seat;
  final String gate;
  final String status;
  final String checkInTime;
  final String boardingTime;
  final String timeUntilDeparture;

  Flight({
    required this.flightNumber,
    required this.airline,
    required this.route,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.aircraft,
    required this.seat,
    required this.gate,
    required this.status,
    required this.checkInTime,
    required this.boardingTime,
    required this.timeUntilDeparture,
  });
}

class FlightLeg {
  final String airport;
  final String city;
  final String time;
  final String date;
  final String terminal;

  FlightLeg({
    required this.airport,
    required this.city,
    required this.time,
    required this.date,
    required this.terminal,
  });
}

class FlightPost {
  final String id;
  final PostUser user;
  final PostFlight flight;
  final PostContent post;

  FlightPost({
    required this.id,
    required this.user,
    required this.flight,
    required this.post,
  });

  factory FlightPost.fromJson(Map<String, dynamic> json) {
    return FlightPost(
      id: json['id']?.toString() ?? '',
      user: PostUser.fromJson(json['user'] ?? {}),
      flight: PostFlight.fromJson(json['flight'] ?? {}),
      post: PostContent.fromJson(json['post'] ?? {}),
    );
  }
}

class PostUser {
  final String name;
  final String? avatar;
  final String nationality;

  PostUser({required this.name, this.avatar, required this.nationality});

  factory PostUser.fromJson(Map<String, dynamic> json) {
    return PostUser(
      name: json['name'] ?? 'User',
      avatar: json['avatar'],
      nationality: json['nationality'] ?? 'Global',
    );
  }
}

class PostFlight {
  final String number;
  final String route;

  PostFlight({required this.number, required this.route});

  factory PostFlight.fromJson(Map<String, dynamic> json) {
    return PostFlight(
      number: json['number'] ?? '',
      route: json['route'] ?? '',
    );
  }
}

class PostContent {
  final String title;
  final String content;
  final String? fullContent;
  final String timestamp;
  final int likes;
  final int comments;
  final bool isLiked;
  final int rating;

  PostContent({
    required this.title,
    required this.content,
    this.fullContent,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.isLiked,
    required this.rating,
  });

  factory PostContent.fromJson(Map<String, dynamic> json) {
    return PostContent(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      fullContent: json['full_content'] ?? json['fullContent'],
      timestamp: json['timestamp'] ?? '',
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      rating: json['rating'] ?? 5,
    );
  }
}

class BottomNavItem {
  final String id;
  final String label;
  final String icon;
  final bool active;
  final VoidCallback action;

  BottomNavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.active,
    required this.action,
  });
}

// features/home/model/home_model.dart
// Add this class to your existing home_model.dart
class Notification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime timestamp;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.timestamp,
  });
}
