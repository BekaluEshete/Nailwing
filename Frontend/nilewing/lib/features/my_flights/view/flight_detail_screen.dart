// features/my_flights/screens/flight_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:nilewing/core/theme/app_colors.dart';
import '../model/flight_model.dart';
import '../services/flight_service.dart';

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
  final FlightService _flightService = FlightService();
  Flight? _flight;
  bool _isLoading = true;
  String? _error;

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

  @override
  void initState() {
    super.initState();
    _loadFlightDetail();
  }

  Future<void> _loadFlightDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final flight = await _flightService.getFlightById(widget.flightId);
      setState(() {
        _flight = flight;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load flight details: $e';
        _isLoading = false;
      });
    }
  }

  // Get flight detail map from Flight model
  Map<String, dynamic> get _flightDetail {
    if (_flight == null) {
      return {
        'id': widget.flightId,
        'flightNumber': '',
        'airline': '',
        'departure': {
          'airport': '',
          'city': '',
          'country': '',
          'time': '',
          'date': '',
          'terminal': '',
          'gate': '',
        },
        'arrival': {
          'airport': '',
          'city': '',
          'country': '',
          'time': '',
          'date': '',
          'terminal': '',
          'gate': '',
        },
        'duration': '',
        'aircraft': '',
        'seat': '',
        'bookingReference': '',
        'status': '',
        'class': '',
      };
    }

    final f = _flight!;
    return {
      'id': f.id,
      'flightNumber': f.flightNumber,
      'airline': f.airline,
      'departure': {
        'airport': f.departure.airport,
        'city': f.departure.city,
        'country': '',
        'time': f.departure.time,
        'date': f.departure.date,
        'terminal': f.departure.terminal,
        'gate': f.gate,
      },
      'arrival': {
        'airport': f.arrival.airport,
        'city': f.arrival.city,
        'country': '',
        'time': f.arrival.time,
        'date': f.arrival.date,
        'terminal': f.arrival.terminal,
        'gate': '',
      },
      'duration': f.duration,
      'aircraft': f.aircraft,
      'seat': f.seat,
      'bookingReference': '',
      'status': _getStatusText(f.status),
      'class': '',
      'delayTime': f.delayTime,
    };
  }
  
  String _getStatusText(FlightStatus status) {
    switch (status) {
      case FlightStatus.upcoming:
        return 'Scheduled';
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

  Future<void> _handleCancelFlight() async {
    if (_flight == null) return;

    try {
      final success = await _flightService.cancelFlight(_flight!.id);
      if (success) {
        _showSnackBar(
          'Flight cancelled successfully. Post has been removed from public view.',
        );
        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          widget.onNavigateBack();
        });
      } else {
        _showSnackBar('Failed to cancel flight. Please try again.');
      }
    } catch (e) {
      _showSnackBar('Error cancelling flight: $e');
    }
  }

  Future<void> _handleDelayFlight() async {
    if (_flight == null) return;

    if (_delayForm['newDepartureTime']!.isEmpty ||
        _delayForm['delayReason']!.isEmpty ||
        _delayForm['delayDuration']!.isEmpty) {
      _showSnackBar('Please fill in all required fields');
      return;
    }

    try {
      final delayMinutes = int.tryParse(
        _delayForm['delayDuration']!.replaceAll(RegExp(r'[^0-9]'), ''),
      ) ?? 0;

      await _flightService.updateFlightStatus(
        _flight!.id,
        'delayed',
        delayMinutes: delayMinutes,
      );

      _showSnackBar(
        'Flight delay updated successfully. Notifications sent to connected travelers.',
      );

      // Reload flight data
      await _loadFlightDetail();

      // Reset form
      setState(() {
        _delayForm.updateAll((key, value) => '');
      });
    } catch (e) {
      _showSnackBar('Error updating flight delay: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading flight details...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null || _flight == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Flight not found',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _loadFlightDetail();
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: widget.onNavigateBack,
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                    // Booking Information
                    _buildBookingCard(),
                    const SizedBox(height: 16),
                    // Flight Timeline
                    _buildTimelineCard(),
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
          colors: [
            AppColors.primary,
            AppColors.accent,
          ],
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
    if (_flight == null) return 'Check with airline';
    
    final departure = _flightDetail['departure'] as Map<String, dynamic>?;
    if (departure == null) return 'Check with airline';
    
    final departureTime = departure['time'] as String?;
    
    if (departureTime == null || departureTime.isEmpty) {
      return 'Check with airline';
    }
    
    try {
      // Calculate boarding time (typically 30 minutes before departure)
      final parts = departureTime.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        var boardingHour = hour;
        var boardingMinute = minute - 30; // 30 minutes before
        
        if (boardingMinute < 0) {
          boardingMinute += 60;
          boardingHour -= 1;
          if (boardingHour < 0) {
            boardingHour += 24;
          }
        }
        
        return '${boardingHour.toString().padLeft(2, '0')}:${boardingMinute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      // If parsing fails, just show a generic message
      return 'Check with airline';
    }
    
    return 'Check with airline';
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
                      onPressed: (_flight?.status == FlightStatus.completed || 
                                  _flight?.status == FlightStatus.cancelled)
                          ? null
                          : () => _showDelayDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: (_flight?.status == FlightStatus.completed || 
                                         _flight?.status == FlightStatus.cancelled)
                            ? Colors.grey[400]
                            : Colors.orange[600],
                        side: BorderSide(
                          color: (_flight?.status == FlightStatus.completed || 
                                 _flight?.status == FlightStatus.cancelled)
                              ? Colors.grey[300]!
                              : Colors.orange[200]!,
                        ),
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
                      onPressed: (_flight?.status == FlightStatus.completed || 
                                  _flight?.status == FlightStatus.cancelled)
                          ? null
                          : () => _showCancelDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: (_flight?.status == FlightStatus.completed || 
                                         _flight?.status == FlightStatus.cancelled)
                            ? Colors.grey[400]
                            : Colors.red[600],
                        side: BorderSide(
                          color: (_flight?.status == FlightStatus.completed || 
                                 _flight?.status == FlightStatus.cancelled)
                              ? Colors.grey[300]!
                              : Colors.red[200]!,
                        ),
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
              'Flight Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                if (_flight != null && _flight!.seat.isNotEmpty)
                  _buildInfoRow('Seat', _flight!.seat),
                if (_flight != null && _flight!.aircraft.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow('Aircraft', _flight!.aircraft),
                ],
                if (_flight != null && _flight!.delayTime != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow('Delay', _flight!.delayTime!),
                ],
                if (_flight != null && _flight!.transitAirport != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Transit Airport',
                    _flight!.transitAirport!,
                  ),
                  if (_flight!.transitTime != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow('Transit Time', _flight!.transitTime!),
                  ],
                ],
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

  Widget _buildTimelineCard() {
    if (_flight == null) return const SizedBox.shrink();

    final departure = _flightDetail['departure'] as Map<String, dynamic>?;
    final arrival = _flightDetail['arrival'] as Map<String, dynamic>?;
    final List<Map<String, String>> timeline = [];

    // Build timeline from actual flight data
    if (departure != null) {
      final depTime = departure['time'] as String? ?? '';
      final depDate = departure['date'] as String? ?? '';
      final depAirport = departure['airport'] as String? ?? '';
      
      if (depTime.isNotEmpty) {
        timeline.add({
          'event': 'Departure from $depAirport',
          'time': depDate.isNotEmpty ? '$depTime - $depDate' : depTime,
        });
      }
    }
    
    if (arrival != null) {
      final arrTime = arrival['time'] as String? ?? '';
      final arrDate = arrival['date'] as String? ?? '';
      final arrAirport = arrival['airport'] as String? ?? '';
      
      if (arrTime.isNotEmpty) {
        timeline.add({
          'event': 'Arrival at $arrAirport',
          'time': arrDate.isNotEmpty ? '$arrTime - $arrDate' : arrTime,
        });
      }
    }

    if (timeline.isEmpty) return const SizedBox.shrink();

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
                            Expanded(
                              child: Text(
                                item['event']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              item['time']!,
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
