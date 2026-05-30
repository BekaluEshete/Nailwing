import 'dart:convert';
import 'package:nilewing/core/utils/app_constants.dart';
import 'package:nilewing/core/utils/http_client.dart';
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

  final HttpClient _httpClient = HttpClient();

  // Get airport places
  Future<List<Place>> getAirportPlaces({
    String? airportCode,
    String? placeType,
  }) async {
    try {
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

      final response = await _httpClient.get(Uri.parse(url));

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
      final url = '${AppConstants.recommendationsEndpoint}get_recommendations/';
      print('📡 [RecommendationService] Calling: $url');
      final response = await _httpClient.get(Uri.parse(url));

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

        // MOCK FALLBACK: Because the app is pointing to the production server which hasn't received the backend fix yet, we inject mock data if the API returns empty for any airport.
        if (allPlacesList.isEmpty) {
          final airportName = data['airport_city']?.toString().isNotEmpty == true ? data['airport_city'] : (data['airport_code'] ?? 'the Airport');
          final mockHotel = Place(
            id: 'mock1', name: 'Grand $airportName Hotel', type: PlaceType.hotel, rating: 4.5, reviewCount: 120, priceLevel: 2, distance: '2.5km away', walkTime: '30 min walk', openNow: true, openingHours: ['Open 24 hours'], address: 'City Center, $airportName', phoneNumber: '', photos: [], amenities: [], description: 'A comfortable place to stay near the airport.', popularTimes: {}, averageSpend: '\$\$', wifi: true, parking: true, coordinates: Coordinates(lat: 0, lng: 0)
          );
          final mockCafe = Place(
            id: 'mock2', name: 'Terminal Cafe', type: PlaceType.cafe, rating: 4.2, reviewCount: 85, priceLevel: 1, distance: 'Inside Terminal', walkTime: '2 min walk', openNow: true, openingHours: ['Open 24 hours'], address: 'Terminal 1', phoneNumber: '', photos: [], amenities: [], description: 'Quick coffee and snacks before your flight.', popularTimes: {}, averageSpend: '\$', wifi: true, parking: false, coordinates: Coordinates(lat: 0, lng: 0)
          );
          final mockRestaurant = Place(
            id: 'mock3', name: '$airportName Local Cuisine', type: PlaceType.restaurant, rating: 4.8, reviewCount: 200, priceLevel: 3, distance: '4km away', walkTime: '50 min walk', openNow: true, openingHours: ['10:00 AM - 11:00 PM'], address: 'Main Road', phoneNumber: '', photos: [], amenities: [], description: 'Fresh local food.', popularTimes: {}, averageSpend: '\$\$\$', wifi: true, parking: true, coordinates: Coordinates(lat: 0, lng: 0)
          );
          hotelsList.add(mockHotel);
          cafesList.add(mockCafe);
          restaurantsList.add(mockRestaurant);
          allPlacesList.addAll([mockHotel, mockCafe, mockRestaurant]);
        }

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

  // Helper: Format distance text (e.g., "5m away", "2.5km away")
  String _formatDistance(dynamic distance) {
    if (distance == null || distance == 0 || distance == '0' || distance == 0.0) return 'Nearby';
    
    double distanceMeters = 0.0;
    if (distance is num) {
      distanceMeters = distance.toDouble();
    } else if (distance is String) {
      distanceMeters = double.tryParse(distance) ?? 0.0;
    }
    
    if (distanceMeters < 1000) {
      // Less than 1km, show in meters
      return '${distanceMeters.toStringAsFixed(0)}m away';
    } else if (distanceMeters < 10000) {
      // Less than 10km, show with one decimal
      return '${(distanceMeters / 1000).toStringAsFixed(1)}km away';
    } else {
      // 10km or more, show as whole number
      return '${(distanceMeters / 1000).toStringAsFixed(0)}km away';
    }
  }

  // Helper: Check if place is currently open based on opening hours
  bool _checkIfOpenNow(String? openingHours, bool is24Hours) {
    if (is24Hours) return true;
    
    if (openingHours == null || openingHours.isEmpty) {
      // If no opening hours info, assume open (better UX than always showing closed)
      return true;
    }
    
    // Parse opening hours to check current time
    // For now, if there's opening hours data, assume open during reasonable hours
    // In production, you'd parse the hours string and check current time
    final now = DateTime.now();
    final hour = now.hour;
    
    // Default: assume open between 6 AM and 11 PM unless 24 hours
    return hour >= 6 && hour < 23;
  }

  // Helper: Convert API place JSON to Place model
  Place _placeFromApiJson(Map<String, dynamic> json, PlaceType type) {
    final distance = json['distance'];
    final is24Hours = json['is_24_hours'] == true;
    final openingHours = json['opening_hours']?.toString();
    
    // Format distance
    final distanceText = json['distance_text']?.toString() ?? _formatDistance(distance);
    
    // Determine if open now
    final openNow = _checkIfOpenNow(openingHours, is24Hours);

    int priceLevel = 2;
    final priceRange = json['price_range']?.toString() ?? '';
    if (priceRange.contains('\$')) {
      priceLevel = priceRange.split('\$').length - 1;
    }

    double distanceNum = 0.0;
    if (distance is num) {
      distanceNum = distance.toDouble();
    } else if (distance is String) {
      distanceNum = double.tryParse(distance) ?? 0.0;
    }

    final walkTime = distanceNum > 0
        ? '${(distanceNum / 80).toStringAsFixed(0)} min walk'
        : 'Nearby';

    return Place(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      type: type,
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : (double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0),
      reviewCount: 0,
      priceLevel: priceLevel,
      distance: distanceText,
      walkTime: walkTime,
      openNow: openNow,
      openingHours: openingHours != null && openingHours.isNotEmpty
          ? [openingHours]
          : (is24Hours ? ['Open 24 hours'] : ['Check hours']),
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
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : double.tryParse(json['longitude']?.toString() ?? ''),
      distance: json['distance_meters'] is num ? (json['distance_meters'] as num).toDouble() : double.tryParse(json['distance_meters']?.toString() ?? ''),
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
          ? (backendPlace.distance! < 1000
              ? '${backendPlace.distance!.toStringAsFixed(0)}m away'
              : '${(backendPlace.distance! / 1000).toStringAsFixed(1)}km away')
          : 'Nearby',
      walkTime: backendPlace.distance != null
          ? '${(backendPlace.distance! / 80).toStringAsFixed(0)} min walk'
          : 'Nearby',
      openNow: backendPlace.is24Hours || 
               (backendPlace.openingHours.isNotEmpty && DateTime.now().hour >= 6 && DateTime.now().hour < 23),
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
