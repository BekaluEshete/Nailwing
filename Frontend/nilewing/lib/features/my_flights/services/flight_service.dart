import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nilewing/core/utils/app_constants.dart';
import 'package:nilewing/core/utils/token_storage.dart';
import '../model/flight_model.dart';

class FlightService {
  static final FlightService _instance = FlightService._internal();
  factory FlightService() => _instance;
  FlightService._internal();

  final TokenStorage _tokenStorage = TokenStorage();

  Future<String?> _getAuthToken() async {
    return await _tokenStorage.getAccessToken();
  }

  // Get all user flights
  Future<List<Flight>> getUserFlights() async {
    try {
      print('🛫 [FlightService] Getting user flights...');
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ [FlightService] No auth token found');
        throw Exception('Not authenticated');
      }

      print('📡 [FlightService] Calling: ${AppConstants.flightsEndpoint}');
      final response = await http.get(
        Uri.parse(AppConstants.flightsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 [FlightService] Response status: ${response.statusCode}');
      print('📥 [FlightService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ [FlightService] Parsed ${data.length} flights');
        final flights = data.map((json) => _flightFromJson(json)).toList();
        return flights;
      }
      print('❌ [FlightService] Failed with status: ${response.statusCode}');
      throw Exception('Failed to load flights: ${response.statusCode}');
    } catch (e) {
      print('❌ [FlightService] Error: $e');
      throw Exception('Error loading flights: $e');
    }
  }

