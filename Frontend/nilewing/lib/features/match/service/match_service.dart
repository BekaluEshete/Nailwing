import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nilewing/core/utils/app_constants.dart';
import 'package:nilewing/core/utils/token_storage.dart';
import 'package:nilewing/core/utils/http_client.dart';
import '../model/match_model.dart';

class MatchService {
  static final MatchService _instance = MatchService._internal();
  factory MatchService() => _instance;
  MatchService._internal();

  final TokenStorage _tokenStorage = TokenStorage();
  final HttpClient _httpClient = HttpClient();

  Future<String?> _getAuthToken() async {
    return await _tokenStorage.getAccessToken();
  }

  // Find new matches
  Future<List<Match>> findMatches({String? flightId}) async {
    try {
      print('🔍 [MatchService] Finding matches...');
      if (flightId != null) {
        print('🔍 [MatchService] For flight ID: $flightId');
      }
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ [MatchService] No auth token found');
        throw Exception('Not authenticated');
      }

      String url = AppConstants.findMatchesEndpoint;
      if (flightId != null) {
        url += '?flight_id=$flightId';
      }

      print('📡 [MatchService] Calling: $url');
      final response = await _httpClient.get(Uri.parse(url));

      print('📥 [MatchService] Response status: ${response.statusCode}');
      print('📥 [MatchService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Handle new response format with debug info
        List<dynamic> matchesData;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('matches')) {
            matchesData = responseData['matches'] as List<dynamic>? ?? [];
            // Log debug info if available
            if (responseData.containsKey('message')) {
              print('ℹ️ [MatchService] ${responseData['message']}');
            }
            if (responseData.containsKey('debug')) {
              final debug = responseData['debug'] as Map<String, dynamic>?;
              if (debug != null) {
                print('🔍 [MatchService] Debug info:');
                debug.forEach((key, value) {
                  print('   $key: $value');
                });
              }
            }
          } else {
            // Old format - direct array
            matchesData = responseData as List<dynamic>;
          }
        } else {
          // Old format - direct array
          matchesData = responseData as List<dynamic>;
        }
        
