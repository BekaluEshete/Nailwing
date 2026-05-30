// features/my_flights/screens/my_flights_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nilewing/core/theme/app_colors.dart';
import 'package:nilewing/features/my_flights/view/add_flight_post_screen.dart';
import 'package:nilewing/features/my_flights/view/flight_detail_screen.dart';
import '../model/flight_model.dart';
import '../viewmodel/flight_view_model.dart';

class MyFlightsScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateBack;
  final VoidCallback onNavigateToAddFlight;
  final Function(String) onNavigateToFlightDetail;

  const MyFlightsScreen({
    Key? key,
    required this.onNavigateBack,
    required this.onNavigateToAddFlight,
    required this.onNavigateToFlightDetail,
  }) : super(key: key);

  @override
  ConsumerState<MyFlightsScreen> createState() => _MyFlightsScreenState();
}

class _MyFlightsScreenState extends ConsumerState<MyFlightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myFlightsViewModelProvider).loadFlights();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(myFlightsViewModelProvider);
    final flights = viewModel.flights;
    final upcomingFlights = viewModel.upcomingFlights;
    final pastFlights = viewModel.pastFlights;
    final cancelledFlights = viewModel.cancelledFlights;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                _buildHeader(viewModel),

                // Content
                Expanded(
                  child: _buildContent(
                    viewModel,
                    flights,
                    upcomingFlights,
                    pastFlights,
                    cancelledFlights,
                  ),
                ),
              ],
            ),

            // Floating Add Button
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddFlightPostScreen(
                        onNavigateBack: () => Navigator.pop(context),
                        onFlightAdded: (newFlight) {
                          // Add to view model
                          ref
                              .read(myFlightsViewModelProvider)
                              .addFlight(newFlight as Flight);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 8,
                child: const Icon(Icons.add, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... Rest of your existing methods remain exactly the same ...
  // _buildHeader, _buildContent, _buildSectionHeader, _buildFlightCard, etc.
  // All the helper methods and dialog classes remain unchanged

  Widget _buildHeader(MyFlightsViewModel viewModel) {
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
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 24),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onNavigateBack,
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Flights',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${viewModel.flights.where((f) => f.isVisible).length} active • ${viewModel.cancelledFlights.length} cancelled',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildContent(
    MyFlightsViewModel viewModel,
    List<Flight> flights,
    List<Flight> upcomingFlights,
    List<Flight> pastFlights,
    List<Flight> cancelledFlights,
  ) {
    if (viewModel.isLoading && flights.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upcoming Flights
          if (upcomingFlights.isNotEmpty) ...[
            _buildSectionHeader(
              'Upcoming Flights (${upcomingFlights.length})',
              AppColors.primary,
            ),
            SizedBox(height: 12),
            ...upcomingFlights.map(
              (flight) => _buildFlightCard(flight, viewModel, true),
            ),
            SizedBox(height: 24),
          ],

          // Past Flights
          if (pastFlights.isNotEmpty) ...[
            _buildSectionHeader(
              'Past Flights (${pastFlights.length})',
              Colors.grey,
            ),
            SizedBox(height: 12),
            ...pastFlights.map(
              (flight) => _buildFlightCard(flight, viewModel, false),
            ),
            SizedBox(height: 24),
          ],

          // Cancelled Flights
          if (cancelledFlights.isNotEmpty) ...[
            _buildSectionHeaderWithBadge(
              'Cancelled Flights (${cancelledFlights.length})',
            ),
            SizedBox(height: 12),
            ...cancelledFlights.map(
              (flight) => _buildFlightCard(flight, viewModel, false),
            ),
            SizedBox(height: 24),
          ],

          // Empty State
          if (flights.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Icon(
                      Icons.flight,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No flights yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first flight to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddFlightPostScreen(
                            onNavigateBack: () => Navigator.pop(context),
                            onFlightAdded: (newFlight) {
                              ref
                                  .read(myFlightsViewModelProvider)
                                  .addFlight(newFlight as Flight);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Add Flight'),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 80), // Bottom spacing for FAB
        ],
      ),
    );
  }

  // ... All other methods remain exactly the same as in your original code ...
  // _buildSectionHeader, _buildSectionHeaderWithBadge, _buildFlightCard,
  // _buildFlightActions, _showDelayDialog, _showCancelDialog, and all helper methods

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeaderWithBadge(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Colors.red.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red[50],
            border: Border.all(color: Colors.red[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Hidden from others',
            style: TextStyle(
              fontSize: 10,
              color: Colors.red[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlightCard(
    Flight flight,
    MyFlightsViewModel viewModel,
    bool showActions,
  ) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlightDetailScreen(
                flightId: flight.id,
                onNavigateBack: () => Navigator.pop(context),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: _getCardGradient(flight.status),
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(flight.status),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusBorderColor(flight.status),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(flight.status),
                            size: 12,
                            color: _getStatusTextColor(flight.status),
                          ),
                          SizedBox(width: 4),
                          Text(
                            _getStatusText(flight.status),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getStatusTextColor(flight.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Route
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            flight.departure.airport,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey[900],
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            flight.departure.city,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            flight.departure.time,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            flight.departure.date,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
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
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _getRouteColor(flight.status), width: 2),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _getRouteColor(flight.status).withOpacity(0.2),
                                        _getRouteColor(flight.status),
                                        _getRouteColor(flight.status).withOpacity(0.2),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Transform.rotate(
                                angle: 1.5708, // 90 degrees
                                child: Icon(
                                  Icons.flight,
                                  color: _getRouteColor(flight.status),
                                  size: 24,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _getRouteColor(flight.status).withOpacity(0.2),
                                        _getRouteColor(flight.status).withOpacity(0.5),
                                        _getRouteColor(flight.status).withOpacity(0.2),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _getRouteColor(flight.status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              flight.duration,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            flight.aircraft,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            flight.arrival.airport,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey[900],
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            flight.arrival.city,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            flight.arrival.time,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            flight.arrival.date,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Flight Actions
                if (showActions) ...[
                  SizedBox(height: 16),
                  _buildDivider(),
                  SizedBox(height: 12),
                  _buildFlightActions(flight, viewModel),
                ],

                // Delay Notice
                if (flight.status == FlightStatus.delayed &&
                    flight.delayTime != null) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          size: 16,
                          color: Colors.orange[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delayed by ${flight.delayTime}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Cancelled Notice
                if (flight.status == FlightStatus.cancelled) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cancel, size: 16, color: Colors.red[600]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Flight Cancelled — Hidden from public view',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Flight Rating and Post Info
                if (flight.hasPost &&
                    flight.status == FlightStatus.completed) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Row(
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  Icons.star,
                                  size: 12,
                                  color: index < (flight.rating ?? 0)
                                      ? Colors.amber
                                      : Colors.grey[300],
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Flight Story Posted',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (flight.postTitle != null) ...[
                          SizedBox(height: 8),
                          Text(
                            flight.postTitle!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            flight.postContent ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    size: 12,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${flight.likes}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 12,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${flight.comments}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'View Story →',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1E40AF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Transit Info
                if (flight.transitTime != null &&
                    flight.transitAirport != null) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      border: Border.all(color: Colors.amber[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.amber[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Transit: ${flight.transitTime} at ${flight.transitAirport}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 12),
                _buildDivider(),
                SizedBox(height: 8),

                // Flight Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.place, size: 16, color: Colors.grey[600]),
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
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        SizedBox(height: 4),
                        Text(
                          'Seat ${flight.seat}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _getSeatStatus(flight.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getSeatStatusColor(flight.status),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(height: 4),
                        Text(
                          flight.status == FlightStatus.completed
                              ? 'Arrived'
                              : 'Departure',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          flight.departure.date,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getDateColor(flight.status),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.25),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.25),
                  AppColors.primary.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlightActions(Flight flight, MyFlightsViewModel viewModel) {
    final isDisabled = flight.status == FlightStatus.completed ||
        flight.status == FlightStatus.cancelled;

    return Row(
      children: [
        // ── Delay button ──────────────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTap: isDisabled ? null : () => _showDelayDialog(flight, viewModel),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 46,
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey[100]
                    : Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDisabled
                      ? Colors.grey[200]!
                      : Colors.orange.withOpacity(0.35),
                  width: 1.5,
                ),
                boxShadow: isDisabled
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? Colors.grey[200]
                          : Colors.orange.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.access_time_filled_rounded,
                      size: 14,
                      color: isDisabled ? Colors.grey[400] : Colors.orange[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delay',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDisabled ? Colors.grey[400] : Colors.orange[700],
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // ── Cancel button ─────────────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTap: isDisabled ? null : () => _showCancelDialog(flight, viewModel),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 46,
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey[100]
                    : Colors.red.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDisabled
                      ? Colors.grey[200]!
                      : Colors.red.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: isDisabled
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? Colors.grey[200]
                          : Colors.red.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 14,
                      color: isDisabled ? Colors.grey[400] : Colors.red[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDisabled ? Colors.grey[400] : Colors.red[600],
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDelayDialog(Flight flight, MyFlightsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => DelayFlightDialog(
        flight: flight,
        onUpdateDelay: (delayData) {
          viewModel.updateDelayForm(delayData);
          viewModel.updateFlightDelay(flight.id);
        },
      ),
    );
  }

  void _showCancelDialog(Flight flight, MyFlightsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => CancelFlightDialog(
        flight: flight,
        onCancel: () => viewModel.cancelFlight(flight.id),
      ),
    );
  }

  // Helper methods for styling
  LinearGradient _getCardGradient(FlightStatus status) {
    switch (status) {
      case FlightStatus.completed:
        return LinearGradient(
          colors: [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case FlightStatus.cancelled:
        return LinearGradient(
          colors: [Colors.red[50]!, Colors.red[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [Colors.white, Color(0xFFF0F9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getStatusColor(FlightStatus status) {
    switch (status) {
      case FlightStatus.upcoming:
        return Colors.blue[100]!;
      case FlightStatus.boarding:
        return Colors.green[100]!;
      case FlightStatus.delayed:
        return Colors.orange[100]!;
      case FlightStatus.completed:
        return Colors.grey[100]!;
      case FlightStatus.cancelled:
        return Colors.red[100]!;
    }
  }

  Color _getStatusBorderColor(FlightStatus status) {
    switch (status) {
      case FlightStatus.upcoming:
        return Colors.blue[200]!;
      case FlightStatus.boarding:
        return Colors.green[200]!;
      case FlightStatus.delayed:
        return Colors.orange[200]!;
      case FlightStatus.completed:
        return Colors.grey[200]!;
      case FlightStatus.cancelled:
        return Colors.red[200]!;
    }
  }

  Color _getStatusTextColor(FlightStatus status) {
    switch (status) {
      case FlightStatus.upcoming:
        return Colors.blue[700]!;
      case FlightStatus.boarding:
        return Colors.green[700]!;
      case FlightStatus.delayed:
        return Colors.orange[700]!;
      case FlightStatus.completed:
        return Colors.grey[700]!;
      case FlightStatus.cancelled:
        return Colors.red[700]!;
    }
  }

  IconData _getStatusIcon(FlightStatus status) {
    switch (status) {
      case FlightStatus.upcoming:
        return Icons.access_time;
      case FlightStatus.boarding:
        return Icons.flight_takeoff;
      case FlightStatus.delayed:
        return Icons.warning;
      case FlightStatus.completed:
        return Icons.check_circle;
      case FlightStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(FlightStatus status) {
    switch (status) {
      case FlightStatus.upcoming:
        return 'Upcoming';
      case FlightStatus.boarding:
        return 'Boarding';
      case FlightStatus.delayed:
        return 'Delayed';
      case FlightStatus.completed:
        return 'Completed';
      case FlightStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getRouteColor(FlightStatus status) {
    return status == FlightStatus.cancelled
        ? Colors.red[400]!
        : AppColors.primary;
  }

  String _getSeatStatus(FlightStatus status) {
    switch (status) {
      case FlightStatus.cancelled:
        return 'Cancelled';
      case FlightStatus.completed:
        return 'Completed';
      default:
        return 'Confirmed';
    }
  }

  Color _getSeatStatusColor(FlightStatus status) {
    return status == FlightStatus.cancelled
        ? Colors.red[600]!
        : Colors.grey[800]!;
  }

  Color _getDateColor(FlightStatus status) {
    return status == FlightStatus.cancelled
        ? Colors.red[600]!
        : AppColors.primary;
  }
}

// ─── Delay Flight Dialog ──────────────────────────────────────────────────────
class DelayFlightDialog extends StatefulWidget {
  final Flight flight;
  final Function(DelayFormData) onUpdateDelay;

  const DelayFlightDialog({
    Key? key,
    required this.flight,
    required this.onUpdateDelay,
  }) : super(key: key);

  @override
  State<DelayFlightDialog> createState() => _DelayFlightDialogState();
}

class _DelayFlightDialogState extends State<DelayFlightDialog> {
  final _formKey = GlobalKey<FormState>();
  final _delayForm = DelayFormData();
  String? _selectedReason;

  final List<String> delayReasons = [
    'Weather conditions',
    'Technical issues',
    'Air traffic control',
    'Crew scheduling',
    'Airport operations',
    'Security reasons',
    'Other',
  ];

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade600, Colors.orange.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.access_time_filled_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Report Delay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.flight.flightNumber,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Times row
                      Row(
                        children: [
                          Expanded(
                            child: _formField(
                              label: 'New Departure',
                              required: true,
                              child: TextFormField(
                                decoration: _inputDeco('HH:MM'),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                onChanged: (v) => _delayForm.newDepartureTime = v,
                                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _formField(
                              label: 'New Arrival',
                              child: TextFormField(
                                decoration: _inputDeco('HH:MM'),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                onChanged: (v) => _delayForm.newArrivalTime = v,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Duration
                      _formField(
                        label: 'Delay Duration',
                        required: true,
                        child: TextFormField(
                          decoration: _inputDeco('e.g. 2h 30m'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          onChanged: (v) {
                            setState(() => _delayForm.delayDuration = v);
                          },
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Reason
                      _formField(
                        label: 'Reason',
                        required: true,
                        child: DropdownButtonFormField<String>(
                          value: _selectedReason,
                          decoration: _inputDeco('Select reason'),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                          items: delayReasons
                              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedReason = v;
                              _delayForm.delayReason = v ?? '';
                            });
                          },
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),

                      // Preview banner
                      if (_delayForm.delayDuration.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 18, color: Colors.orange[600]),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Delayed by ${_delayForm.delayDuration}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.orange[800],
                                      ),
                                    ),
                                    Text(
                                      'Connected travelers will be notified',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.orange[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Dismiss',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade600, Colors.orange.shade400],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            widget.onUpdateDelay(_delayForm);
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Update',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
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

  Widget _formField({
    required String label,
    required Widget child,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.3,
              ),
            ),
            if (required)
              const Text(' *',
                  style: TextStyle(color: Colors.orange, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ─── Cancel Flight Dialog ─────────────────────────────────────────────────────
class CancelFlightDialog extends StatelessWidget {
  final Flight flight;
  final VoidCallback onCancel;

  const CancelFlightDialog({
    Key? key,
    required this.flight,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade600, Colors.red.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cancel_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cancel Flight',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          flight.flightNumber,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This will permanently affect your flight listing.',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey[600], height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  // Impact list
                  ...[
                    ('Remove flight from public view', Icons.visibility_off_rounded),
                    ('Notify connected travelers', Icons.notifications_off_rounded),
                    ('Cancel pending connection requests', Icons.person_remove_rounded),
                    ('Remove from matching suggestions', Icons.search_off_rounded),
                  ].map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(item.$2, size: 14, color: Colors.red[400]),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item.$1,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Warning banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 18, color: Colors.red[500]),
                        const SizedBox(width: 8),
                        Text(
                          'This action cannot be undone',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                            color: AppColors.primary.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Keep Flight',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade600, Colors.red.shade400],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          onCancel();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete_rounded, size: 16),
                        label: const Text('Cancel Flight',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
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
}
