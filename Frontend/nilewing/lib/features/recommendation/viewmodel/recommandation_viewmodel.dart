// features/recommendations/viewmodels/recommendations_viewmodel.dart
import 'package:flutter/material.dart';

// Provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/features/recommendation/model/recommendation_model.dart';
import 'package:nilewing/features/recommendation/services/recommendation_service.dart';

class RecommendationsViewModel with ChangeNotifier {
  final RecommendationsService _service;

  RecommendationsViewModel({RecommendationsService? service})
    : _service = service ?? RecommendationsService();

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

  Future<void> loadRecommendations() async {
    _updateState(state.copyWith(isLoading: true, error: null));

    try {
      final airport = await _service.getCurrentAirport();
      final places = await _service.getPlacesNearAirport(airport.code);
      final users = await _service.getNearbyUsers(airport.code);

      _currentAirport = airport; // This is now fine since both are Airport?
      _updateState(
        state.copyWith(places: places, nearbyUsers: users, isLoading: false),
      );
    } catch (e) {
      _updateState(
        state.copyWith(
          isLoading: false,
          error: 'Failed to load recommendations: $e',
        ),
      );
    }
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
    try {
      await _service.connectWithUser(userId);
      // You could update the user state here if needed
    } catch (e) {
      _updateState(state.copyWith(error: 'Failed to connect with user: $e'));
    }
  }

  Future<void> getDirections(Place place) async {
    try {
      await _service.getDirections(place);
      // Handle directions opening
    } catch (e) {
      _updateState(state.copyWith(error: 'Failed to get directions: $e'));
    }
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
