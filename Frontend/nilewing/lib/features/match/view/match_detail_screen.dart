// features/matches/views/match_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nilewing/features/match/view/user_detail_screen.dart';
import 'package:nilewing/features/match/viewModel/match_view_model.dart';
import 'package:nilewing/features/match/model/match_model.dart';
import 'package:nilewing/features/chat/viewmodel/chat_view_model.dart';
import 'package:nilewing/core/utils/token_storage.dart';

class MatchDetailScreen extends ConsumerWidget {
  final Match match;
  final VoidCallback onNavigateBack;

  const MatchDetailScreen({
    Key? key,
    required this.match,
    required this.onNavigateBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(matchViewModelProvider.notifier);
    final matchState = ref.watch(matchViewModelProvider);
    
    // Get the latest match from state if available, otherwise use the passed match
    final currentMatch = matchState.matches.firstWhere(
      (m) => m.id == match.id,
      orElse: () => match,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: onNavigateBack,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text('Match Details', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header
            _buildUserHeader(context, ref, currentMatch),
            const SizedBox(height: 20),

            // Compatibility section
            _buildCompatibilitySection(currentMatch),
            const SizedBox(height: 20),

            // Description
            _buildDescription(currentMatch),
            const SizedBox(height: 20),

            // Route info
            _buildRouteInfo(currentMatch),
            const SizedBox(height: 20),

            // Suggested activities
            _buildSuggestedActivities(currentMatch),
            const SizedBox(height: 20),

            // Trip purpose
            if (currentMatch.tripPurpose != null) _buildTripPurpose(currentMatch),
            if (currentMatch.tripPurpose != null) const SizedBox(height: 20),

            // Common interests
            _buildCommonInterests(currentMatch),
            const SizedBox(height: 20),

            // Status and action buttons
            _buildActionSection(context, ref, viewModel, currentMatch),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, WidgetRef ref, Match currentMatch) {
    return GestureDetector(
      onTap: () {
        // Navigate to user detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDetailScreen(
              user: currentMatch.user,
              onNavigateBack: () => Navigator.pop(context),
            ),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                currentMatch.user.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentMatch.user.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currentMatch.user.nationality} • ${currentMatch.user.age} years',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[100]!),
                  ),
                  child: Text(
                    currentMatch.compatibilityText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilitySection(Match currentMatch) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF45C7C1)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            '${currentMatch.compatibility}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Match Compatibility',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  currentMatch.matchType.description,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Match currentMatch) {
    return Text(
      currentMatch.description,
      style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
    );
  }

  Widget _buildRouteInfo(Match currentMatch) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentMatch.flightInfo.route,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                currentMatch.overlapTime,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Shared: ${currentMatch.sharedSegments.join(', ')}',
                style: TextStyle(fontSize: 14, color: Colors.blue[800]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedActivities(Match currentMatch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suggested activities:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: currentMatch.suggestedActivities.map((activity) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      activity,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTripPurpose(Match currentMatch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trip Purpose',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          currentMatch.tripPurpose!,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCommonInterests(Match currentMatch) {
    if (currentMatch.commonInterests.isEmpty) {
      return const SizedBox.shrink(); // Don't show if no common interests
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Common Interests:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: currentMatch.commonInterests.map((interest) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Text(
                interest,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionSection(
    BuildContext context,
    WidgetRef ref,
    MatchViewModel viewModel,
    Match currentMatch,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(match.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(match.status).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(currentMatch.status),
            color: _getStatusColor(currentMatch.status),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              match.status,
              style: TextStyle(
                fontSize: 14,
                color: _getStatusColor(match.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Show "Chat" button if connection is matched/accepted
          if (currentMatch.status.toLowerCase() == 'matched' || 
              currentMatch.status.toLowerCase() == 'connected')
            ElevatedButton(
              onPressed: () => _createChatAfterConnection(context, ref, currentMatch),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Chat'),
            )
          // Show Connect button only if status is "Connect"
          else if (currentMatch.status.toLowerCase() == 'connect')
            ElevatedButton(
              onPressed: () => _handleConnect(context, ref, viewModel, currentMatch),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Connect'),
            )
          // Show Accept/Reject buttons if connection request received (NOT sent by current user)
          else if ((currentMatch.status.toLowerCase() == 'connection request' ||
                   currentMatch.status.toLowerCase() == 'connection_requested') &&
                   !currentMatch.isRequestSentByCurrentUser)
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _handleAcceptConnection(context, ref, viewModel, currentMatch),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Accept'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _handleRejectConnection(context, ref, viewModel, currentMatch),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ],
            )
          // Show "Request Sent" status if connection request was sent by current user
          else if (currentMatch.status.toLowerCase() == 'request sent' ||
                   (currentMatch.status.toLowerCase() == 'connection request' ||
                    currentMatch.status.toLowerCase() == 'connection_requested') &&
                   currentMatch.isRequestSentByCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Request Sent',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          // Show rejected message
          else if (currentMatch.status.toLowerCase() == 'rejected')
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Connection canceled. You cannot chat with this person.',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleConnect(
    BuildContext context,
    WidgetRef ref,
    MatchViewModel matchViewModel,
    Match match,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Send connection request (like the match)
      print('💚 [MatchDetail] Sending connection request for match: ${match.id}');
      await matchViewModel.likeMatch(match.id);
      
      // Refresh matches to get updated status
      await matchViewModel.loadMatches();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection request sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ [MatchDetail] Error sending connection request: $e');
      
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAcceptConnection(
    BuildContext context,
    WidgetRef ref,
    MatchViewModel matchViewModel,
    Match match,
  ) async {
    // Show loading indicator
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Accept the connection request
      print('✅ [MatchDetail] Accepting connection request: ${match.id}');
      final updatedMatch = await matchViewModel.acceptConnection(match.id);
      
      print('✅ [MatchDetail] Connection accepted. Status: ${updatedMatch.status}');

      // Close loading dialog BEFORE creating chat
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection accepted! Creating chat...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Small delay to ensure dialog is closed
      await Future.delayed(const Duration(milliseconds: 100));

      // Now create chat since connection is accepted (with updated match from server)
      await _createChatAfterConnection(context, ref, updatedMatch);
    } catch (e) {
      print('❌ [MatchDetail] Error accepting connection: $e');
      
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectConnection(
    BuildContext context,
    WidgetRef ref,
    MatchViewModel matchViewModel,
    Match match,
  ) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject Connection?'),
          content: const Text('Are you sure you want to reject this connection request?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Reject the connection request
      print('❌ [MatchDetail] Rejecting connection request: ${match.id}');
      await matchViewModel.rejectMatch(match.id);
      
      // Refresh matches to get updated status
      await matchViewModel.loadMatches();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection canceled. You cannot chat with this person.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ [MatchDetail] Error rejecting connection: $e');
      
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createChatAfterConnection(
    BuildContext context,
    WidgetRef ref,
    Match match,
  ) async {
    try {
      // Verify connection is accepted before creating chat
      // The backend should return 'matched' status after accepting
      final statusLower = match.status.toLowerCase();
      print('🔍 [MatchDetail] Checking match status: $statusLower');
      
      // Accept 'matched' status - this is what backend returns after accepting connection
      if (statusLower != 'matched') {
        print('⚠️ [MatchDetail] Connection not matched yet, status: $statusLower. Attempting to create chat anyway...');
        // Don't return - try to create chat anyway as the backend might allow it
      }

      // Create personal chat with the matched user
      final tokenStorage = TokenStorage();
      final currentUserData = await tokenStorage.getUserData();
      final currentUserId = currentUserData?['id']?.toString();
      final matchedUserId = match.user.id;
      
      print('💬 [MatchDetail] Current user ID: $currentUserId');
      print('💬 [MatchDetail] Matched user ID: $matchedUserId');
      print('💬 [MatchDetail] Match status: ${match.status}');
      
      // Verify we're not trying to chat with ourselves
      if (currentUserId != null && matchedUserId == currentUserId) {
        print('⚠️ [MatchDetail] Cannot create chat with yourself');
        return;
      }
      
      if (matchedUserId.isEmpty || matchedUserId == '0') {
        print('⚠️ [MatchDetail] Invalid user ID');
        return;
      }
      
      // Check if widget is still mounted before reading ref
      if (!context.mounted) return;
      
      final chatViewModel = ref.read(chatViewModelProvider.notifier);
      
      // Create personal chat with the matched user
      print('💬 [MatchDetail] Creating personal chat with matched user: $matchedUserId');
      final contact = await chatViewModel.createPersonalChat(matchedUserId);    

      // Check if widget is still mounted
      if (!context.mounted) {
        print('⚠️ [MatchDetail] Widget no longer mounted, cannot navigate');
        return;
      }

      if (contact == null) {
        print('⚠️ [MatchDetail] Chat creation returned null');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create chat. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      print('✅ [MatchDetail] Chat created successfully: ${contact.id}');
      
      // Small delay to ensure WebSocket connection is established
      await Future.delayed(const Duration(milliseconds: 300));

      // Navigate to chat detail screen
      if (context.mounted) {
        print('✅ [MatchDetail] Navigating to chat: ${contact.id}');
        Navigator.of(context).pop(); // Close match detail screen first
        await Future.delayed(const Duration(milliseconds: 100));
        if (context.mounted) {
          context.push('/chat/${contact.id}');
        }
      }
    } catch (e) {
      print('❌ [MatchDetail] Error creating chat: $e');
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase().contains('sent') ||
        status.toLowerCase().contains('awaiting')) {
      return Colors.orange;
    } else if (status.toLowerCase().contains('confirmed')) {
      return Colors.green;
    } else if (status.toLowerCase().contains('connect')) {
      return Colors.blue;
    }
    return Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    if (status.toLowerCase().contains('sent') ||
        status.toLowerCase().contains('awaiting')) {
      return Icons.access_time;
    } else if (status.toLowerCase().contains('confirmed')) {
      return Icons.check_circle;
    } else if (status.toLowerCase().contains('connect')) {
      return Icons.person_add;
    }
    return Icons.info;
  }
}
