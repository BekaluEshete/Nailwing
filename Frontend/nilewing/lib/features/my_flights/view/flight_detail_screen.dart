// features/my_flights/screens/flight_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:nilewing/core/theme/app_colors.dart';

class FlightDetailScreen extends StatefulWidget {
  final String flightId;
  final VoidCallback onNavigateBack;

  const FlightDetailScreen({
    Key? key,
    required this.flightId,
    required this.onNavigateBack,
  }) : super(key: key);

  @override
  State<FlightDetailScreen> createState() => _FlightDetailScreenState();
}

class _FlightDetailScreenState extends State<FlightDetailScreen> {
  final Map<String, String> _delayForm = {
    'newDepartureTime': '',
    'newArrivalTime': '',
    'delayReason': '',
    'delayDuration': '',
  };

  final List<String> _delayReasons = [
    'Weather conditions',
    'Technical issues',
    'Air traffic control',
    'Crew scheduling',
    'Airport operations',
    'Security reasons',
    'Other',
  ];

  // Mock flight data - in real app, fetch based on flightId
  Map<String, dynamic> get _flightDetail {
    return {
      'id': widget.flightId,
      'flightNumber': 'ET302',
      'airline': 'Ethiopian Airlines',
      'departure': {
        'airport': 'ADD',
        'city': 'Addis Ababa',
        'country': 'Ethiopia',
        'time': '23:35',
        'date': 'Today, Dec 22',
        'terminal': 'T2',
        'gate': 'B7',
      },
      'arrival': {
        'airport': 'CDG',
        'city': 'Paris',
        'country': 'France',
        'time': '06:50+1',
        'date': 'Tomorrow, Dec 23',
        'terminal': '2E',
        'gate': 'A12',
      },
      'duration': '7h 15m',
      'aircraft': 'Boeing 787-9',
      'seat': '12A',
      'bookingReference': 'ET9X7K',
      'eTicketNumber': '123-4567890123',
      'status': 'On Time',
      'class': 'Economy',
      'price': '\$675',
      'baggage': {
        'checkedBags': '1 x 23kg',
        'carryOn': '1 x 8kg',
        'personalItem': '1 x 3kg',
      },
      'passenger': {
        'name': 'Markos Tesfaye',
        'frequentFlyer': 'ShebaMiles Gold',
        'specialRequests': ['Window Seat', 'Vegetarian Meal'],
      },
      'checkIn': {
        'opensAt': '21:35 (2 hours before)',
        'closesAt': '22:35 (1 hour before)',
        'status': 'Available',
      },
      'amenities': ['WiFi', 'Entertainment', 'Meals', 'USB Power'],
      'timeline': [
        {'time': '21:35', 'event': 'Check-in opens', 'status': 'upcoming'},
        {'time': '22:35', 'event': 'Check-in closes', 'status': 'upcoming'},
        {'time': '23:00', 'event': 'Boarding begins', 'status': 'upcoming'},
        {'time': '23:35', 'event': 'Departure', 'status': 'upcoming'},
      ],
    };
  }

