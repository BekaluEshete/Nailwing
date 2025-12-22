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
  final User? selectedUser;
  final bool isLoadingUserDetail;

  const MatchState({
    this.matches = const [],
    this.searchQuery = '',
    this.filters = const MatchFilters(),
    this.isLoading = false,
    this.error,
    this.selectedMatch,
    this.selectedUser,
    this.isLoadingUserDetail = false,
  });

  MatchState copyWith({
    List<Match>? matches,
    String? searchQuery,
    MatchFilters? filters,
    bool? isLoading,
    String? error,
    Match? selectedMatch,
    User? selectedUser,
    bool? isLoadingUserDetail,
  }) {
    return MatchState(
      matches: matches ?? this.matches,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedMatch: selectedMatch ?? this.selectedMatch,
      selectedUser: selectedUser ?? this.selectedUser,
      isLoadingUserDetail: isLoadingUserDetail ?? this.isLoadingUserDetail,
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
  User? get selectedUser => state.selectedUser;
  bool get isLoadingUserDetail => state.isLoadingUserDetail;
  List<Match> get filteredMatches => state.filteredMatches;

  // Actions
  Future<void> loadMatches({String? flightId}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final matches = await _service.findMatches(flightId: flightId);
      state = state.copyWith(matches: matches, isLoading: false);
    } catch (e) {
      // Extract user-friendly error message
      String errorMessage = 'Failed to load matches';
      final errorString = e.toString();
      
      if (errorString.contains('Cannot connect to server')) {
        errorMessage = 'Cannot connect to server. Please check your internet connection.';
      } else if (errorString.contains('Connection timeout')) {
        errorMessage = 'Connection timeout. Please try again.';
      } else if (errorString.contains('Connection refused')) {
        errorMessage = 'Server is not responding. Please try again later.';
      } else if (errorString.contains('Not authenticated')) {
        errorMessage = 'Please log in to find matches.';
      } else {
        errorMessage = errorString.replaceAll('Exception: ', '');
      }
      
      state = state.copyWith(
        error: errorMessage,
        isLoading: false,
      );
    }
  }

  Future<void> loadUserDetail(String userId) async {
    state = state.copyWith(isLoadingUserDetail: true, error: null);

    try {
      // Find user from existing matches
      final match = state.matches.firstWhere(
        (m) => m.user.id == userId,
        orElse: () => throw Exception('User not found'),
      );
      state = state.copyWith(selectedUser: match.user, isLoadingUserDetail: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load user details: $e',
        isLoadingUserDetail: false,
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

  void clearSelectedUser() {
    state = state.copyWith(selectedUser: null);
  }

  Future<void> likeMatch(String matchId) async {
    try {
      final updatedMatch = await _service.likeMatch(matchId);
      final updatedMatches = state.matches.map((match) {
        if (match.id == matchId) {
          // Use the status from the backend response
          return updatedMatch;
        }
        return match;
      }).toList();

      state = state.copyWith(matches: updatedMatches);
    } catch (e) {
      state = state.copyWith(error: 'Failed to like match: $e');
    }
  }

  Future<void> rejectMatch(String matchId) async {
    try {
      await _service.rejectMatch(matchId);
      // Update match status to rejected instead of removing
      final updatedMatches = state.matches.map((match) {
        if (match.id == matchId) {
          return match.copyWith(status: 'Rejected');
        }
        return match;
      }).toList();
      state = state.copyWith(matches: updatedMatches);
    } catch (e) {
      state = state.copyWith(error: 'Failed to reject match: $e');
    }
  }

  // Accept a connection request
  Future<Match> acceptConnection(String matchId) async {
    try {
      final updatedMatch = await _service.acceptConnection(matchId);
      final updatedMatches = state.matches.map((match) {
        if (match.id == matchId) {
          return updatedMatch;
        }
        return match;
      }).toList();
      state = state.copyWith(matches: updatedMatches);
      // Return the updated match so the caller can use it
      return updatedMatch;
    } catch (e) {
      state = state.copyWith(error: 'Failed to accept connection: $e');
      rethrow; // Re-throw to let caller handle the error
    }
  }

  // Get connection requests
  Future<void> loadConnectionRequests() async {
    try {
      final requests = await _service.getConnectionRequests();
      // You might want to store these separately or merge with matches
      // For now, we'll just update the matches list
      state = state.copyWith(matches: requests);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load connection requests: $e');
    }
  }

  Future<void> viewMatch(String matchId) async {
    try {
      await _service.viewMatch(matchId);
    } catch (e) {
      // Not critical, just log
      print('Error viewing match: $e');
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
