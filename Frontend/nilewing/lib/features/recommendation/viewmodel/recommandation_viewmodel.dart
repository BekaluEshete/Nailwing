// features/recommendations/viewmodels/recommendations_viewmodel.dart
import 'package:flutter/material.dart';

// Provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/features/recommendation/model/recommendation_model.dart';
import 'package:nilewing/features/recommendation/services/recommendation_service.dart';

class RecommendationsViewModel with ChangeNotifier {
  final RecommendationService _service;

  RecommendationsViewModel({RecommendationService? service})
    : _service = service ?? RecommendationService();

  RecommendationsState _state = RecommendationsState(
    places: [],
    nearbyUsers: [],
    favoriteIds: {},
    searchQuery: '',
    selectedTabIndex: 0,
    isLoading: false,
  );

  RecommendationsState get state => _state;

  Airport? _currentAirport;
  Airport? get currentAirport => _currentAirport;
  
  Map<String, dynamic>? _recommendationData;
  Map<String, dynamic>? get recommendationData => _recommendationData;

  Future<void> loadRecommendations({bool forceRefresh = false}) async {
    // Don't reload if already loaded and not forcing refresh
    if (!forceRefresh && _state.places.isNotEmpty) return;

    _updateState(state.copyWith(isLoading: true, error: null));

    try {
      // Get comprehensive recommendations from backend
      final data = await _service.getRecommendations();
      _recommendationData = data;
      
      // Extract all places and people
      final allPlaces = data['allPlaces'] as List<Place>? ?? [];
      final peopleData = data['people'] as List<dynamic>? ?? [];
      
      // Convert people data to NearbyUser objects
      final nearbyUsers = peopleData.map((json) => _nearbyUserFromJson(json)).toList();
      
      // Update airport info if available
      final airportCode = data['airportCode'] as String? ?? '';
      final airportCity = data['airportCity'] as String? ?? '';
      if (airportCode.isNotEmpty) {
        _currentAirport = Airport(
          code: airportCode,
          name: '$airportCode Airport',
          city: airportCity,
          country: '',
        );
      }

      _updateState(
        state.copyWith(
          places: allPlaces,
          nearbyUsers: nearbyUsers,
          isLoading: false,
        ),
      );
    } catch (e) {
      final errorMsg = e.toString();
      // Connection abort usually means app went to background mid-request — not a real error
      if (errorMsg.contains('Software caused connection abort') ||
          errorMsg.contains('Connection reset') ||
          errorMsg.contains('SocketException')) {
        _updateState(state.copyWith(
          isLoading: false,
          error: 'Connection interrupted. Pull to refresh.',
        ));
      } else {
        _updateState(state.copyWith(
          isLoading: false,
          error: 'Failed to load recommendations. Tap retry.',
        ));
      }
    }
  }
  
  // Helper: Convert API people JSON to NearbyUser
  NearbyUser _nearbyUserFromJson(Map<String, dynamic> json) {
    return NearbyUser(
      id: json['user_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      avatar: json['avatar']?.toString(),
      age: json['age'] is num ? (json['age'] as num).toInt() : int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      nationality: json['nationality']?.toString() ?? '',
      currentLocation: json['matching_airport']?.toString() ?? 
          json['arrival_airport']?.toString() ?? '',
      distanceFromAirport: 'At airport',
      interests: (json['common_interests'] as List<dynamic>? ?? [])
          .map((i) => i.toString())
          .toList(),
      isOnline: false,
      mutualConnections: 0,
      currentActivity: json['description']?.toString() ?? '',
      localRecommendations: [],
    );
  }

  void setSearchQuery(String query) {
    _updateState(state.copyWith(searchQuery: query));
  }

  void setSelectedTab(int index) {
    _updateState(state.copyWith(selectedTabIndex: index));
  }

  void setSelectedPlace(Place? place) {
    _updateState(state.copyWith(selectedPlace: place));
  }

  void toggleFavorite(String placeId) {
    final newFavorites = Set<String>.from(state.favoriteIds);
    if (newFavorites.contains(placeId)) {
      newFavorites.remove(placeId);
    } else {
      newFavorites.add(placeId);
    }
    _updateState(state.copyWith(favoriteIds: newFavorites));
  }

  Future<void> connectWithUser(String userId) async {
    // Navigate to the match screen — the user is already matched
    // (they appear in recommendations only if matched)
    print('Connect with user: $userId');
    // TODO: Navigate to chat with this user when chat contact is available
  }

  Future<void> getDirections(Place place) async {
    // TODO: Implement directions (could use maps URL or navigation)
    // For now, just log
    print('Get directions to: ${place.name}');
  }

  void clearError() {
    _updateState(state.copyWith(error: null));
  }

  void _updateState(RecommendationsState newState) {
    _state = newState;
    notifyListeners();
  }
}

final recommendationsViewModelProvider =
    ChangeNotifierProvider<RecommendationsViewModel>((ref) {
      return RecommendationsViewModel();
    });
