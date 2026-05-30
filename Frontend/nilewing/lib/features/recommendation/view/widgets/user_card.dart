// features/recommendations/views/widgets/user_card.dart
import 'package:flutter/material.dart';
import 'package:nilewing/features/recommendation/model/recommendation_model.dart';

class UserCard extends StatelessWidget {
  final NearbyUser user;
  final VoidCallback onConnect;

  const UserCard({Key? key, required this.user, required this.onConnect})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(user),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildUserInfo(user),
                      const SizedBox(height: 4),
                      Text(
                        '📍 ${user.currentLocation}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '🎯 ${user.currentActivity}',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      _buildInterests(user),
                    ],
                  ),
                ),
              ],
            ),
            if (user.localRecommendations.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildRecommendations(user),
            ],
            const SizedBox(height: 12),
            _buildActions(user),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(NearbyUser user) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue,
          child: Text(
            user.name.split(' ').map((n) => n[0]).join(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (user.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserInfo(NearbyUser user) {
    return Row(
      children: [
        Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '${user.nationality} • ${user.age} years',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Text(
          '• ${user.distanceFromAirport}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildInterests(NearbyUser user) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: user.interests.take(3).map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Text(
            interest,
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendations(NearbyUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Local Tips:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: user.localRecommendations.take(2).map((tip) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  Widget _buildActions(NearbyUser user) {
    return Row(
      children: [
        if (user.mutualConnections > 0) ...[
          Icon(Icons.people, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '${user.mutualConnections} mutual',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const Spacer(),
        ] else
          const Spacer(),
        ElevatedButton.icon(
          onPressed: onConnect,
          icon: const Icon(Icons.person_add, size: 16),
          label: const Text('Connect'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
}
