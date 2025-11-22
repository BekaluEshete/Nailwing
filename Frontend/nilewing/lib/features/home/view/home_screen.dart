// features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/core/theme/app_colors.dart';
import 'package:nilewing/features/home/model/home_model.dart';
import 'package:nilewing/features/home/viewmodel/home_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToNotifications;
  final VoidCallback? onNavigateToMyFlights;
  final VoidCallback? onNavigateToMatch;
  final VoidCallback? onNavigateToPreFlightMatching;
  final VoidCallback? onNavigateToChat;
  final VoidCallback? onNavigateToRecommendations;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToSettings;

  const HomeScreen({
    Key? key,
    this.onNavigateToNotifications,
    this.onNavigateToMyFlights,
    this.onNavigateToMatch,
    this.onNavigateToPreFlightMatching,
    this.onNavigateToChat,
    this.onNavigateToRecommendations,
    this.onNavigateToProfile,
    this.onNavigateToSettings,
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

      viewModel.initializeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(homeViewModelProvider);

    // Show loading state while initial data is being fetched
    if (viewModel.isLoading &&
        (viewModel.user == null || viewModel.userFlight == null)) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E40AF)),
              ),
              SizedBox(height: 16),
              Text(
                'Loading your flight information...',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Use actual data or fallback
    final user =
        viewModel.user ??
        User(
          name: "Guest User",
          email: "guest@email.com",
          nationality: "International",
        );

    final flight =
        viewModel.userFlight ??
        Flight(
          flightNumber: "ET302",
          airline: "Ethiopian Airlines",
          route: "ADD → CDG",
          departure: FlightLeg(
            airport: "ADD",
            city: "Addis Ababa",
            time: "23:35",
            date: "Today",
            terminal: "T2",
          ),
          arrival: FlightLeg(
            airport: "CDG",
            city: "Paris",
            time: "06:50+1",
            date: "Tomorrow",
            terminal: "2E",
          ),
          duration: "7h 15m",
          aircraft: "Boeing 787-9",
          seat: "12A",
          gate: "B7",
          status: "On Time",
          checkInTime: "21:35",
          boardingTime: "23:00",
          timeUntilDeparture: "5h 23m",
        );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Status Bar
            _buildStatusBar(viewModel),

            // Top Header
            _buildTopHeader(viewModel, user),

            // Main Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await viewModel.initializeData();
                },
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Upcoming Flight Section
                      _buildUpcomingFlightSection(viewModel, flight),

                      // Pre-Flight Matches Section
                      _buildPreFlightMatchesSection(viewModel),

                      // Community Flight Stories
                      _buildFlightStoriesSection(viewModel),

                      // Bottom spacing for navigation
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Navigation
            //  _buildBottomNavigation(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(HomeViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary, AppColors.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [],
      ),
    );
  }

  Widget _buildTopHeader(HomeViewModel viewModel, User user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary, AppColors.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
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

          // Notifications and Profile
          Row(
            children: [
              Stack(
                children: [
                  IconButton(
                    onPressed: widget.onNavigateToNotifications,
                    icon: Icon(Icons.notifications, color: Colors.white),
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
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          viewModel.notificationCount > 9
                              ? '4+'
                              : viewModel.notificationCount.toString(),
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
              GestureDetector(
                onTap: widget.onNavigateToProfile,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: user.profileImage != null
                      ? CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(user.profileImage!),
                        )
                      : Text(
                          user.name.substring(0, 2).toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingFlightSection(HomeViewModel viewModel, Flight flight) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Your Upcoming Flight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: widget.onNavigateToMyFlights,
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                child: Column(
                  children: [
                    // Flight Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                flight.flightNumber,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              flight.airline,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
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
                              flight.status,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Route
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                flight.departure.airport,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Text(
                                flight.departure.city,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                flight.departure.time,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                flight.departure.date,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(color: AppColors.primary),
                                  ),
                                  Transform.rotate(
                                    angle: 0.8,
                                    child: Icon(
                                      Icons.flight_takeoff,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(color: AppColors.primary),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                flight.duration,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                flight.aircraft,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                flight.arrival.airport,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Text(
                                flight.arrival.city,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                flight.arrival.time,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                flight.arrival.date,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 12),

                    // Flight Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Icon(
                              Icons.place,
                              color: Colors.grey[600],
                              size: 16,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Gate ${flight.gate}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Terminal ${flight.departure.terminal}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(
                              Icons.people,
                              color: Colors.grey[600],
                              size: 16,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Seat ${flight.seat}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Window',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.grey[600],
                              size: 16,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Departure in',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              flight.timeUntilDeparture,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: viewModel.isLoading
                                ? null
                                : viewModel.checkIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: viewModel.isLoading
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text('Check In'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: viewModel.isLoading
                                ? null
                                : viewModel.viewFlightDetails,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('Details'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreFlightMatchesSection(HomeViewModel viewModel) {
    final matches = viewModel.preFlightMatches;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Colors.blue],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Pre-Flight Matches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: widget.onNavigateToPreFlightMatching,
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Color(0xFFF0FDF4), Color(0xFFF0F9FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green, Colors.blue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.travel_explore,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${matches?['matchCount'] ?? 0} Travel Matches Found!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Text(
                                matches?['commonRoute'] ??
                                    'Finding travel companions...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if ((matches?['matchCount'] ?? 0) > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              border: Border.all(color: Colors.green[200]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'New',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 12),

                    if ((matches?['matchCount'] ?? 0) > 0) ...[
                      // Match Preview
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.green[100],
                              child: Text(
                                matches?['matches']?[0]['initials'] ?? 'MW',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green[700],
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
                                    matches?['matches']?[0]['name'] ??
                                        'Travel Companion',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    matches?['matches']?[0]['route'] ??
                                        'Same flight route',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                border: Border.all(color: Colors.green[200]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${matches?['matches']?[0]['matchScore'] ?? 0}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '"${matches?['matches']?[0]['message'] ?? 'Looking for travel companions!'}"',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 12),
                    ],

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.green, Colors.blue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ElevatedButton(
                              onPressed: (matches?['matchCount'] ?? 0) > 0
                                  ? () => widget.onNavigateToPreFlightMatching
                                        ?.call()
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Connect Now'),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => widget.onNavigateToMatch?.call(),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide(color: Colors.green),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Browse All',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Benefits Info
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: const Color.fromARGB(255, 164, 151, 27),
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Pre-flight matching helps you:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.only(left: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• Plan layover activities together',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[600],
                                  ),
                                ),
                                Text(
                                  '• Share taxis and reduce costs',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[600],
                                  ),
                                ),
                                Text(
                                  '• Get travel tips and guidance',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[600],
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightStoriesSection(HomeViewModel viewModel) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Community Flight Stories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: widget.onNavigateToMatch,
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          if (viewModel.flightPosts.isEmpty && !viewModel.isLoading)
            Container(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.airplanemode_inactive,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No flight stories yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  Text(
                    'Be the first to share your travel experience!',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: viewModel.flightPosts
                  .map((post) => _buildFlightPostCard(post, viewModel))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildFlightPostCard(FlightPost post, HomeViewModel viewModel) {
    final isExpanded = viewModel.expandedPosts.contains(post.id);
    final displayContent = isExpanded && post.post.fullContent != null
        ? post.post.fullContent!
        : post.post.content;

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: post.user.avatar != null
                      ? CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(post.user.avatar!),
                        )
                      : Text(
                          post.user.name.split(' ').map((n) => n[0]).join(''),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
                        post.user.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.place, size: 12, color: Colors.grey[600]),
                          SizedBox(width: 2),
                          Text(
                            post.user.nationality,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 2),
                          Text(
                            post.post.timestamp,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Flight Info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1E40AF).withOpacity(0.1),
                    Color(0xFF06B6D4).withOpacity(0.1),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      post.flight.number,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    post.flight.route,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Spacer(),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        Icons.star,
                        size: 12,
                        color: index < post.post.rating
                            ? Colors.amber
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Post Content
            Text(
              post.post.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              displayContent,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),

            if (post.post.fullContent != null &&
                post.post.fullContent!.length > post.post.content.length)
              GestureDetector(
                onTap: () => viewModel.toggleReadMore(post.id),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isExpanded ? 'Read Less' : 'Read More',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: Color(0xFF1E40AF),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 8),

            // Engagement
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => viewModel.toggleLike(post.id),
                      child: Row(
                        children: [
                          Icon(
                            post.post.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: post.post.isLiked
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            post.post.likes.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: post.post.isLiked
                                  ? Colors.red
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          post.post.comments.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: widget.onNavigateToProfile,
                  child: Text(
                    'View Profile',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  //   Widget _buildBottomNavigation(HomeViewModel viewModel) {
  //     return Container(
  //       decoration: BoxDecoration(
  //         color: Colors.white.withOpacity(0.95),
  //         border: Border(top: BorderSide(color: Colors.grey[300]!)),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black12,
  //             blurRadius: 8,
  //             offset: Offset(0, -2),
  //           ),
  //         ],
  //       ),
  //       child: SafeArea(
  //         top: false,
  //         child: Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceAround,
  //             children: viewModel.bottomNavItems
  //                 .map((item) => _buildBottomNavItem(item, viewModel))
  //                 .toList(),
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   Widget _buildBottomNavItem(BottomNavItem item, HomeViewModel viewModel) {
  //     final isActive = item.active;

  //     return GestureDetector(
  //       onTap: item.action,
  //       child: Container(
  //         padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  //         decoration: BoxDecoration(
  //           borderRadius: BorderRadius.circular(12),
  //           gradient: isActive
  //               ? LinearGradient(
  //                   colors: [
  //                     Color(0xFF1E40AF).withOpacity(0.2),
  //                     Color(0xFF06B6D4).withOpacity(0.1),
  //                   ],
  //                   begin: Alignment.topCenter,
  //                   end: Alignment.bottomCenter,
  //                 )
  //               : null,
  //           boxShadow: isActive
  //               ? [
  //                   BoxShadow(
  //                     color: Color(0xFF1E40AF).withOpacity(0.2),
  //                     blurRadius: 8,
  //                     offset: Offset(0, 2),
  //                   ),
  //                 ]
  //               : null,
  //         ),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Text(
  //               item.icon,
  //               style: TextStyle(
  //                 fontSize: 18,
  //                 color: isActive ? Color(0xFF1E40AF) : Colors.grey[600],
  //               ),
  //             ),
  //             SizedBox(height: 4),
  //             Text(
  //               item.label,
  //               style: TextStyle(
  //                 fontSize: 10,
  //                 fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
  //                 color: isActive ? Color(0xFF1E40AF) : Colors.grey[600],
  //               ),
  //               textAlign: TextAlign.center,
  //               maxLines: 1,
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  //
}
