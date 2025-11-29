// features/my_flights/viewmodels/my_flights_view_model.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/flight_model.dart';
import '../services/flight_service.dart';

final myFlightsViewModelProvider = ChangeNotifierProvider<MyFlightsViewModel>(
  (ref) => MyFlightsViewModel(),
);

class MyFlightsViewModel with ChangeNotifier {
  final FlightService _service = FlightService();

  List<Flight> _flights = [];
  bool _isLoading = false;
  String? _selectedFlightId;
  DelayFormData _delayForm = DelayFormData();

  List<Flight> get flights => _flights;
  bool get isLoading => _isLoading;
  String? get selectedFlightId => _selectedFlightId;
  DelayFormData get delayForm => _delayForm;

  List<Flight> get upcomingFlights => _flights
      .where(
        (f) =>
            f.isVisible &&
            (f.status == FlightStatus.upcoming ||
                f.status == FlightStatus.boarding ||
                f.status == FlightStatus.delayed),
      )
      .toList();

  List<Flight> get pastFlights => _flights
      .where((f) => f.isVisible && f.status == FlightStatus.completed)
      .toList();

  List<Flight> get cancelledFlights =>
      _flights.where((f) => f.status == FlightStatus.cancelled).toList();

  Future<void> loadFlights() async {
    _isLoading = true;
    notifyListeners();

    try {
      _flights = await _service.getUserFlights();
    } catch (e) {
      print('Error loading flights: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelFlight(String flightId) async {
    try {
      final success = await _service.cancelFlight(flightId);
      if (success) {
        // Update local state
        final index = _flights.indexWhere((f) => f.id == flightId);
        if (index != -1) {
          _flights[index] = _flights[index].copyWith(
            status: FlightStatus.cancelled,
            isVisible: false,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error cancelling flight: $e');
      rethrow;
    }
  }

  // Add this method to your existing MyFlightsViewModel
  Future<void> addFlight(Flight newFlight) async {
    try {
      print('✈️ [FlightViewModel] Adding flight: ${newFlight.flightNumber}');
      
      // Convert Flight to backend format
      final flightData = _convertFlightToBackendFormat(newFlight);
      print('📤 [FlightViewModel] Flight data: $flightData');
      
      // Call API to create flight
      final createdFlight = await _service.createFlight(flightData);
      print('✅ [FlightViewModel] Flight created: ${createdFlight.id}');
      
      // Add to local state
      _flights.insert(0, createdFlight);
      notifyListeners();
    } catch (e) {
      print('❌ [FlightViewModel] Error adding flight: $e');
      rethrow;
    }
  }

  // Helper: Convert frontend Flight to backend format
  Map<String, dynamic> _convertFlightToBackendFormat(Flight flight) {
    // Parse departure datetime
    final departureDateTime = _parseDateTime(
      flight.departure.date,
      flight.departure.time,
    );
    
    // Parse arrival datetime
    final arrivalDateTime = _parseDateTime(
      flight.arrival.date,
      flight.arrival.time,
    );
    
    final flightData = <String, dynamic>{
      'flight_number': flight.flightNumber,
      'airline': flight.airline,
      'departure_airport': flight.departure.airport,
      'departure_city': flight.departure.city,
      'departure_terminal': flight.departure.terminal,
      'departure_datetime': departureDateTime.toIso8601String(),
      'arrival_airport': flight.arrival.airport,
      'arrival_city': flight.arrival.city,
      'arrival_terminal': flight.arrival.terminal,
      'arrival_datetime': arrivalDateTime.toIso8601String(),
      'aircraft': flight.aircraft,
      'seat': flight.seat,
      'departure_gate': flight.gate,
      'status': _convertStatusToBackend(flight.status),
      'is_visible': flight.isVisible,
      'looking_for_company': false,
      'open_to_meeting': true,
    };
    
    // Add layover info if exists
    if (flight.transitAirport != null && flight.transitAirport!.isNotEmpty) {
      flightData['has_layover'] = true;
      flightData['layover_airport'] = flight.transitAirport;
      // Calculate layover times (simplified - you may need to adjust)
      if (departureDateTime.isBefore(arrivalDateTime)) {
        final layoverStart = departureDateTime.add(Duration(hours: 1));
        final layoverEnd = arrivalDateTime.subtract(Duration(hours: 1));
        flightData['layover_start'] = layoverStart.toIso8601String();
        flightData['layover_end'] = layoverEnd.toIso8601String();
      }
    } else {
      flightData['has_layover'] = false;
    }
    
    return flightData;
  }

  DateTime _parseDateTime(String dateStr, String timeStr) {
    try {
      // Try to parse date
      DateTime date;
      if (dateStr.toLowerCase() == 'today') {
        date = DateTime.now();
      } else if (dateStr.toLowerCase() == 'tomorrow') {
        date = DateTime.now().add(Duration(days: 1));
      } else {
        // Try to parse date string (mm/dd/yyyy or similar)
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          date = DateTime(
            int.parse(parts[2]),
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        } else {
          date = DateTime.now();
        }
      }
      
      // Parse time
      final timeParts = timeStr.split(':');
      if (timeParts.length == 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        return DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );
      }
      
      return date;
    } catch (e) {
      print('⚠️ [FlightViewModel] Error parsing datetime: $e');
      return DateTime.now();
    }
  }

  String _convertStatusToBackend(FlightStatus status) {
    switch (status) {
      case FlightStatus.upcoming:
        return 'scheduled';
      case FlightStatus.boarding:
        return 'boarding';
      case FlightStatus.delayed:
        return 'delayed';
      case FlightStatus.completed:
        return 'landed';
      case FlightStatus.cancelled:
        return 'cancelled';
    }
  }

  Future<void> updateFlightDelay(String flightId) async {
    try {
      final success = await _service.updateFlightDelay(flightId, _delayForm);
      if (success) {
        // Update local state
        final index = _flights.indexWhere((f) => f.id == flightId);
        if (index != -1) {
          _flights[index] = _flights[index].copyWith(
            status: FlightStatus.delayed,
            delayTime: _delayForm.delayDuration,
          );
          _delayForm = DelayFormData(); // Reset form
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error updating flight delay: $e');
      rethrow;
    }
  }

  void setSelectedFlight(String flightId) {
    _selectedFlightId = flightId;
    notifyListeners();
  }

  void updateDelayForm(DelayFormData newForm) {
    _delayForm = newForm;
    notifyListeners();
  }

  void resetDelayForm() {
    _delayForm = DelayFormData();
    notifyListeners();
  }
}

// Extension for copying Flight objects
extension FlightCopyWith on Flight {
  Flight copyWith({
    String? id,
    String? flightNumber,
    String? airline,
    String? route,
    FlightLeg? departure,
    FlightLeg? arrival,
    String? duration,
    String? aircraft,
    String? seat,
    String? gate,
    FlightStatus? status,
    String? delayTime,
    String? transitTime,
    String? transitAirport,
    int? rating,
    String? postTitle,
    String? postContent,
    int? likes,
    int? comments,
    bool? hasPost,
    bool? isVisible,
  }) {
    return Flight(
      id: id ?? this.id,
      flightNumber: flightNumber ?? this.flightNumber,
      airline: airline ?? this.airline,
      route: route ?? this.route,
      departure: departure ?? this.departure,
      arrival: arrival ?? this.arrival,
      duration: duration ?? this.duration,
      aircraft: aircraft ?? this.aircraft,
      seat: seat ?? this.seat,
      gate: gate ?? this.gate,
      status: status ?? this.status,
      delayTime: delayTime ?? this.delayTime,
      transitTime: transitTime ?? this.transitTime,
      transitAirport: transitAirport ?? this.transitAirport,
      rating: rating ?? this.rating,
      postTitle: postTitle ?? this.postTitle,
      postContent: postContent ?? this.postContent,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      hasPost: hasPost ?? this.hasPost,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
