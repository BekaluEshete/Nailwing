// features/matches/viewmodels/match_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/features/match/model/match_model.dart';
import 'package:nilewing/features/match/service/match_service.dart';

// State
class MatchState {
  final List<Match> matches;
  final String searchQuery;
  final MatchFilters filters;
  final bool isLoading;
  final String? error;
  final Match? selectedMatch;

  const MatchState({
    this.matches = const [],
    this.searchQuery = '',
    this.filters = const MatchFilters(),
    this.isLoading = false,
    this.error,
    this.selectedMatch,
  });

  MatchState copyWith({
    List<Match>? matches,
    String? searchQuery,
    MatchFilters? filters,
    bool? isLoading,
    String? error,
    Match? selectedMatch,
  }) {
    return MatchState(
      matches: matches ?? this.matches,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedMatch: selectedMatch ?? this.selectedMatch,
    );
  }

  List<Match> get filteredMatches {
    if (searchQuery.isEmpty && filters.isDefault) {
      return matches;
    }

    return matches.where((match) {
      final matchesSearch =
          searchQuery.isEmpty ||
          match.user.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          match.user.nationality.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          match.flightInfo.airline.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          match.user.interests.any(
            (interest) =>
                interest.toLowerCase().contains(searchQuery.toLowerCase()),
          );

      if (!matchesSearch) return false;

      // Gender filter
      if (filters.gender != 'all' && match.user.gender != filters.gender) {
        return false;
      }

      // Age filter
      if (filters.ageRange != 'all') {
        final age = match.user.age;
        switch (filters.ageRange) {
          case '18-25':
            if (age < 18 || age > 25) return false;
            break;
          case '26-35':
            if (age < 26 || age > 35) return false;
            break;
          case '36-45':
            if (age < 36 || age > 45) return false;
            break;
          case '46+':
            if (age < 46) return false;
            break;
        }
      }

      // Nationality filter
      if (filters.nationality != 'all' &&
          match.user.nationality != filters.nationality) {
        return false;
      }

      // Language filter
      if (filters.language != 'all' &&
          !match.user.languages.contains(filters.language)) {
        return false;
      }

      // Interests filter
      if (filters.interests.isNotEmpty &&
          !filters.interests.any(
            (interest) => match.user.interests.contains(interest),
          )) {
        return false;
      }

      // Compatibility filter
      if (match.compatibility < filters.minCompatibility) {
        return false;
      }

      // Match type filter
      if (filters.matchTypes.isNotEmpty &&
          !filters.matchTypes.contains(match.matchType)) {
        return false;
      }

      return true;
    }).toList();
  }
}

// ViewModel
class MatchViewModel extends StateNotifier<MatchState> {
  final MatchService _service;

  MatchViewModel(this._service) : super(const MatchState());

  // Getters
  List<Match> get matches => state.matches;
  String get searchQuery => state.searchQuery;
  MatchFilters get filters => state.filters;
  bool get isLoading => state.isLoading;
  String? get error => state.error;
  Match? get selectedMatch => state.selectedMatch;
  List<Match> get filteredMatches => state.filteredMatches;

  // Actions
  Future<void> loadMatches() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final matches = await _service.getMatches();
      state = state.copyWith(matches: matches, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load matches: $e',
        isLoading: false,
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilters(MatchFilters filters) {
    state = state.copyWith(filters: filters);
  }

  void setSelectedMatch(Match? match) {
    state = state.copyWith(selectedMatch: match);
  }

  Future<void> sendMatchRequest(String matchId) async {
    try {
      await _service.sendMatchRequest(matchId);
      // Update match status locally if needed
      final updatedMatches = state.matches.map((match) {
        if (match.id == matchId) {
          return match.copyWith(status: 'Request sent');
        }
        return match;
      }).toList();

      state = state.copyWith(matches: updatedMatches);
    } catch (e) {
      state = state.copyWith(error: 'Failed to send match request: $e');
    }
  }

  Future<void> acceptMatch(String matchId) async {
    try {
      await _service.acceptMatch(matchId);
      // Update match status locally
      final updatedMatches = state.matches.map((match) {
        if (match.id == matchId) {
          return match.copyWith(status: 'Accepted');
        }
        return match;
      }).toList();

      state = state.copyWith(matches: updatedMatches);
    } catch (e) {
      state = state.copyWith(error: 'Failed to accept match: $e');
    }
  }

  Future<void> declineMatch(String matchId) async {
    try {
      await _service.declineMatch(matchId);
      // Remove match from list
      final updatedMatches = state.matches
          .where((match) => match.id != matchId)
          .toList();
      state = state.copyWith(matches: updatedMatches);
    } catch (e) {
      state = state.copyWith(error: 'Failed to decline match: $e');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void resetFilters() {
    state = state.copyWith(filters: const MatchFilters());
  }
}

// Providers
final matchServiceProvider = Provider<MatchService>((ref) {
  return MatchService();
});

final matchViewModelProvider =
    StateNotifierProvider<MatchViewModel, MatchState>((ref) {
      final matchService = ref.watch(matchServiceProvider);
      return MatchViewModel(matchService);
    });
