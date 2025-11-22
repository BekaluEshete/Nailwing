// features/home/viewmodels/home_view_model.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/core/utils/token_storage.dart';
import '../model/home_model.dart';
import '../services/flight_service.dart';
import '../services/user_service.dart';

final homeViewModelProvider = ChangeNotifierProvider<HomeViewModel>(
  (ref) => HomeViewModel(),
);

class HomeViewModel with ChangeNotifier {
  final FlightService _flightService = FlightService();
  final UserService _userService = UserService();

  String _activeTab = 'home';
  int _notificationCount = 0;
  bool _isLoading = false;
  bool _isOnline = true;
  double _batteryLevel = 78.0;
  final Set<String> _expandedPosts = {};
  List<FlightPost> _flightPosts = [];
  Flight? _userFlight;
  User? _user;
  Map<String, dynamic>? _preFlightMatches;
  DateTime _currentTime = DateTime.now();

  String get activeTab => _activeTab;
  int get notificationCount => _notificationCount;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  double get batteryLevel => _batteryLevel;
  Set<String> get expandedPosts => _expandedPosts;
  List<FlightPost> get flightPosts => _flightPosts;
  Flight? get userFlight => _userFlight;
  User? get user => _user;
  Map<String, dynamic>? get preFlightMatches => _preFlightMatches;
  DateTime get currentTime => _currentTime;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Timer? _timer;

