// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/features/home/model/home_model.dart';
import 'package:nilewing/features/home/viewmodel/home_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToSettings;
  final VoidCallback? onNavigateToNotifications;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToMyFlights;
  final VoidCallback? onNavigateToFlightList;
  final VoidCallback? onNavigateToViewPosts;
  final VoidCallback? onNavigateToMatch;
  final VoidCallback? onNavigateToChat;
  final VoidCallback? onNavigateToRecommendations;

  const HomeScreen({
    Key? key,
    this.onNavigateToSettings,
    this.onNavigateToNotifications,
    this.onNavigateToProfile,
    this.onNavigateToMyFlights,
    this.onNavigateToFlightList,
    this.onNavigateToViewPosts,
    this.onNavigateToMatch,
    this.onNavigateToChat,
    this.onNavigateToRecommendations,
  }) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = ref.read(homeViewModelProvider);
      viewModel.setNavigationCallbacks(
        onNavigateToSettings: widget.onNavigateToSettings,
        onNavigateToNotifications: widget.onNavigateToNotifications,
        onNavigateToProfile: widget.onNavigateToProfile,
        onNavigateToMyFlights: widget.onNavigateToMyFlights,
        onNavigateToFlightList: widget.onNavigateToFlightList,
        onNavigateToViewPosts: widget.onNavigateToViewPosts,
        onNavigateToMatch: widget.onNavigateToMatch,
        onNavigateToChat: widget.onNavigateToChat,
        onNavigateToRecommendations: widget.onNavigateToRecommendations,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(homeViewModelProvider);
    final user = viewModel.user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top App Bar
          _buildTopAppBar(viewModel, user),

          // Current Location Banner
          _buildLocationBanner(user),

          // Main Content
          Expanded(child: _buildContent(viewModel)),

          // Bottom Navigation
          _buildBottomNavigation(viewModel),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(HomeViewModel viewModel, User user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF06B6D4)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Logo and Icons Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Logo
                  Row(
                    children: [
                      Icon(Icons.flight, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'NILE WING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),

                  Spacer(),

                  // Notifications and Settings
                  Row(
                    children: [
                      Stack(
                        children: [
                          IconButton(
                            onPressed: widget.onNavigateToNotifications,
                            icon: Icon(
                              Icons.notifications,
                              color: Colors.white,
                            ),
                          ),
                          if (viewModel.notificationCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  viewModel.notificationCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        onPressed: widget.onNavigateToSettings,
                        icon: Icon(Icons.settings, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Profile Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Profile Avatar and Info
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: user.profileImage != null
                              ? CircleAvatar(
                                  radius: 26,
                                  backgroundImage: NetworkImage(
                                    user.profileImage!,
                                  ),
                                )
                              : Text(
                                  user.name.substring(0, 2).toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${user.name} ✈️',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Ready for your journey?',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Transit Status
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              user.flightStatus,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          user.currentFlight,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
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

  Widget _buildLocationBanner(User user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            user.currentLocation,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Text(
            'Next: ${user.nextFlight}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(HomeViewModel viewModel) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Quick Access Grid
          _buildQuickAccess(viewModel),
          SizedBox(height: 24),

          // Recent Flight Stories
          _buildRecentStories(viewModel),
          SizedBox(height: 16),

          // User Stats Card
          _buildUserStatsCard(),
          SizedBox(height: 80), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildQuickAccess(HomeViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF06B6D4)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: viewModel.quickActions.length,
          itemBuilder: (context, index) {
            final action = viewModel.quickActions[index];
            return _buildQuickActionCard(action);
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(QuickAction action) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: action.action,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF8FAFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: action.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: action.gradientColors.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(action.icon, color: Colors.white, size: 24),
              ),
              SizedBox(height: 12),
              Text(
                action.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                action.subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentStories(HomeViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Recent Flight Stories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: widget.onNavigateToViewPosts,
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1E40AF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Column(
          children: viewModel.recentPosts
              .map((post) => _buildStoryCard(post))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildStoryCard(FlightPost post) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF0F9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF1E40AF),
                child: post.avatar != null
                    ? CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(post.avatar!),
                      )
                    : Text(
                        post.user.substring(0, 2).toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.user,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            post.flight,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Spacer(),
                        Text(
                          post.time,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      post.route,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      post.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      post.preview,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Colors.red[400],
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              post.likes.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Read More',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E40AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Flight Journey',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('12', 'Flights'),
                  _buildStatItem('8', 'Countries'),
                  _buildStatItem('24', 'Stories'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  // In your home_screen.dart, update the _buildBottomNavigation method:

  Widget _buildBottomNavigation(HomeViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: viewModel.bottomNavItems
                .map((item) => _buildBottomNavItem(item, viewModel))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(BottomNavItem item, HomeViewModel viewModel) {
    final isActive = item.active; // This now comes from the ViewModel

    return GestureDetector(
      onTap: item.action,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    Color(0xFF1E40AF).withOpacity(0.2),
                    Color(0xFF06B6D4).withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Color(0xFF1E40AF).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.icon,
              style: TextStyle(
                fontSize: 18,
                color: isActive ? Color(0xFF1E40AF) : Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Color(0xFF1E40AF) : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
