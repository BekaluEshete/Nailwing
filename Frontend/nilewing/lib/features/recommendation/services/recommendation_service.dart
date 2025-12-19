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

class RecommendationService {
  static final RecommendationService _instance =
      RecommendationService._internal();
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

  // Get comprehensive recommendations (hotels, cafes, restaurants, people)
  Future<Map<String, dynamic>> getRecommendations() async {
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

      print(
        '📥 [RecommendationService] Response status: ${response.statusCode}',
      );
      print('📥 [RecommendationService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('✅ [RecommendationService] Recommendations loaded successfully');

        // Parse all categories
        final hotelsList = (data['hotels'] as List<dynamic>? ?? [])
            .map(
              (json) => _placeFromApiJson(
                json as Map<String, dynamic>,
                PlaceType.hotel,
              ),
            )
            .toList();
        final cafesList = (data['cafes'] as List<dynamic>? ?? [])
            .map(
              (json) => _placeFromApiJson(
                json as Map<String, dynamic>,
                PlaceType.cafe,
              ),
            )
            .toList();
        final restaurantsList = (data['restaurants'] as List<dynamic>? ?? [])
            .map(
              (json) => _placeFromApiJson(
                json as Map<String, dynamic>,
                PlaceType.restaurant,
              ),
            )
            .toList();

        // Combine all places
        final allPlacesList = <Place>[
          ...hotelsList,
          ...cafesList,
          ...restaurantsList,
        ];

        return {
          'hotels': hotelsList,
          'cafes': cafesList,
          'restaurants': restaurantsList,
          'allPlaces': allPlacesList,
          'people': data['people'] ?? [],
          'airportCode': data['airport_code']?.toString() ?? '',
          'airportCity': data['airport_city']?.toString() ?? '',
          'flightInfo': data['flight_info'] ?? {},
        };
      }

      if (response.statusCode == 404) {
        final data = json.decode(response.body);
        print(
          '⚠️ [RecommendationService] ${data['message'] ?? 'No recommendations'}',
        );
        return {
          'hotels': <Place>[],
          'cafes': <Place>[],
          'restaurants': <Place>[],
          'allPlaces': <Place>[],
          'people': <Map<String, dynamic>>[],
          'airportCode': '',
          'airportCity': '',
          'flightInfo': {},
        };
      }

      print(
        '⚠️ [RecommendationService] Failed with status: ${response.statusCode}',
      );
      throw Exception('Failed to load recommendations: ${response.statusCode}');
    } catch (e) {
      print('❌ [RecommendationService] Error: $e');
      rethrow;
    }
  }

  // Helper: Convert API place JSON to Place model
  Place _placeFromApiJson(Map<String, dynamic> json, PlaceType type) {
    final distance = json['distance'] ?? 0;
    final distanceText =
        json['distance_text'] ??
        (distance > 0
            ? '${(distance / 1000).toStringAsFixed(1)} km'
            : 'Nearby');

    int priceLevel = 2;
    final priceRange = json['price_range']?.toString() ?? '';
    if (priceRange.contains('\$')) {
      priceLevel = priceRange.split('\$').length - 1;
    }

    return Place(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      type: type,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: 0,
      priceLevel: priceLevel,
      distance: distanceText,
      walkTime: distance > 0
          ? '${(distance / 80).toStringAsFixed(0)} min walk'
          : 'Nearby',
      openNow: json['is_24_hours'] ?? true,
      openingHours: json['opening_hours']?.toString().isNotEmpty == true
          ? [json['opening_hours'].toString()]
          : ['Open 24 hours'],
      address: json['address']?.toString() ?? '',
      phoneNumber: '',
      website: null,
      photos: (json['photos'] as List<dynamic>? ?? [])
          .map((p) => p.toString())
          .toList(),
      amenities: [],
      description: json['description']?.toString() ?? '',
      popularTimes: {},
      averageSpend: priceRange.isNotEmpty ? priceRange : 'Varies',
      specialties: null,
      roomPrice: null,
      wifi: true,
      parking: false,
      coordinates: Coordinates(
        lat: (json['latitude'] ?? 0.0).toDouble(),
        lng: (json['longitude'] ?? 0.0).toDouble(),
      ),
    );
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
    return getAirportPlaces(
      airportCode: airportCode,
      placeType: 'charging_station',
    );
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
      address:
          '${backendPlace.terminal.isNotEmpty ? 'Terminal ${backendPlace.terminal}, ' : ''}${backendPlace.airportCode} Airport',
      phoneNumber: '',
      website: null,
      photos: [],
      amenities: [],
      description: backendPlace.description,
      popularTimes: {},
      averageSpend: backendPlace.priceRange.isNotEmpty
          ? backendPlace.priceRange
          : 'Varies',
      specialties: null,
      roomPrice: null,
      wifi: true,
      parking: false,
      coordinates:
          backendPlace.latitude != null && backendPlace.longitude != null
          ? Coordinates(
              lat: backendPlace.latitude!,
              lng: backendPlace.longitude!,
            )
          : Coordinates(lat: 0, lng: 0),
    );
  }

  // Helper: Convert JSON to Place model (for direct places endpoint)
  Place _placeFromJson(Map<String, dynamic> json) {
    final backendPlace = _backendPlaceFromJson(json);
    return _placeFromBackend(backendPlace);
  }
}
