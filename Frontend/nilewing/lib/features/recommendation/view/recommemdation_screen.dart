// features/recommendations/views/recommendations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/core/theme/app_colors.dart';
import 'package:nilewing/features/recommendation/view/widgets/place_card.dart';
import 'package:nilewing/features/recommendation/view/widgets/user_card.dart';
import 'package:nilewing/features/recommendation/viewmodel/recommandation_viewmodel.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateBack;

  const RecommendationsScreen({Key? key, required this.onNavigateBack})
    : super(key: key);

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recommendationsViewModelProvider).loadRecommendations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(recommendationsViewModelProvider);
    final state = viewModel.state;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(viewModel),
          _buildTabBar(viewModel),
          if (state.isLoading) _buildLoading(),
          if (state.error != null) _buildError(state.error!, viewModel),
          if (!state.isLoading && state.error == null) _buildContent(viewModel),
        ],
      ),
    );
  }

  Widget _buildHeader(RecommendationsViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: widget.onNavigateBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          viewModel.currentAirport != null
                              ? 'Recommendations for ${viewModel.currentAirport!.code}'
                              : 'Recommendations',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (viewModel.currentAirport != null)
                          Text(
                            '${viewModel.currentAirport!.city} • ${viewModel.currentAirport!.code} Airport',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        if (viewModel.recommendationData?['flight_info'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Arriving: ${_formatFlightDate(viewModel.recommendationData!['flight_info'])}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white60, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 19, 18, 18),
                      ),
                      onChanged: (value) {
                        setState(() {});
                        viewModel.setSearchQuery(value);
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search recommendations...',
                        hintStyle: TextStyle(
                          color: Color.fromARGB(153, 12, 12, 12),
                        ),
                        border: InputBorder.none,
                      ),
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

  Widget _buildTabBar(RecommendationsViewModel viewModel) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          viewModel.setSelectedTab(index);
          setState(() {}); // Update UI when tab changes
        },
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.blue,
        tabs: const [
          Tab(icon: Icon(Icons.hotel, size: 16), text: 'Hotels'),
          Tab(icon: Icon(Icons.coffee, size: 16), text: 'Cafés'),
          Tab(icon: Icon(Icons.restaurant, size: 16), text: 'Dining'),
          Tab(icon: Icon(Icons.people, size: 16), text: 'People'),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Expanded(child: Center(child: CircularProgressIndicator()));
  }

  Widget _buildError(String error, RecommendationsViewModel viewModel) {
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
              onPressed: viewModel.loadRecommendations,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(RecommendationsViewModel viewModel) {
    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildPlacesList(viewModel),
          _buildPlacesList(viewModel),
          _buildPlacesList(viewModel),
          _buildUsersList(viewModel),
        ],
      ),
    );
  }

  Widget _buildPlacesList(RecommendationsViewModel viewModel) {
    final places = viewModel.state.filteredPlaces;

    if (places.isEmpty) {
      return const Center(child: Text('No places found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return PlaceCard(
          place: place,
          isFavorite: viewModel.state.favoriteIds.contains(place.id),
          onTap: () => viewModel.setSelectedPlace(place),
          onFavoriteTap: () => viewModel.toggleFavorite(place.id),
        );
      },
    );
  }

  Widget _buildUsersList(RecommendationsViewModel viewModel) {
    final users = viewModel.state.nearbyUsers;

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No people found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'No matched people at your destination airport yet',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return UserCard(
          user: user,
          onConnect: () => viewModel.connectWithUser(user.id),
        );
      },
    );
  }
  
  String _formatFlightDate(Map<String, dynamic> flightInfo) {
    try {
      final arrivalDateTime = flightInfo['arrival_datetime']?.toString();
      if (arrivalDateTime != null && arrivalDateTime.isNotEmpty) {
        final dateTime = DateTime.parse(arrivalDateTime);
        final now = DateTime.now();
        final difference = dateTime.difference(now);
        
        if (difference.inDays > 0) {
          return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'}, ${dateTime.day}/${dateTime.month}';
        } else if (difference.inHours > 0) {
          return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
        } else {
          return 'Today';
        }
      }
    } catch (e) {
      print('Error formatting flight date: $e');
    }
    return 'Upcoming';
  }
}
