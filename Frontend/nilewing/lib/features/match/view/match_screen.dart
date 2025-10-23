// features/matches/views/match_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/features/match/viewModel/match_view_model.dart';

import 'match_list_screen.dart';
import 'match_detail_screen.dart';
import 'user_detail_screen.dart';
import 'package:nilewing/features/match/model/match_model.dart';

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
          if (state.error != null) _buildError(state.error!, viewModel),
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

  Widget _buildError(String error, MatchViewModel viewModel) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              error,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: viewModel.loadMatches,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
