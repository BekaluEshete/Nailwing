// models/home_model.dart
import 'package:flutter/material.dart';

class User {
  final String name;
  final String? profileImage;
  final String nationality;
  final List<String> languages;
  final String currentFlight;
  final String flightStatus;
  final String currentLocation;
  final String nextFlight;

  User({
    required this.name,
    this.profileImage,
    required this.nationality,
    required this.languages,
    required this.currentFlight,
    required this.flightStatus,
    required this.currentLocation,
    required this.nextFlight,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      profileImage: json['profileImage'],
      nationality: json['nationality'] ?? '',
      languages: List<String>.from(json['languages'] ?? []),
      currentFlight: json['currentFlight'] ?? '',
      flightStatus: json['flightStatus'] ?? '',
      currentLocation: json['currentLocation'] ?? '',
      nextFlight: json['nextFlight'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'profileImage': profileImage,
      'nationality': nationality,
      'languages': languages,
      'currentFlight': currentFlight,
      'flightStatus': flightStatus,
      'currentLocation': currentLocation,
      'nextFlight': nextFlight,
    };
  }
}

class FlightPost {
  final int id;
  final String user;
  final String? avatar;
  final String flight;
  final String route;
  final String time;
  final int likes;
  final String title;
  final String preview;

  FlightPost({
    required this.id,
    required this.user,
    this.avatar,
    required this.flight,
    required this.route,
    required this.time,
    required this.likes,
    required this.title,
    required this.preview,
  });

  factory FlightPost.fromJson(Map<String, dynamic> json) {
    return FlightPost(
      id: json['id'] ?? 0,
      user: json['user'] ?? '',
      avatar: json['avatar'],
      flight: json['flight'] ?? '',
      route: json['route'] ?? '',
      time: json['time'] ?? '',
      likes: json['likes'] ?? 0,
      title: json['title'] ?? '',
      preview: json['preview'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'avatar': avatar,
      'flight': flight,
      'route': route,
      'time': time,
      'likes': likes,
      'title': title,
      'preview': preview,
    };
  }
}

class QuickAction {
  final int id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback action;

  QuickAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.action,
  });
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

// New models for services
class Flight {
  final String id;
  final String airline;
  final String flightNumber;
  final FlightLeg departure;
  final FlightLeg arrival;
  final String seat;
  final String seatType;
  final String status;
  final String departureIn;

  Flight({
    required this.id,
    required this.airline,
    required this.flightNumber,
    required this.departure,
    required this.arrival,
    required this.seat,
    required this.seatType,
    required this.status,
    required this.departureIn,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      id: json['id'] ?? '',
      airline: json['airline'] ?? '',
      flightNumber: json['flightNumber'] ?? '',
      departure: FlightLeg.fromJson(json['departure'] ?? {}),
      arrival: FlightLeg.fromJson(json['arrival'] ?? {}),
      seat: json['seat'] ?? '',
      seatType: json['seatType'] ?? '',
      status: json['status'] ?? '',
      departureIn: json['departureIn'] ?? '',
    );
  }
}

class FlightLeg {
  final String airport;
  final String city;
  final String time;
  final String date;
  final String? terminal;
  final String? gate;

  FlightLeg({
    required this.airport,
    required this.city,
    required this.time,
    required this.date,
    this.terminal,
    this.gate,
  });

  factory FlightLeg.fromJson(Map<String, dynamic> json) {
    return FlightLeg(
      airport: json['airport'] ?? '',
      city: json['city'] ?? '',
      time: json['time'] ?? '',
      date: json['date'] ?? '',
      terminal: json['terminal'],
      gate: json['gate'],
    );
  }
}

class FlightRecommendation {
  final int id;
  final String type;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final int matchScore;
  final String reason;

  FlightRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.matchScore,
    required this.reason,
  });

  factory FlightRecommendation.fromJson(Map<String, dynamic> json) {
    return FlightRecommendation(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['imageUrl'],
      matchScore: json['matchScore'] ?? 0,
      reason: json['reason'] ?? '',
    );
  }
}

class UserFlightStats {
  final int totalFlights;
  final int countriesVisited;
  final int storiesPosted;
  final int milesFlown;
  final List<String> favoriteAirlines;

  UserFlightStats({
    required this.totalFlights,
    required this.countriesVisited,
    required this.storiesPosted,
    required this.milesFlown,
    required this.favoriteAirlines,
  });

  factory UserFlightStats.fromJson(Map<String, dynamic> json) {
    return UserFlightStats(
      totalFlights: json['totalFlights'] ?? 0,
      countriesVisited: json['countriesVisited'] ?? 0,
      storiesPosted: json['storiesPosted'] ?? 0,
      milesFlown: json['milesFlown'] ?? 0,
      favoriteAirlines: List<String>.from(json['favoriteAirlines'] ?? []),
    );
  }
}

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

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      isRead: json['isRead'] ?? false,
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
