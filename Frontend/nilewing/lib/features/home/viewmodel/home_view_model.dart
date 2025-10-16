// viewmodels/home_view_model.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/features/home/model/home_model.dart';

import '../services/flight_service.dart';
import '../services/user_service.dart';

final homeViewModelProvider = ChangeNotifierProvider<HomeViewModel>(
  (ref) => HomeViewModel(),
);

class HomeViewModel with ChangeNotifier {
  final FlightService _flightService = FlightService();
  final UserService _userService = UserService();

  String _activeTab = 'home';
  int _notificationCount = 5;
  bool _isLoading = false;
  User? _user;
  List<FlightPost> _recentPosts = [];
  List<Flight> _upcomingFlights = [];
  UserFlightStats? _userStats;

  String get activeTab => _activeTab;
  int get notificationCount => _notificationCount;
  bool get isLoading => _isLoading;
  User get user => _user ?? _userService.getMockUser();
  List<FlightPost> get recentPosts => _recentPosts;
  List<Flight> get upcomingFlights => _upcomingFlights;
  UserFlightStats? get userStats => _userStats;

  // Initialize data
  Future<void> initializeData(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load data in parallel
      await Future.wait([
        _loadUserProfile(userId),
        _loadRecentPosts(),
        _loadUpcomingFlights(userId),
        _loadUserStats(userId),
      ]);
    } catch (e) {
      print('Error initializing home data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      _user = await _userService.getUserProfile(userId);
    } catch (e) {
      print('Error loading user profile: $e');
      _user = _userService.getMockUser();
    }
  }

  Future<void> _loadRecentPosts() async {
    try {
      _recentPosts = await _flightService.getFlightPosts();
    } catch (e) {
      print('Error loading recent posts: $e');
      _recentPosts = _flightService.getMockFlightPosts();
    }
  }

  Future<void> _loadUpcomingFlights(String userId) async {
    try {
      _upcomingFlights = await _flightService.getUpcomingFlights(userId);
    } catch (e) {
      print('Error loading upcoming flights: $e');
      _upcomingFlights = _flightService.getMockUpcomingFlights();
    }
  }

  Future<void> _loadUserStats(String userId) async {
    try {
      _userStats = await _flightService.getUserFlightStats(userId);
    } catch (e) {
      print('Error loading user stats: $e');
      _userStats = _flightService.getMockUserStats();
    }
  }

  // Refresh data
  Future<void> refreshData(String userId) async {
    await initializeData(userId);
  }

  // Add a new flight
  Future<void> addFlight(Map<String, dynamic> flightData) async {
    try {
      // In a real app, you would get userId from authentication
      final userId = "current_user_id";
      await _flightService.addFlight(userId, flightData);

      // Refresh upcoming flights
      await _loadUpcomingFlights(userId);
    } catch (e) {
      throw Exception('Failed to add flight: $e');
    }
  }

  // Get notifications count
  Future<void> loadNotificationCount(String userId) async {
    try {
      final notifications = await _userService.getUserNotifications(userId);
      _notificationCount = notifications.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  List<QuickAction> get quickActions => [
    QuickAction(
      id: 1,
      title: "Add Flight",
      subtitle: "New journey",
      icon: Icons.add,
      gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
      action: () => print("Add flight"),
    ),
    QuickAction(
      id: 2,
      title: "Flight Status",
      subtitle: "Track live",
      icon: Icons.navigation,
      gradientColors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
      action: () => print("Flight status"),
    ),
    QuickAction(
      id: 3,
      title: "View Flights",
      subtitle: "Browse all",
      icon: Icons.flight,
      gradientColors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      action: () => _onNavigateToFlightList?.call(),
    ),
    QuickAction(
      id: 4,
      title: "Flight Posts",
      subtitle: "Community",
      icon: Icons.remove_red_eye,
      gradientColors: [Color(0xFFEC4899), Color(0xFFDB2777)],
      action: () => _onNavigateToViewPosts?.call(),
    ),
  ];

  // Updated bottomNavItems to be dynamic based on activeTab
  List<BottomNavItem> get bottomNavItems => [
    BottomNavItem(
      id: 'myflights',
      label: 'My Flights',
      icon: '✈️',
      active: _activeTab == 'myflights',
      action: () {
        setActiveTab('myflights');
        _onNavigateToMyFlights?.call();
      },
    ),
    BottomNavItem(
      id: 'match',
      label: 'Match',
      icon: '⚡',
      active: _activeTab == 'match',
      action: () {
        setActiveTab('match');
        _onNavigateToMatch?.call();
      },
    ),
    BottomNavItem(
      id: 'chat',
      label: 'Chat',
      icon: '💬',
      active: _activeTab == 'chat',
      action: () {
        setActiveTab('chat');
        _onNavigateToChat?.call();
      },
    ),
    BottomNavItem(
      id: 'recommendations',
      label: 'Recommendations',
      icon: '🌟',
      active: _activeTab == 'recommendations',
      action: () {
        setActiveTab('recommendations');
        _onNavigateToRecommendations?.call();
      },
    ),
    BottomNavItem(
      id: 'home',
      label: 'Home',
      icon: '🏠',
      active: _activeTab == 'home',
      action: () => setActiveTab('home'),
    ),
  ];

  // Navigation callbacks
  VoidCallback? _onNavigateToSettings;
  VoidCallback? _onNavigateToNotifications;
  VoidCallback? _onNavigateToProfile;
  VoidCallback? _onNavigateToMyFlights;
  VoidCallback? _onNavigateToFlightList;
  VoidCallback? _onNavigateToViewPosts;
  VoidCallback? _onNavigateToMatch;
  VoidCallback? _onNavigateToChat;
  VoidCallback? _onNavigateToRecommendations;

  void setNavigationCallbacks({
    VoidCallback? onNavigateToSettings,
    VoidCallback? onNavigateToNotifications,
    VoidCallback? onNavigateToProfile,
    VoidCallback? onNavigateToMyFlights,
    VoidCallback? onNavigateToFlightList,
    VoidCallback? onNavigateToViewPosts,
    VoidCallback? onNavigateToMatch,
    VoidCallback? onNavigateToChat,
    VoidCallback? onNavigateToRecommendations,
  }) {
    _onNavigateToSettings = onNavigateToSettings;
    _onNavigateToNotifications = onNavigateToNotifications;
    _onNavigateToProfile = onNavigateToProfile;
    _onNavigateToMyFlights = onNavigateToMyFlights;
    _onNavigateToFlightList = onNavigateToFlightList;
    _onNavigateToViewPosts = onNavigateToViewPosts;
    _onNavigateToMatch = onNavigateToMatch;
    _onNavigateToChat = onNavigateToChat;
    _onNavigateToRecommendations = onNavigateToRecommendations;
  }

  void setActiveTab(String tab) {
    _activeTab = tab;
    notifyListeners(); // This will rebuild the UI with updated active states
  }

  void setNotificationCount(int count) {
    _notificationCount = count;
    notifyListeners();
  }
}
