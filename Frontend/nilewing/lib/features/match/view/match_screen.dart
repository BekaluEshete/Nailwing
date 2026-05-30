// features/matches/views/match_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/features/match/viewModel/match_view_model.dart';

import 'match_list_screen.dart';
import 'match_detail_screen.dart';
import 'user_detail_screen.dart';
import 'package:nilewing/features/match/model/match_model.dart';
import 'package:go_router/go_router.dart';
import 'package:nilewing/features/chat/view/call_screen.dart';
import 'package:nilewing/features/chat/viewmodel/chat_view_model.dart';
import 'package:nilewing/core/theme/app_colors.dart';

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
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MatchDetailScreen(
          match: match,
          onNavigateBack: () => Navigator.pop(context),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToUserDetail(User user, BuildContext context) {
    ref.read(matchViewModelProvider.notifier).loadUserDetail(user.id);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => UserDetailScreen(
          user: user,
          onNavigateBack: () {
            ref.read(matchViewModelProvider.notifier).clearSelectedUser();
            Navigator.pop(context);
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
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
                onCallTap: (match) => _handleCall(match, false),
                onVideoCallTap: (match) => _handleCall(match, true),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleCall(Match match, bool isVideo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          channelName: match.user.id,
          contactName: match.user.name,
          contactId: match.user.id,
          isVideoCall: isVideo,
        ),
      ),
    ).then((_) {
      ref.read(chatViewModelProvider.notifier).dismissIncomingCall();
    });
  }

  Widget _buildHeader(MatchViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withBlue(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onNavigateBack,
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Travel Matches',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  // Connection requests button
                  Consumer(
                    builder: (context, ref, _) {
                      final matchState = ref.watch(matchViewModelProvider);
                      // Only count requests where the current user is the RECEIVER,
                      // not where they are the sender.
                      final pendingRequests = matchState.matches.where((m) =>
                          m.status.toLowerCase().contains('request') &&
                          !m.isRequestSentByCurrentUser).length;
                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
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
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: viewModel.setSearchQuery,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search matches: airports, interests...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader(MatchState state, MatchViewModel viewModel) {
    final count = state.filteredMatches.length;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: count > 0
                  ? AppColors.primary.withOpacity(0.08)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: count > 0
                    ? AppColors.primary.withOpacity(0.2)
                    : Colors.grey[200]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  count > 0 ? Icons.people_rounded : Icons.search_off_rounded,
                  size: 13,
                  color: count > 0 ? AppColors.primary : Colors.grey[500],
                ),
                const SizedBox(width: 5),
                Text(
                  count > 0
                      ? '$count match${count == 1 ? '' : 'es'} found'
                      : 'No matches',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: count > 0 ? AppColors.primary : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (!state.filters.isDefault)
            GestureDetector(
              onTap: viewModel.resetFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded, size: 12, color: Colors.red[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Clear Filters',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1500),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 2 * 3.14159,
                  child: child,
                );
              },
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Finding matches...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
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