  void _handleCancelFlight() {
    // In a real app, this would make an API call to cancel the flight
    _showSnackBar(
      'Flight cancelled successfully. Post has been removed from public view.',
    );

    // Navigate back after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      widget.onNavigateBack();
    });
  }

  void _handleDelayFlight() {
    if (_delayForm['newDepartureTime']!.isEmpty ||
        _delayForm['delayReason']!.isEmpty ||
        _delayForm['delayDuration']!.isEmpty) {
      _showSnackBar('Please fill in all required fields');
      return;
    }

    // In a real app, this would make an API call to update the flight
    _showSnackBar(
      'Flight delay updated successfully. Notifications sent to connected travelers.',
    );

    // Reset form
    setState(() {
      _delayForm.updateAll((key, value) => '');
    });

    // Navigate back after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      widget.onNavigateBack();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Flight Status Card
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    // Flight Management Actions
                    _buildManagementCard(),
                    const SizedBox(height: 16),
                    // Route Information
                    _buildRouteCard(),
                    const SizedBox(height: 16),
                    // Passenger Information
                    _buildPassengerCard(),
                    const SizedBox(height: 16),
                    // Booking Information
                    _buildBookingCard(),
                    const SizedBox(height: 16),
                    // Baggage Information
                    _buildBaggageCard(),
                    const SizedBox(height: 16),
                    // Check-in Information
                    _buildCheckInCard(),
                    const SizedBox(height: 16),
                    // Flight Timeline
                    _buildTimelineCard(),
                    const SizedBox(height: 16),
                    // Amenities
                    _buildAmenitiesCard(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent ?? AppColors.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: widget.onNavigateBack,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _flightDetail['flightNumber'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _flightDetail['airline'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    // Share functionality
                    _showSnackBar('Share flight details');
                  },
                  icon: const Icon(Icons.share, color: Colors.white, size: 20),
                ),
                IconButton(
                  onPressed: () {
                    // Download functionality
                    _showSnackBar('Download flight details');
                  },
                  icon: const Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green[50]!, Colors.green[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _flightDetail['status'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Boarding starts at ${_getBoardingTime()}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBoardingTime() {
    final timeline = _flightDetail['timeline'] as List;
    final boarding = timeline.firstWhere(
      (item) => item['event'] == 'Boarding begins',
      orElse: () => {'time': '--:--'},
    );
    return boarding['time'];
  }

  Widget _buildManagementCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange[50]!, Colors.red[50]!],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, size: 20, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'Flight Management',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Need to make changes to your flight? Use the options below to update or cancel.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showDelayDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.orange[600],
                        side: BorderSide(color: Colors.orange[200]!),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time, size: 16),
                          SizedBox(width: 4),
                          Text('Delay Flight'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showCancelDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.red[600],
                        side: BorderSide(color: Colors.red[200]!),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel, size: 14),
                          SizedBox(width: 3),
                          Text('Cancel '),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  border: Border.all(color: Colors.amber[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.amber[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Important Notice:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'These actions will affect your visibility to other travelers and any active connections. Make sure to coordinate with anyone you\'ve already connected with.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber[700],
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
    );
  }

  Widget _buildRouteCard() {
    final departure = _flightDetail['departure'];
    final arrival = _flightDetail['arrival'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue[50]!, Colors.cyan[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          departure['airport'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          departure['city'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          departure['time'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          departure['date'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
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
                            Expanded(child: Divider(color: AppColors.primary)),
                            Icon(
                              Icons.flight_takeoff,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            Expanded(child: Divider(color: AppColors.primary)),
                          ],
                        ),
                        Text(
                          _flightDetail['duration'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _flightDetail['aircraft'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          arrival['airport'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          arrival['city'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          arrival['time'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          arrival['date'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Departure',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Terminal ${departure['terminal']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Gate ${departure['gate']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Arrival',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Terminal ${arrival['terminal']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Gate ${arrival['gate']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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

  Widget _buildPassengerCard() {
    final passenger = _flightDetail['passenger'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Passenger Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        passenger['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _flightDetail['seat'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Class',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _flightDetail['class'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Frequent Flyer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        passenger['frequentFlyer'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Special Requests',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (passenger['specialRequests'] as List).map((request) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(request, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildInfoRow(
                  'Booking Reference',
                  _flightDetail['bookingReference'],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'E-Ticket Number',
                  _flightDetail['eTicketNumber'],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Total Price',
                  _flightDetail['price'],
                  isPrice: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPrice = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isPrice ? FontWeight.bold : FontWeight.normal,
            color: isPrice ? AppColors.primary : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildBaggageCard() {
    final baggage = _flightDetail['baggage'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.luggage, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Baggage Allowance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildInfoRow('Checked Bags', baggage['checkedBags']),
                const SizedBox(height: 8),
                _buildInfoRow('Carry-on', baggage['carryOn']),
                const SizedBox(height: 8),
                _buildInfoRow('Personal Item', baggage['personalItem']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInCard() {
    final checkIn = _flightDetail['checkIn'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.cyan[50]!],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Check-in',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  _buildInfoRow('Opens', checkIn['opensAt']),
                  const SizedBox(height: 8),
                  _buildInfoRow('Closes', checkIn['closesAt']),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _showSnackBar('Mobile Check-in opened');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code, size: 16),
                    SizedBox(width: 8),
                    Text('Mobile Check-in'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineCard() {
    final timeline = _flightDetail['timeline'] as List;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Flight Timeline',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: timeline.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['event'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              item['time'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesCard() {
    final amenities = _flightDetail['amenities'] as List;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Flight Amenities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities.map((amenity) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(amenity, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showDelayDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Flight Delay'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update your flight details to notify connected travelers about the delay.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('New Departure Time *'),
                        const SizedBox(height: 4),
                        TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'HH:MM',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _delayForm['newDepartureTime'] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('New Arrival Time'),
                        const SizedBox(height: 4),
                        TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'HH:MM',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _delayForm['newArrivalTime'] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delay Duration *'),
                  const SizedBox(height: 4),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'e.g. 2h 30m',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _delayForm['delayDuration'] = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reason for Delay *'),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: _delayReasons.map((reason) {
                      return DropdownMenuItem(
                        value: reason,
                        child: Text(reason),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _delayForm['delayReason'] = value ?? '';
                      });
                    },
                  ),
                ],
              ),
              if (_delayForm['delayDuration']!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
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
                          const SizedBox(width: 8),
                          const Text(
                            'Delay Summary',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Flight will be delayed by ${_delayForm['delayDuration']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Connected travelers will be automatically notified',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _handleDelayFlight,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[500],
              foregroundColor: Colors.white,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 4),
                Text('Update Flight'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Cancel Flight?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This action will:'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('• Remove your flight post from public view'),
                  Text('• Notify connected travelers about the cancellation'),
                  Text('• Cancel any pending connection requests'),
                  Text('• Remove the flight from matching suggestions'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ This action cannot be undone',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Flight'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleCancelFlight();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete, size: 16),
                SizedBox(width: 4),
                Text('Yes, Cancel Flight'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