        print('✅ [MatchService] Found ${matchesData.length} matches');
        final matches = matchesData.map((json) => _matchFromJson(json)).toList();
        return matches;
      }
      print('❌ [MatchService] Failed with status: ${response.statusCode}');
      throw Exception('Failed to find matches: ${response.statusCode}');
    } catch (e) {
      print('❌ [MatchService] Error finding matches: $e');
      throw Exception('Error finding matches: $e');
    }
  }

  // Get user's matches
  Future<List<Match>> getUserMatches() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConstants.matchesEndpoint}/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => _matchFromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Like a match
  Future<Match> likeMatch(String matchId) async {
    try {
      print('❤️ [MatchService] Liking match: $matchId');
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ [MatchService] No auth token found');
        throw Exception('Not authenticated');
      }

      final url = '${AppConstants.matchesEndpoint}/$matchId/like/';
      print('📡 [MatchService] POST to: $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 [MatchService] Response status: ${response.statusCode}');
      print('📥 [MatchService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [MatchService] Match liked successfully');
        return _matchFromJson(data);
      } else {
        final errorData = json.decode(response.body);
        print(
          '❌ [MatchService] Error: ${errorData['error'] ?? 'Unknown error'}',
        );
        throw Exception(errorData['error'] ?? 'Failed to like match');
      }
    } catch (e) {
      print('❌ [MatchService] Error liking match: $e');
      throw Exception('Error liking match: $e');
    }
  }

  // Reject a match
  Future<void> rejectMatch(String matchId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConstants.matchesEndpoint}/$matchId/reject/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reject match');
      }
    } catch (e) {
      throw Exception('Error rejecting match: $e');
    }
  }

  // View a match (mark as viewed)
  Future<void> viewMatch(String matchId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConstants.matchesEndpoint}/$matchId/view/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        // Not critical, just log
        print('Failed to mark match as viewed');
      }
    } catch (e) {
      // Not critical, just log
      print('Error viewing match: $e');
    }
  }

  // Get match filters
  Future<Map<String, dynamic>> getMatchFilters() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConstants.matchFiltersEndpoint}/my_filters/'),
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

  // Update match filters
  Future<Map<String, dynamic>> updateMatchFilters(
    Map<String, dynamic> filters,
  ) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.put(
        Uri.parse('${AppConstants.matchFiltersEndpoint}/my_filters/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(filters),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update filters');
      }
    } catch (e) {
      throw Exception('Error updating filters: $e');
    }
  }

  // Helper: Convert JSON to Match model
  Match _matchFromJson(Map<String, dynamic> json) {
    final user2Data = json['user2_data'] ?? {};
    final flight2Data = json['flight2_data'];

    // Determine which user is the "other" user (not current user)
    // For now, assume user2 is the match
    final otherUserData = user2Data;
    final otherFlightData = flight2Data;

    // Parse match type
    final matchTypeStr = json['match_type'] ?? '';
    MatchType matchType = MatchType.sameRoute;
    if (matchTypeStr.contains('layover')) {
      matchType = MatchType.sameLayover;
    } else if (matchTypeStr.contains('departure')) {
      matchType = MatchType.departureMatch;
    } else if (matchTypeStr.contains('destination')) {
      matchType = MatchType.destinationMatch;
    }

    // Build flight info
    FlightInfo? flightInfo;
    if (otherFlightData != null) {
      flightInfo = FlightInfo(
        departure: otherFlightData['departure_airport'] ?? '',
        departureCity: otherFlightData['departure_city'] ?? '',
        arrival: otherFlightData['arrival_airport'] ?? '',
        arrivalCity: otherFlightData['arrival_city'] ?? '',
        layover: otherFlightData['layover_airport'],
        layoverCity: otherFlightData['layover_city'],
        airline: otherFlightData['airline'] ?? '',
        flightNumber: otherFlightData['flight_number'] ?? '',
        departureTime: otherFlightData['departure_datetime'] != null
            ? DateTime.parse(otherFlightData['departure_datetime'])
            : DateTime.now(),
        arrivalTime: otherFlightData['arrival_datetime'] != null
            ? DateTime.parse(otherFlightData['arrival_datetime'])
            : DateTime.now(),
        duration: otherFlightData['duration_hours'] != null
            ? '${otherFlightData['duration_hours'].toStringAsFixed(1)}h'
            : '',
        gate: otherFlightData['departure_gate'],
        tripPurpose: null,
      );
    }

    // Calculate compatibility score (0-100)
    final matchScore = json['match_score']?.toDouble() ?? 0.0;
    final compatibility = (matchScore * 20).clamp(0, 100).toInt();

    // Build description
    final overlapHours = json['overlap_duration_hours']?.toDouble() ?? 0.0;
    final matchingAirport = json['matching_airport'] ?? '';
    String description = '';
    if (matchType == MatchType.sameLayover) {
      description =
          'Same layover at $matchingAirport - ${overlapHours.toStringAsFixed(1)}h overlap';
    } else if (matchType == MatchType.sameRoute) {
      description =
          'Same route - Perfect for meeting during layover or sharing transport!';
    } else {
      description =
          'Match at $matchingAirport - ${overlapHours.toStringAsFixed(1)}h overlap';
    }

    // Extract common interests from JSON
    final commonInterestsList = json['common_interests'];
    List<String> commonInterests = [];
    
    if (commonInterestsList != null) {
      if (commonInterestsList is List) {
        commonInterests = commonInterestsList
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (commonInterestsList is String) {
        // Handle case where it might be a JSON string
        try {
          final parsed = jsonDecode(commonInterestsList) as List;
          commonInterests = parsed
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } catch (e) {
          // If parsing fails, treat as single interest
          if (commonInterestsList.toString().trim().isNotEmpty) {
            commonInterests = [commonInterestsList.toString().trim()];
          }
        }
      }
    }
    
    print('🔍 [MatchService] Common interests parsed: $commonInterests');
    
    // Get user's own interests (not common interests) - this should come from user data
    // For now, we'll use an empty list or try to get from user2_data if available
    List<String> userInterests = [];
    if (otherUserData['interests'] != null) {
      if (otherUserData['interests'] is List) {
        userInterests = (otherUserData['interests'] as List)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    
    return Match(
      id: json['id'].toString(),
      user: User(
        id: otherUserData['id']?.toString() ?? '0',
        name: otherUserData['fullName'] ?? 'User',
        avatar:
            otherUserData['profileImageUrl'] ?? otherUserData['profileImage'],
        age: otherUserData['age'] ?? 0,
        nationality: otherUserData['nationality'] ?? '',
        gender: otherUserData['gender'] ?? 'other',
        languages: otherUserData['language'] != null
            ? [otherUserData['language']]
            : [],
        interests: userInterests, // User's own interests, not common interests
        verified: false,
        bio: '',
        rating: 0.0,
        reviewCount: 0,
        isOnline: false,
        currentLocation: json['matching_city'] != null
            ? '${json['matching_city']} Airport'
            : null,
        locationAccuracy: null,
        lastSeen: null,
        mutualConnections: 0,
        travelStats: const TravelStats(
          countriesVisited: 0,
          totalFlights: 0,
          flightsThisYear: 0,
          frequentFlyerTier: '',
        ),
        favoriteDestination: null,
      ),
      flightInfo:
          flightInfo ??
          FlightInfo(
            departure: '',
            departureCity: '',
            arrival: '',
            arrivalCity: '',
            airline: '',
            flightNumber: '',
            departureTime: DateTime.now(),
            arrivalTime: DateTime.now(),
            duration: '',
          ),
      compatibility: compatibility,
      compatibilityText: matchType.displayName,
      description: description,
      overlapTime: '${overlapHours.toStringAsFixed(1)}h overlap',
      sharedSegments: matchingAirport.isNotEmpty ? [matchingAirport] : [],
      suggestedActivities: _getSuggestedActivities(
        matchType,
        json['matching_city'] ?? '',
      ),
      status: json['status'] == 'matched' ? 'Matched!' : 'Connect',
      matchTime: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      matchType: matchType,
      commonInterests: commonInterests, // Set common interests on Match object
      tripPurpose: null,
    );
  }

  List<String> _getSuggestedActivities(MatchType matchType, String city) {
    switch (matchType) {
      case MatchType.sameLayover:
        return [
          'Coffee at airport lounge',
          'Explore $city airport',
          'Share travel stories',
        ];
      case MatchType.sameRoute:
        return [
          'Meet during layover',
          'Share taxi from airport',
          'Explore destination together',
        ];
      case MatchType.departureMatch:
        return [
          'Coffee before departure',
          'Share travel tips',
          'Network before flight',
        ];
      default:
        return ['Connect and explore'];
    }
  }
}
