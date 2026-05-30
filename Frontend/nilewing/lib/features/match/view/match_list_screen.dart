// features/matches/views/match_list_screen.dart
import 'package:flutter/material.dart';
import 'package:nilewing/features/match/model/match_model.dart';

import 'match_card.dart';

class MatchListScreen extends StatelessWidget {
  final List<Match> matches;
  final Function(Match) onMatchTap;
  final Function(User) onUserTap;
  final Function(Match)? onCallTap;
  final Function(Match)? onVideoCallTap;

  const MatchListScreen({
    Key? key,
    required this.matches,
    required this.onMatchTap,
    required this.onUserTap,
    this.onCallTap,
    this.onVideoCallTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: MatchCard(
            match: match,
            onTap: () => onMatchTap(match),
            onUserTap: () => onUserTap(match.user),
            onCallTap: onCallTap != null ? () => onCallTap!(match) : null,
            onVideoCallTap: onVideoCallTap != null ? () => onVideoCallTap!(match) : null,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (_, v, __) => Transform.scale(
                scale: v,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0891B2).withOpacity(0.15),
                        const Color(0xFF06B6D4).withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0891B2).withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.flight_takeoff_rounded,
                    size: 44,
                    color: Color(0xFF0891B2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No matches yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add an upcoming flight to start\nfinding travel companions',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0891B2).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0891B2).withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: const Color(0xFF0891B2)),
                  const SizedBox(width: 6),
                  Text(
                    'Matches are based on flight overlap',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF0891B2),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
