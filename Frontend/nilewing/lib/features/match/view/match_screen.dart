// features/matches/views/match_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/features/match/viewModel/match_view_model.dart';

import 'match_list_screen.dart';
import 'match_detail_screen.dart';
import 'user_detail_screen.dart';
import 'package:nilewing/features/match/model/match_model.dart';
import 'package:go_router/go_router.dart';

class MatchScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateBack;

  const MatchScreen({Key? key, required this.onNavigateBack}) : super(key: key);

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  void _loadMatches() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchViewModelProvider.notifier).loadMatches();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToMatchDetail(Match match, BuildContext context) {
    ref.read(matchViewModelProvider.notifier).setSelectedMatch(match);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchDetailScreen(
          match: match,
          onNavigateBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _navigateToUserDetail(User user, BuildContext context) {
    ref.read(matchViewModelProvider.notifier).loadUserDetail(user.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailScreen(
          user: user,
          onNavigateBack: () {
            ref.read(matchViewModelProvider.notifier).clearSelectedUser();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchViewModelProvider);
    final viewModel = ref.read(matchViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(viewModel),
          if (state.isLoading) _buildLoading(),
          if (state.error != null) _buildError(context, state.error!, viewModel),
          if (!state.isLoading && state.error == null) ...[
            _buildResultsHeader(state, viewModel),
            Expanded(
              child: MatchListScreen(
                matches: state.filteredMatches,
                onMatchTap: (match) => _navigateToMatchDetail(match, context),
                onUserTap: (user) => _navigateToUserDetail(user, context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(MatchViewModel viewModel) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onNavigateBack,
                icon: const Icon(Icons.arrow_back, color: Colors.black),
              ),
              const SizedBox(width: 8),
              const Text(
                'Travel Matches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              // Connection requests button
              Consumer(
                builder: (context, ref, _) {
                  final matchState = ref.watch(matchViewModelProvider);
                  final pendingRequests = matchState.matches.where((m) =>
                      m.status.toLowerCase() == 'connection request').length;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_add, color: Colors.black),
                        onPressed: () {
                          context.push('/connection-requests');
                        },
                        tooltip: 'Connection Requests',
                      ),
                      if (pendingRequests > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              pendingRequests > 9 ? '9+' : '$pendingRequests',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                onPressed: () {
                  // TODO: Open filters
                },
                icon: const Icon(Icons.filter_list, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: viewModel.setSearchQuery,
              decoration: const InputDecoration(
                hintText: 'Search matches: airports, interests...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(MatchState state, MatchViewModel viewModel) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            '${state.filteredMatches.length} matches found',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const Spacer(),
          if (!state.filters.isDefault)
            TextButton(
              onPressed: viewModel.resetFilters,
              child: const Text(
                'Clear Filters',
                style: TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Expanded(child: Center(child: CircularProgressIndicator()));
  }

  Widget _buildError(BuildContext context, String error, MatchViewModel viewModel) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to Load Matches',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => viewModel.loadMatches(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (error.contains('Cannot connect') || error.contains('Connection'))
                TextButton(
                  onPressed: () {
                    // Show help dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Connection Help'),
                        content: const Text(
                          'If you\'re testing locally, make sure:\n\n'
                          '1. Your backend server is running\n'
                          '2. You\'re using the correct URL in app_constants.dart\n'
                          '3. Your device/emulator can reach the server\n\n'
                          'For Android Emulator, use: http://10.0.2.2:8000\n'
                          'For physical device, use your computer\'s IP address.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Need Help?'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
