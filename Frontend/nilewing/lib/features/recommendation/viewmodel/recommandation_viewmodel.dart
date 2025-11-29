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

  Future<void> loadRecommendations() async {
    _updateState(state.copyWith(isLoading: true, error: null));

    try {
      // Get personalized recommendations from backend (already converted to Places)
      final places = await _service.getRecommendations();

      _updateState(
        state.copyWith(places: places, nearbyUsers: [], isLoading: false),
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
    // TODO: Implement user connection (could navigate to chat or match screen)
    // For now, just log
    print('Connect with user: $userId');
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