  Future<void> initializeData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load all data in parallel
      await Future.wait([
        _loadUserProfile(),
        _loadUserFlight(),
        _loadFlightPosts(),
        _loadPreFlightMatches(),
        _loadNotificationCount(),
      ]);
    } catch (e) {
      print('Error initializing home data: $e');
      // You could set default/fallback data here
    } finally {
      _isLoading = false;
      notifyListeners();
      _startRealTimeUpdates();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      _user = await _userService.getUserProfile("current_user_id");
      notifyListeners(); // Notify listeners when user profile is loaded
    } catch (e) {
      print('Error loading user profile: $e');
      // Try to get user data from storage as fallback
      try {
        final tokenStorage = TokenStorage();
        final userData = await tokenStorage.getUserData();
        if (userData != null) {
          _user = User(
            name: userData['fullName'] ?? 'User',
            profileImage: userData['profileImageUrl'] ?? userData['profileImage'],
            email: userData['email'] ?? '',
            nationality: userData['nationality'] ?? '',
          );
        } else {
          // Last resort fallback
          _user = User(
            name: "User",
            profileImage: null,
            email: "",
            nationality: "",
          );
        }
      } catch (fallbackError) {
        print('Error in fallback: $fallbackError');
        _user = User(
          name: "User",
          profileImage: null,
          email: "",
          nationality: "",
        );
      }
      notifyListeners();
    }
  }

  Future<void> _loadUserFlight() async {
    try {
      _userFlight = await _flightService.getUserUpcomingFlight(
        "current_user_id",
      );
    } catch (e) {
      print('Error loading user flight: $e');
      // Fallback flight data
      _userFlight = Flight(
        flightNumber: "ET302",
        airline: "Ethiopian Airlines",
        route: "ADD → CDG",
        departure: FlightLeg(
          airport: "ADD",
          city: "Addis Ababa",
          time: "23:35",
          date: "Today",
          terminal: "T2",
        ),
        arrival: FlightLeg(
          airport: "CDG",
          city: "Paris",
          time: "06:50+1",
          date: "Tomorrow",
          terminal: "2E",
        ),
        duration: "7h 15m",
        aircraft: "Boeing 787-9",
        seat: "12A",
        gate: "B7",
        status: "On Time",
        checkInTime: "21:35",
        boardingTime: "23:00",
        timeUntilDeparture: "5h 23m",
      );
    }
  }

  Future<void> _loadFlightPosts() async {
    try {
      _flightPosts = await _flightService.getFlightPosts();
    } catch (e) {
      print('Error loading flight posts: $e');
      _flightPosts = []; // Empty fallback
    }
  }

  Future<void> _loadPreFlightMatches() async {
    try {
      _preFlightMatches = await _flightService.getPreFlightMatches(
        "current_user_id",
      );
    } catch (e) {
      print('Error loading pre-flight matches: $e');
      _preFlightMatches = {
        'matchCount': 0,
        'matches': [],
        'commonRoute': 'No matches found',
      };
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      _notificationCount = await _userService.getNotificationCount(
        "current_user_id",
      );
    } catch (e) {
      print('Error loading notification count: $e');
      _notificationCount = 3; // Fallback count
    }
  }

  void _startRealTimeUpdates() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _currentTime = DateTime.now();

      // Simulate real-time updates
      if (DateTime.now().second % 10 == 0) {
        _notificationCount++;
        notifyListeners();
      }

      // Update battery level
      _batteryLevel = (_batteryLevel - 0.02).clamp(0.0, 100.0);
      notifyListeners();
    });
  }

  // // Rest of your existing methods remain the same...
  // List<BottomNavItem> get bottomNavItems => [
  //   BottomNavItem(
  //     id: 'myflights',
  //     label: 'My Flights',
  //     icon: '✈️',
  //     active: _activeTab == 'myflights',
  //     action: () {
  //       setActiveTab('myflights');
  //       _onNavigateToMyFlights?.call();
  //     },
  //   ),
  //   BottomNavItem(
  //     id: 'match',
  //     label: 'Match',
  //     icon: '⚡',
  //     active: _activeTab == 'match',
  //     action: () {
  //       setActiveTab('match');
  //       _onNavigateToMatch?.call();
  //     },
  //   ),
  //   BottomNavItem(
  //     id: 'chat',
  //     label: 'Chat',
  //     icon: '💬',
  //     active: _activeTab == 'chat',
  //     action: () {
  //       setActiveTab('chat');
  //       _onNavigateToChat?.call();
  //     },
  //   ),
  //   BottomNavItem(
  //     id: 'recommendations',
  //     label: 'Recommendations',
  //     icon: '🎯',
  //     active: _activeTab == 'recommendations',
  //     action: () {
  //       setActiveTab('recommendations');
  //       _onNavigateToRecommendations?.call();
  //     },
  //   ),
  //   BottomNavItem(
  //     id: 'home',
  //     label: 'Home',
  //     icon: '🏠',
  //     active: _activeTab == 'home',
  //     action: () => setActiveTab('home'),
  //   ),
  // ];

  void toggleLike(String postId) {
    final index = _flightPosts.indexWhere((post) => post.id == postId);
    if (index != -1) {
      final post = _flightPosts[index];
      final newLikes = post.post.isLiked
          ? post.post.likes - 1
          : post.post.likes + 1;

      _flightPosts[index] = FlightPost(
        id: post.id,
        user: post.user,
        flight: post.flight,
        post: PostContent(
          title: post.post.title,
          content: post.post.content,
          fullContent: post.post.fullContent,
          timestamp: post.post.timestamp,
          likes: newLikes,
          comments: post.post.comments,
          isLiked: !post.post.isLiked,
          rating: post.post.rating,
        ),
      );
      notifyListeners();
    }
  }

  void toggleReadMore(String postId) {
    if (_expandedPosts.contains(postId)) {
      _expandedPosts.remove(postId);
    } else {
      _expandedPosts.add(postId);
    }
    notifyListeners();
  }

  // Service-based actions
  Future<void> checkIn() async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _flightService.checkInForFlight(
        _userFlight?.flightNumber ?? 'ET302',
        "current_user_id",
      );

      if (success) {
        // Handle successful check-in
        print('Check-in successful!');
      }
    } catch (e) {
      print('Check-in failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> viewFlightDetails() async {
    try {
      final details = await _flightService.getFlightDetails(
        _userFlight?.flightNumber ?? 'ET302',
      );
      print('Flight details: $details');
      // Navigate to details screen or show dialog
    } catch (e) {
      print('Error loading flight details: $e');
    }
  }

  // Navigation callbacks
  VoidCallback? _onNavigateToNotifications;

  VoidCallback? _onNavigateToMatch;
  VoidCallback? _onNavigateToPreFlightMatching;
  VoidCallback? _onNavigateToChat;
  VoidCallback? _onNavigateToRecommendations;
  VoidCallback? _onNavigateToProfile;
  VoidCallback? _onNavigateToSettings;

  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners();
  }

  void setNotificationCount(int count) {
    _notificationCount = count;
    notifyListeners();
  }
}
