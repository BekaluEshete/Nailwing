// features/my_flights/viewmodels/my_flights_view_model.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/flight_model.dart';
import '../services/flight_service.dart';

final myFlightsViewModelProvider = ChangeNotifierProvider<MyFlightsViewModel>(
  (ref) => MyFlightsViewModel(),
);

class MyFlightsViewModel with ChangeNotifier {
  final MyFlightsService _service = MyFlightsService();

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
      _flights = await _service.getUserFlights("current_user_id");
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
      // Add to local state immediately for better UX
      _flights.insert(0, newFlight);
      notifyListeners();

      // TODO: Implement API call to save flight
      // await _service.addFlight(newFlight);
    } catch (e) {
      // Remove from local state if API call fails
      _flights.remove(newFlight);
      notifyListeners();
      rethrow;
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
