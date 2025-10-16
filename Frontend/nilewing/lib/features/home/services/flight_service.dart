// services/flight_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nilewing/features/home/model/home_model.dart';

class FlightService {
  static final FlightService _instance = FlightService._internal();
  factory FlightService() => _instance;
  FlightService._internal();

  static const String baseUrl =
      'https://your-api-domain.com/api'; // Replace with your API

  // Get user's upcoming flights
  Future<List<Flight>> getUpcomingFlights(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/flights/upcoming'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((flight) => Flight.fromJson(flight)).toList();
      } else {
        throw Exception(
          'Failed to load upcoming flights: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Return mock data for demo
      return getMockUpcomingFlights();
    }
  }

  // Get flight posts from community
  Future<List<FlightPost>> getFlightPosts({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/flight-posts?page=$page&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((post) => FlightPost.fromJson(post)).toList();
      } else {
        throw Exception('Failed to load flight posts: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for demo
      return getMockFlightPosts();
    }
  }

  // Get flight recommendations
  Future<List<FlightRecommendation>> getFlightRecommendations(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/recommendations'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((rec) => FlightRecommendation.fromJson(rec)).toList();
      } else {
        throw Exception(
          'Failed to load recommendations: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Return mock data for demo
      return getMockRecommendations();
    }
  }

  // Get user flight statistics
  Future<UserFlightStats> getUserFlightStats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserFlightStats.fromJson(data);
      } else {
        throw Exception('Failed to load user stats: ${response.statusCode}');
      }
    } catch (e) {
      // Return mock data for demo
      return getMockUserStats();
    }
  }

  // Add a new flight
  Future<void> addFlight(String userId, Map<String, dynamic> flightData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/flights'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(flightData),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add flight: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add flight: $e');
    }
  }

  // Mock data methods
  List<Flight> getMockUpcomingFlights() {
    return [
      Flight(
        id: 'ET302',
        airline: 'Ethiopian Airlines',
        flightNumber: 'ET302',
        departure: FlightLeg(
          airport: 'ADD',
          city: 'Addis Ababa',
          time: '23:35',
          date: 'Today',
          terminal: 'T2',
          gate: 'B7',
        ),
        arrival: FlightLeg(
          airport: 'CDG',
          city: 'Paris',
          time: '06:50+1',
          date: 'Tomorrow',
        ),
        seat: '12A',
        seatType: 'Window',
        status: 'Scheduled',
        departureIn: '5h 23m',
      ),
    ];
  }

  List<FlightPost> getMockFlightPosts() {
    return [
      FlightPost(
        id: 1,
        user: "Sarah M.",
        avatar: null,
        flight: "LH440",
        route: "FRA → JFK",
        time: "2h ago",
        likes: 24,
        title: "Amazing sunset over the Atlantic!",
        preview:
            "Just caught the most incredible sunset on my way to New York...",
      ),
      FlightPost(
        id: 2,
        user: "Ahmed K.",
        avatar: null,
        flight: "EK203",
        route: "DXB → LHR",
        time: "5h ago",
        likes: 18,
        title: "Business class experience review",
        preview:
            "The Emirates A380 business class exceeded all expectations...",
      ),
    ];
  }

  List<FlightRecommendation> getMockRecommendations() {
    return [
      FlightRecommendation(
        id: 1,
        type: 'destination',
        title: 'Bali, Indonesia',
        subtitle: 'Perfect beach getaway',
        imageUrl: null,
        matchScore: 85,
        reason: 'Based on your love for tropical destinations',
      ),
      FlightRecommendation(
        id: 2,
        type: 'flight_deal',
        title: 'Tokyo Flight Deal',
        subtitle: 'Save 30% on round trip',
        imageUrl: null,
        matchScore: 78,
        reason: 'Great price for your preferred dates',
      ),
    ];
  }

  UserFlightStats getMockUserStats() {
    return UserFlightStats(
      totalFlights: 12,
      countriesVisited: 8,
      storiesPosted: 24,
      milesFlown: 45000,
      favoriteAirlines: ['Ethiopian Airlines', 'Emirates', 'Qatar Airways'],
    );
  }
}
