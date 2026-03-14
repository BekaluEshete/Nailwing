// features/my_flights/screens/my_flights_screen.dart
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
          colors: [AppColors.primary, AppColors.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: widget.onNavigateBack,
              icon: Icon(Icons.arrow_back, color: Colors.white),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Flights',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${viewModel.flights.where((f) => f.isVisible).length} active • ${viewModel.cancelledFlights.length} cancelled',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
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
                                child: Divider(
                                  color: _getRouteColor(flight.status),
                                ),
                              ),
                              Icon(
                                Icons.flight_takeoff,
                                size: 16,
                                color: _getRouteColor(flight.status),
                              ),
                              Expanded(
                                child: Divider(
                                  color: _getRouteColor(flight.status),
                                ),
                              ),
                            ],
                          ),
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

                // Flight Actions
                if (showActions) ...[
                  SizedBox(height: 16),
                  Divider(),
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
                        Text(
                          'Flight Cancelled - Hidden from public view',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
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
                Divider(),
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

  Widget _buildFlightActions(Flight flight, MyFlightsViewModel viewModel) {
    // Disable buttons for completed or cancelled flights
    final isDisabled = flight.status == FlightStatus.completed || 
                       flight.status == FlightStatus.cancelled;
    
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isDisabled ? null : () => _showDelayDialog(flight, viewModel),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: isDisabled ? Colors.grey[400] : Colors.orange[600],
              side: BorderSide(color: isDisabled ? Colors.grey[300]! : Colors.orange[200]!),
              elevation: 0,
            ),
            icon: Icon(Icons.access_time, size: 16),
            label: Text('Delay'),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isDisabled ? null : () => _showCancelDialog(flight, viewModel),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: isDisabled ? Colors.grey[400] : Colors.red[600],
              side: BorderSide(color: isDisabled ? Colors.grey[300]! : Colors.red[200]!),
              elevation: 0,
            ),
            icon: Icon(Icons.cancel, size: 16),
            label: Text('Cancel'),
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

// Delay Flight Dialog
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
  final List<String> delayReasons = [
    'Weather conditions',
    'Technical issues',
    'Air traffic control',
    'Crew scheduling',
    'Airport operations',
    'Security reasons',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Flight Delay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Update ${widget.flight.flightNumber} delay information for connected travelers.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 20),

              // Time inputs
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Departure *',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'HH:MM',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) =>
                              _delayForm.newDepartureTime = value,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Arrival',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'HH:MM',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) =>
                              _delayForm.newArrivalTime = value,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Delay duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delay Duration *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'e.g. 2h 30m',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) => _delayForm.delayDuration = value,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Delay reason
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: delayReasons
                        .map(
                          (reason) => DropdownMenuItem(
                            value: reason,
                            child: Text(reason, style: TextStyle(fontSize: 14)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => _delayForm.delayReason = value ?? '',
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ],
              ),

              // Delay preview
              if (_delayForm.delayDuration.isNotEmpty) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border.all(color: Colors.orange[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning,
                            size: 16,
                            color: Colors.orange[600],
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delay Summary',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Flight will be delayed by ${_delayForm.delayDuration}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Connected travelers will be automatically notified',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          widget.onUpdateDelay(_delayForm);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[500],
                        foregroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 4),
                          Text('Update'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Cancel Flight Dialog
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.cancel, color: Colors.red),
          SizedBox(width: 8),
          Text('Cancel ${flight.flightNumber}?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This action will:'),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Remove your flight post from public view'),
                Text('• Notify connected travelers about the cancellation'),
                Text('• Cancel any pending connection requests'),
                Text('• Remove the flight from matching suggestions'),
              ],
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '⚠️ This action cannot be undone',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Keep Flight'),
        ),
        ElevatedButton(
          onPressed: () {
            onCancel();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete, size: 16),
              SizedBox(width: 4),
              Text('Cancel Flight'),
            ],
          ),
        ),
      ],
    );
  }
}
