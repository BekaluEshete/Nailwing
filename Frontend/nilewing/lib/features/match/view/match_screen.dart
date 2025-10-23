// features/matches/views/match_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/features/match/viewModel/match_view_model.dart';

import 'match_list_screen.dart';

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
            Expanded(child: _buildContent(state, viewModel)),
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
                'Matches',
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
              decoration: InputDecoration(
                hintText: 'Search by name, interests, nationality...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
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
              child: Text(
                'Clear Filters',
                style: TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(MatchState state, MatchViewModel viewModel) {
    return MatchListScreen(
      matches: state.filteredMatches as dynamic,
      onMatchTap: (match) {
        viewModel.setSelectedMatch(match as dynamic);
        // TODO: Navigate to match detail screen
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (context) => MatchDetailScreen(match: match)
        // ));
      },
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
