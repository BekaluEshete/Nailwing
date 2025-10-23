// features/matches/views/match_list_screen.dart
import 'package:flutter/material.dart';
import 'package:nilewing/features/match/view/match_card.dart';
import 'package:nilewing/features/match/model/match_model.dart';

class MatchListScreen extends StatelessWidget {
  final List<Match> matches;
  final Function(Match) onMatchTap;

  const MatchListScreen({
    Key? key,
    required this.matches,
    required this.onMatchTap,
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
        return MatchCard(match: match, onTap: () => onMatchTap(match));
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No matches found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
