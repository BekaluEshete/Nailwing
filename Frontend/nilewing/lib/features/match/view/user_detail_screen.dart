// features/matches/views/user_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:nilewing/features/match/model/match_model.dart';
import 'package:nilewing/features/match/service/match_service.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;
  final VoidCallback onNavigateBack;

  const UserDetailScreen({
    Key? key,
    required this.user,
    required this.onNavigateBack,
  }) : super(key: key);

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  User? _fetchedUser;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('👤 [UserDetailScreen] Loading profile for user: ${widget.user.id}');
      final fetchedUser = await MatchService().getUserProfileById(widget.user.id);
      setState(() {
        _fetchedUser = fetchedUser;
        _isLoading = false;
      });
      print('✅ [UserDetailScreen] Profile loaded successfully');
    } catch (e) {
      print('❌ [UserDetailScreen] Error loading profile: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Fallback to passed user data if fetch fails
        _fetchedUser = widget.user;
      });
    }
  }

  User get _displayUser => _fetchedUser ?? widget.user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onNavigateBack,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Traveler Profile',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _fetchedUser == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading profile: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with user info
                      _buildUserHeader(),
                      const SizedBox(height: 24),

                      // Online status and location
                      _buildLocationSection(),
                      const SizedBox(height: 24),

                      // Mutual connections
                      if (_displayUser.mutualConnections > 0) ...[
                        _buildMutualConnections(),
                        const SizedBox(height: 24),
                      ],

                      // Bio
                      _buildBioSection(),
                      const SizedBox(height: 24),

                      // Interests
                      if (_displayUser.interests.isNotEmpty) ...[
                        _buildInterestsSection(),
                        const SizedBox(height: 24),
                      ],

                      // Travel statistics
                      _buildTravelStats(),
                      const SizedBox(height: 24),

                      // Favorite destination
                      if (_displayUser.favoriteDestination != null) ...[
                        _buildFavoriteDestination(),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(40),
          ),
          child: _displayUser.avatar != null && _displayUser.avatar!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    _displayUser.avatar!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          _displayUser.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      );
                    },
                  ),
                )
              : Center(
                  child: Text(
                    _displayUser.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
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
                _displayUser.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _displayUser.isOnline ? Colors.green[50] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _displayUser.isOnline
                        ? Colors.green[100]!
                        : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  _displayUser.lastSeenText,
                  style: TextStyle(
                    fontSize: 12,
                    color: _displayUser.isOnline ? Colors.green[700] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_displayUser.nationality.isNotEmpty || _displayUser.age > 0)
                Text(
                  _displayUser.nationality.isNotEmpty && _displayUser.age > 0
                      ? '${_displayUser.nationality} • ${_displayUser.age} years old'
                      : _displayUser.nationality.isNotEmpty
                          ? _displayUser.nationality
                          : _displayUser.age > 0
                              ? '${_displayUser.age} years old'
                              : '',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              if (_displayUser.languages.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _displayUser.languages.join(', '),
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Location',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_displayUser.currentLocation != null && _displayUser.currentLocation!.isNotEmpty) ...[
            Text(
              _displayUser.currentLocation!,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 4),
          ] else ...[
            Text(
              'Location not available',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
          if (_displayUser.locationAccuracy != null)
            Text(
              _displayUser.locationAccuracy!.displayText,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildMutualConnections() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.people, color: Colors.blue[600], size: 20),
          const SizedBox(width: 12),
          Text(
            'You have ${_displayUser.mutualConnections} mutual connections',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _displayUser.bio ?? 'No bio available',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interests',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _displayUser.interests.map((interest) {
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

  Widget _buildTravelStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Travel Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '${_displayUser.travelStats.countriesVisited}',
                'Countries Visited',
              ),
              _buildStatItem(
                '${_displayUser.travelStats.totalFlights}',
                'Total Flights',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '${_displayUser.travelStats.flightsThisYear}',
                'This Year',
              ),
              _buildStatItem(
                _displayUser.travelStats.frequentFlyerTier,
                'Frequent Flyer',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFavoriteDestination() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite, color: Colors.orange[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Favorite Destination',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _displayUser.favoriteDestination!,
                  style: TextStyle(fontSize: 14, color: Colors.orange[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