  // Get upcoming flights
  Future<List<Flight>> getUpcomingFlights() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(AppConstants.upcomingFlightsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => _flightFromJson(json)).toList();
      }
      throw Exception('Failed to load upcoming flights: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error loading upcoming flights: $e');
    }
  }

  // Get current flight
  Future<Flight?> getCurrentFlight() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(AppConstants.currentFlightEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return _flightFromJson(data[0]);
        }
        return null;
      }
      throw Exception('Failed to load current flight: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error loading current flight: $e');
    }
  }

  // Get a single flight by ID
  Future<Flight> getFlightById(String flightId) async {
    try {
      print('🛫 [FlightService] Getting flight by ID: $flightId');
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ [FlightService] No auth token found');
        throw Exception('Not authenticated');
      }

      print('📡 [FlightService] Calling: ${AppConstants.flightsEndpoint}$flightId/');
      final response = await http.get(
        Uri.parse('${AppConstants.flightsEndpoint}$flightId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 [FlightService] Response status: ${response.statusCode}');
      print('📥 [FlightService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [FlightService] Flight loaded successfully');
        return _flightFromJson(data);
      }
      print('❌ [FlightService] Failed with status: ${response.statusCode}');
      throw Exception('Failed to load flight: ${response.statusCode}');
    } catch (e) {
      print('❌ [FlightService] Error: $e');
      throw Exception('Error loading flight: $e');
    }
  }

  // Create a new flight
  Future<Flight> createFlight(Map<String, dynamic> flightData) async {
    try {
      print('✈️ [FlightService] Creating flight...');
      print('📤 [FlightService] Flight data: $flightData');
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ [FlightService] No auth token found');
        throw Exception('Not authenticated');
      }

      print('📡 [FlightService] POST to: ${AppConstants.flightsEndpoint}');
      final response = await http.post(
        Uri.parse(AppConstants.flightsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(flightData),
      );

      print('📥 [FlightService] Response status: ${response.statusCode}');
      print('📥 [FlightService] Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [FlightService] Flight created successfully');
        return _flightFromJson(data);
      } else {
        final errorData = json.decode(response.body);
        print('❌ [FlightService] Error: ${errorData['message'] ?? 'Unknown error'}');
        throw Exception(errorData['message'] ?? 'Failed to create flight');
      }
    } catch (e) {
      print('❌ [FlightService] Error creating flight: $e');
      throw Exception('Error creating flight: $e');
    }
  }

  // Update flight
  Future<Flight> updateFlight(String flightId, Map<String, dynamic> flightData) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.patch(
        Uri.parse('${AppConstants.flightsEndpoint}$flightId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(flightData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _flightFromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update flight');
      }
    } catch (e) {
      throw Exception('Error updating flight: $e');
    }
  }

  // Update flight status
  Future<Flight> updateFlightStatus(String flightId, String status, {int? delayMinutes}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.patch(
        Uri.parse('${AppConstants.flightsEndpoint}$flightId/update_status/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': status,
          if (delayMinutes != null) 'delay_minutes': delayMinutes,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _flightFromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update flight status');
      }
    } catch (e) {
      throw Exception('Error updating flight status: $e');
    }
  }

  // Add user interest
  Future<void> addInterest(String interest) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse(AppConstants.interestsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'interest': interest}),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to add interest');
      }
    } catch (e) {
      throw Exception('Error adding interest: $e');
    }
  }

  // Get user interests
  Future<List<String>> getUserInterests() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse(AppConstants.interestsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item['interest'] as String).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Cancel flight
  Future<bool> cancelFlight(String flightId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${AppConstants.flightsEndpoint}$flightId/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      throw Exception('Error cancelling flight: $e');
    }
  }

  // Update flight delay
  Future<bool> updateFlightDelay(String flightId, DelayFormData delayData) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.patch(
        Uri.parse('${AppConstants.flightsEndpoint}$flightId/update_status/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': 'delayed',
          'delay_minutes': delayData.delayDuration.isNotEmpty
              ? int.tryParse(delayData.delayDuration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0
              : 0,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating flight delay: $e');
    }
  }

  // Delete interest
  Future<void> deleteInterest(String interestId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${AppConstants.interestsEndpoint}$interestId/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete interest');
      }
    } catch (e) {
      throw Exception('Error deleting interest: $e');
    }
  }

  // Get travel preferences
  Future<Map<String, dynamic>> getTravelPreferences() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConstants.preferencesEndpoint}my_preferences/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // Update travel preferences
  Future<Map<String, dynamic>> updateTravelPreferences(Map<String, dynamic> preferences) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('${AppConstants.preferencesEndpoint}my_preferences/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(preferences),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update preferences');
      }
    } catch (e) {
      throw Exception('Error updating preferences: $e');
    }
  }

  // Helper: Convert JSON to Flight model
  Flight _flightFromJson(Map<String, dynamic> json) {
    // Determine status - check if flight is past and update accordingly
    String? status = json['status'];
    final arrivalDatetime = json['arrival_datetime'];
    
    // If arrival has passed and status is still upcoming/boarding, mark as completed
    if (_isFlightPast(arrivalDatetime) && 
        status != null && 
        ['scheduled', 'boarding', 'delayed'].contains(status.toLowerCase())) {
      status = 'landed';
    }
    
    return Flight(
      id: json['id'].toString(),
      flightNumber: json['flight_number'] ?? '',
      airline: json['airline'] ?? '',
      route: json['route'] ?? '',
      departure: FlightLeg(
        airport: json['departure_airport'] ?? '',
        city: json['departure_city'] ?? '',
        time: _formatTime(json['departure_datetime']),
        date: _formatDate(json['departure_datetime']),
        terminal: json['departure_terminal'] ?? '',
      ),
      arrival: FlightLeg(
        airport: json['arrival_airport'] ?? '',
        city: json['arrival_city'] ?? '',
        time: _formatTime(json['arrival_datetime']),
        date: _formatDate(json['arrival_datetime']),
        terminal: json['arrival_terminal'] ?? '',
      ),
      duration: json['duration_hours'] != null 
          ? _formatDuration(json['duration_hours'])
          : '',
      aircraft: json['aircraft'] ?? '',
      seat: json['seat'] ?? '',
      gate: json['departure_gate'] ?? '',
      status: _parseFlightStatus(status),
      delayTime: json['delay_minutes'] != null && json['delay_minutes'] > 0
          ? '${json['delay_minutes']} min'
          : null,
      transitTime: json['layover_duration_hours'] != null
          ? '${json['layover_duration_hours'].toStringAsFixed(1)}h'
          : null,
      transitAirport: json['layover_airport'],
      rating: null,
      postTitle: null,
      postContent: null,
      likes: 0,
      comments: 0,
      hasPost: false,
      isVisible: json['is_visible'] ?? true,
    );
  }
  
  String _formatDuration(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m > 0) {
      return '${h}h ${m}m';
    }
    return '${h}h';
  }

  String _formatTime(String? datetimeStr) {
    if (datetimeStr == null) return '';
    try {
      final dt = DateTime.parse(datetimeStr);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  String _formatDate(String? datetimeStr) {
    if (datetimeStr == null) return '';
    try {
      final dt = DateTime.parse(datetimeStr);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'Today';
      } else if (dt.year == now.year && dt.month == now.month && dt.day == now.day + 1) {
        return 'Tomorrow';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return '';
    }
  }

  FlightStatus _parseFlightStatus(String? status) {
    if (status == null) return FlightStatus.upcoming;
    
    switch (status.toLowerCase()) {
      case 'scheduled':
        return FlightStatus.upcoming;
      case 'boarding':
        return FlightStatus.boarding;
      case 'delayed':
        return FlightStatus.delayed;
      case 'in_flight':
      case 'landed':
        return FlightStatus.completed;
      case 'cancelled':
        return FlightStatus.cancelled;
      default:
        return FlightStatus.upcoming;
    }
  }
  
  // Helper to determine if flight is past based on datetime
  bool _isFlightPast(String? arrivalDatetime) {
    if (arrivalDatetime == null) return false;
    try {
      final arrival = DateTime.parse(arrivalDatetime);
      return arrival.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }
}
