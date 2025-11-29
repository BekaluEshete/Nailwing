import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nilewing/core/utils/app_constants.dart';
import 'package:nilewing/core/utils/token_storage.dart';
import '../model/recommendation_model.dart';

// Backend Place model (simplified)
class _BackendPlace {
  final String id;
  final String name;
  final String type;
  final String airportCode;
  final String terminal;
  final String description;
  final double rating;
  final String priceRange;
  final String openingHours;
  final bool is24Hours;
  final double? latitude;
  final double? longitude;
  final double? distance;

  _BackendPlace({
    required this.id,
    required this.name,
    required this.type,
    required this.airportCode,
    required this.terminal,
    required this.description,
    required this.rating,
    required this.priceRange,
    required this.openingHours,
    required this.is24Hours,
    this.latitude,
    this.longitude,
    this.distance,
  });
}

// Backend Recommendation model
class _BackendRecommendation {
  final String id;
  final _BackendPlace place;
  final String reason;
  final double? distance;
  final bool isViewed;

  _BackendRecommendation({
    required this.id,
    required this.place,
    required this.reason,
    this.distance,
    required this.isViewed,
  });
}

class RecommendationService {
  static final RecommendationService _instance = RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  final TokenStorage _tokenStorage = TokenStorage();

  Future<String?> _getAuthToken() async {
    return await _tokenStorage.getAccessToken();
  }

  // Get airport places
  Future<List<Place>> getAirportPlaces({
    String? airportCode,
    String? placeType,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      String url = AppConstants.placesEndpoint;
      final queryParams = <String>[];
      if (airportCode != null) {
        queryParams.add('airport=$airportCode');
      }
      if (placeType != null) {
        queryParams.add('type=$placeType');
      }
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => _placeFromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get personalized recommendations (returns Places, not Recommendations)
  Future<List<Place>> getRecommendations() async {
    try {
      print('📍 [RecommendationService] Getting recommendations...');
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ [RecommendationService] No auth token found');
        throw Exception('Not authenticated');
      }

      final url = '${AppConstants.recommendationsEndpoint}get_recommendations/';
      print('📡 [RecommendationService] Calling: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 [RecommendationService] Response status: ${response.statusCode}');
      print('📥 [RecommendationService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ [RecommendationService] Found ${data.length} recommendations');
        final places = data.map((json) {
          final rec = _recommendationFromJson(json);
          return _recommendationToPlace(rec);
        }).toList();
        return places;
      }
      print('⚠️ [RecommendationService] No recommendations (status: ${response.statusCode})');
      return [];
    } catch (e) {
      print('❌ [RecommendationService] Error: $e');
      return [];
    }
  }

  // Get places by type
  Future<List<Place>> getRestaurants(String airportCode) async {
    return getAirportPlaces(airportCode: airportCode, placeType: 'restaurant');
  }

  Future<List<Place>> getCafes(String airportCode) async {
    return getAirportPlaces(airportCode: airportCode, placeType: 'cafe');
  }

  Future<List<Place>> getLounges(String airportCode) async {
    return getAirportPlaces(airportCode: airportCode, placeType: 'lounge');
  }

  Future<List<Place>> getChargingStations(String airportCode) async {
    return getAirportPlaces(airportCode: airportCode, placeType: 'charging_station');
  }

  // Helper: Convert JSON to backend Place model
  _BackendPlace _backendPlaceFromJson(Map<String, dynamic> json) {
    return _BackendPlace(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      airportCode: json['airport_code'] ?? '',
      terminal: json['terminal'] ?? '',
      description: json['description'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      priceRange: json['price_range'] ?? '',
      openingHours: json['opening_hours'] ?? '',
      is24Hours: json['is_24_hours'] ?? false,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      distance: json['distance_meters']?.toDouble(),
    );
  }

  // Helper: Convert backend Place to frontend Place
  Place _placeFromBackend(_BackendPlace backendPlace) {
    PlaceType placeType = PlaceType.cafe;
    switch (backendPlace.type) {
      case 'restaurant':
        placeType = PlaceType.restaurant;
        break;
      case 'cafe':
        placeType = PlaceType.cafe;
        break;
      case 'lounge':
      case 'hotel':
        placeType = PlaceType.hotel;
        break;
      default:
        placeType = PlaceType.cafe;
    }

    int priceLevel = 2;
    if (backendPlace.priceRange.contains('\$')) {
      priceLevel = backendPlace.priceRange.split('\$').length - 1;
    }

    return Place(
      id: backendPlace.id,
      name: backendPlace.name,
      type: placeType,
      rating: backendPlace.rating,
      reviewCount: 0,
      priceLevel: priceLevel,
      distance: backendPlace.distance != null
          ? '${(backendPlace.distance! / 1000).toStringAsFixed(1)} km'
          : 'Nearby',
      walkTime: backendPlace.distance != null
          ? '${(backendPlace.distance! / 80).toStringAsFixed(0)} min walk'
          : 'Nearby',
      openNow: backendPlace.is24Hours || true,
      openingHours: backendPlace.openingHours.isNotEmpty
          ? [backendPlace.openingHours]
          : ['Open 24 hours'],
      address: '${backendPlace.terminal.isNotEmpty ? 'Terminal ${backendPlace.terminal}, ' : ''}${backendPlace.airportCode} Airport',
      phoneNumber: '',
      website: null,
      photos: [],
      amenities: [],
      description: backendPlace.description,
      popularTimes: {},
      averageSpend: backendPlace.priceRange.isNotEmpty ? backendPlace.priceRange : 'Varies',
      specialties: null,
      roomPrice: null,
      wifi: true,
      parking: false,
      coordinates: backendPlace.latitude != null && backendPlace.longitude != null
          ? Coordinates(lat: backendPlace.latitude!, lng: backendPlace.longitude!)
          : Coordinates(lat: 0, lng: 0),
    );
  }

  // Helper: Convert JSON to Place model (for direct places endpoint)
  Place _placeFromJson(Map<String, dynamic> json) {
    final backendPlace = _backendPlaceFromJson(json);
    return _placeFromBackend(backendPlace);
  }

  // Helper: Convert JSON to Recommendation model
  _BackendRecommendation _recommendationFromJson(Map<String, dynamic> json) {
    final placeData = json['place'] ?? {};
    return _BackendRecommendation(
      id: json['id'].toString(),
      place: _backendPlaceFromJson(placeData),
      reason: json['reason'] ?? '',
      distance: json['distance_meters']?.toDouble(),
      isViewed: json['is_viewed'] ?? false,
    );
  }

  // Convert backend recommendation to frontend Place
  Place _recommendationToPlace(_BackendRecommendation rec) {
    return _placeFromBackend(rec.place);
  }
}
