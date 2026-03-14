// features/home/services/flight_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nilewing/core/utils/app_constants.dart';
import 'package:nilewing/core/utils/token_storage.dart';
import '../model/home_model.dart';

class FlightService {
  static final FlightService _instance = FlightService._internal();
  factory FlightService() => _instance;
  FlightService._internal();

  final TokenStorage _tokenStorage = TokenStorage();

  Future<String?> _getAuthToken() async {
    return await _tokenStorage.getAccessToken();
  }

  // Get user's upcoming flight from backend
  Future<Flight> getUserUpcomingFlight(String userId) async {
    try {
      print('🛫 [HomeFlightService] Getting upcoming flight...');
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Get upcoming flights from backend
      final response = await http.get(
        Uri.parse(AppConstants.upcomingFlightsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 [HomeFlightService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          // Get the first upcoming flight
          final flightData = data[0] as Map<String, dynamic>;
          return _flightFromBackendJson(flightData);
        }
      }

      // If no upcoming flights, try to get current flight
      final currentResponse = await http.get(
        Uri.parse(AppConstants.currentFlightEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (currentResponse.statusCode == 200) {
        final List<dynamic> currentData = json.decode(currentResponse.body);
        if (currentData.isNotEmpty) {
          final flightData = currentData[0] as Map<String, dynamic>;
          return _flightFromBackendJson(flightData);
        }
      }

      // If still no flights, get the most recent flight
      final allFlightsResponse = await http.get(
        Uri.parse(AppConstants.flightsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (allFlightsResponse.statusCode == 200) {
        final List<dynamic> allFlights = json.decode(allFlightsResponse.body);
        if (allFlights.isNotEmpty) {
          final flightData = allFlights[0] as Map<String, dynamic>;
          return _flightFromBackendJson(flightData);
        }
      }

      throw Exception('No flights found');
    } catch (e) {
      print('❌ [HomeFlightService] Error loading flight: $e');
      // Return a fallback flight if API fails
      return _getFallbackFlight();
    }
  }

  // Convert backend flight JSON to home Flight model
  Flight _flightFromBackendJson(Map<String, dynamic> json) {
    final departureDateTime = DateTime.parse(json['departure_datetime']);
    final arrivalDateTime = DateTime.parse(json['arrival_datetime']);
    final now = DateTime.now();
    
    // Calculate duration
    final duration = arrivalDateTime.difference(departureDateTime);
    final durationHours = duration.inHours;
    final durationMinutes = duration.inMinutes % 60;
    final durationString = durationHours > 0 
        ? '${durationHours}h ${durationMinutes}m'
        : '${durationMinutes}m';

    // Calculate time until departure
    final timeUntilDeparture = departureDateTime.difference(now);
    String timeUntilDepartureString = '';
    if (timeUntilDeparture.isNegative) {
      timeUntilDepartureString = 'Departed';
    } else if (timeUntilDeparture.inDays > 0) {
      timeUntilDepartureString = '${timeUntilDeparture.inDays}d ${timeUntilDeparture.inHours % 24}h';
    } else if (timeUntilDeparture.inHours > 0) {
      timeUntilDepartureString = '${timeUntilDeparture.inHours}h ${timeUntilDeparture.inMinutes % 60}m';
    } else {
      timeUntilDepartureString = '${timeUntilDeparture.inMinutes}m';
    }

    // Format dates
    final departureDate = _formatDate(departureDateTime);
    final arrivalDate = _formatDate(arrivalDateTime);

    // Build route string
    String route = '${json['departure_airport']} → ${json['arrival_airport']}';
    if (json['has_layover'] == true && json['layover_airport'] != null) {
      route = '${json['departure_airport']} → ${json['layover_airport']} → ${json['arrival_airport']}';
    }

    // Calculate check-in and boarding times (2 hours and 1 hour before departure)
    final checkInTime = departureDateTime.subtract(const Duration(hours: 2));
    final boardingTime = departureDateTime.subtract(const Duration(hours: 1));

    return Flight(
      flightNumber: json['flight_number'] ?? 'N/A',
      airline: json['airline'] ?? 'Unknown',
      route: route,
      departure: FlightLeg(
        airport: json['departure_airport'] ?? '',
        city: json['departure_city'] ?? '',
        time: _formatTime(departureDateTime),
        date: departureDate,
        terminal: json['departure_terminal'] ?? '',
      ),
      arrival: FlightLeg(
        airport: json['arrival_airport'] ?? '',
        city: json['arrival_city'] ?? '',
        time: _formatTime(arrivalDateTime),
        date: arrivalDate,
        terminal: json['arrival_terminal'] ?? '',
      ),
      duration: durationString,
      aircraft: json['aircraft'] ?? '',
      seat: json['seat'] ?? '',
      gate: json['departure_gate'] ?? json['gate'] ?? '',
      status: _formatStatus(json['status'] ?? 'scheduled'),
      checkInTime: _formatTime(checkInTime),
      boardingTime: _formatTime(boardingTime),
      timeUntilDeparture: timeUntilDepartureString,
    );
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'On Time';
      case 'boarding':
        return 'Boarding';
      case 'delayed':
        return 'Delayed';
      case 'in_flight':
        return 'In Flight';
      case 'landed':
        return 'Landed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'On Time';
    }
  }

  // Date formatting helpers
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    if (date.year == now.year && date.month == now.month && date.day == now.day + 1) {
      return 'Tomorrow';
    }
    return '${date.month}/${date.day}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Flight _getFallbackFlight() {
    return Flight(
      flightNumber: "N/A",
      airline: "No Flight",
      route: "No upcoming flights",
      departure: FlightLeg(
        airport: "",
        city: "",
        time: "",
        date: "",
        terminal: "",
      ),
      arrival: FlightLeg(
        airport: "",
        city: "",
        time: "",
        date: "",
        terminal: "",
      ),
      duration: "",
      aircraft: "",
      seat: "",
      gate: "",
      status: "No flights",
      checkInTime: "",
      boardingTime: "",
      timeUntilDeparture: "",
    );
  }

  // Get community flight posts from backend
  Future<List<FlightPost>> getFlightPosts({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(AppConstants.communityPostsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> postsData = json.decode(response.body);
        return postsData.map((data) => FlightPost.fromJson(data as Map<String, dynamic>)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error getting community posts: $e');
      return [];
    }
  }

  // Get pre-flight matches - This is now handled by MatchService in home_view_model
  // Keeping for backward compatibility but it's not used anymore
  Future<Map<String, dynamic>> getPreFlightMatches(String userId) async {
    await Future.delayed(Duration(milliseconds: 300));
    return {
      'matchCount': 0,
      'matches': [],
      'commonRoute': 'No matches found',
    };
  }

  // Check in for flight
  Future<bool> checkInForFlight(String flightNumber, String userId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Find the flight by flight number
      final response = await http.get(
        Uri.parse(AppConstants.flightsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> flights = json.decode(response.body);
        final flight = flights.firstWhere(
          (f) => f['flight_number'] == flightNumber,
          orElse: () => null,
        );

        if (flight != null) {
          // In a real app, you would call a check-in endpoint here
          // For now, just return true
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking in: $e');
      return false;
    }
  }

  // Get flight details
  Future<Map<String, dynamic>> getFlightDetails(String flightNumber) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(AppConstants.flightsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> flights = json.decode(response.body);
        final flight = flights.firstWhere(
          (f) => f['flight_number'] == flightNumber,
          orElse: () => null,
        );

        if (flight != null) {
          return {
            'flightNumber': flight['flight_number'],
            'status': _formatStatus(flight['status'] ?? 'scheduled'),
            'gate': flight['departure_gate'] ?? flight['gate'] ?? '',
            'terminal': flight['departure_terminal'] ?? '',
            'boardingTime': flight['boarding_time'] ?? '',
            'duration': flight['duration_hours'] != null
                ? '${flight['duration_hours']}h'
                : '',
          };
        }
      }
      throw Exception('Flight not found');
    } catch (e) {
      throw Exception('Error loading flight details: $e');
    }
  }
}
