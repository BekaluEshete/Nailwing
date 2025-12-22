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

  Future<String?> _getCurrentUserId() async {
    try {
      final userData = await _tokenStorage.getUserData();
      return userData?['id']?.toString();
    } catch (e) {
      print('❌ [MatchService] Error getting current user ID: $e');
      return null;
    }
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
      
      http.Response response;
      try {
        response = await _httpClient.get(Uri.parse(url));
      } catch (e) {
        // Check for network connectivity issues
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('failed host lookup') || 
            errorString.contains('socketexception') ||
            errorString.contains('no address associated with hostname')) {
          throw Exception('Cannot connect to server. Please check your internet connection and ensure the backend server is running.');
        } else if (errorString.contains('timeout') || errorString.contains('timed out')) {
          throw Exception('Connection timeout. The server is taking too long to respond. Please try again.');
        } else if (errorString.contains('connection refused')) {
          throw Exception('Connection refused. The server may be down. Please try again later.');
        }
        rethrow;
      }

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
        // Get current user ID once for all matches
        final currentUserId = await _getCurrentUserId();
        
        // Parse matches with error handling
        final matches = <Match>[];
        for (final jsonData in matchesData) {
          try {
            final match = _matchFromJson(jsonData, currentUserId);
            matches.add(match);
            print('✅ [MatchService] Successfully parsed match: ${match.id}');
          } catch (e, stackTrace) {
            print('❌ [MatchService] Error parsing match: $e');
            print('❌ [MatchService] Stack trace: $stackTrace');
            print('❌ [MatchService] Match data: ${json.encode(jsonData)}');
            // Continue with other matches instead of failing completely
          }
        }
        
        if (matches.isEmpty && matchesData.isNotEmpty) {
          print('⚠️ [MatchService] Failed to parse any matches from ${matchesData.length} match(es)');
          throw Exception('Failed to parse matches. Please check the data format.');
        }
        
        print('✅ [MatchService] Successfully parsed ${matches.length} out of ${matchesData.length} matches');
        return matches;
      }
      print('❌ [MatchService] Failed with status: ${response.statusCode}');
      throw Exception('Failed to find matches: ${response.statusCode}');
    } catch (e) {
      print('❌ [MatchService] Error finding matches: $e');
      // If it's already a user-friendly message, rethrow it
      if (e.toString().contains('Cannot connect') || 
          e.toString().contains('Connection timeout') ||
          e.toString().contains('Connection refused')) {
        rethrow;
      }
      // Otherwise, provide a generic error
      throw Exception('Failed to load matches. Please check your internet connection and try again.');
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
        final currentUserId = await _getCurrentUserId();
        return data.map((json) => _matchFromJson(json, currentUserId)).toList();
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
        final currentUserId = await _getCurrentUserId();
        return _matchFromJson(data, currentUserId);
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

  // Reject a match or connection request
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

  // Accept a connection request
  Future<Match> acceptConnection(String matchId) async {
    try {
      print('✅ [MatchService] Accepting connection request: $matchId');
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ [MatchService] No auth token found');
        throw Exception('Not authenticated');
      }

      final url = '${AppConstants.matchesEndpoint}/$matchId/accept_connection/';
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
        print('✅ [MatchService] Connection accepted successfully');
        final currentUserId = await _getCurrentUserId();
        return _matchFromJson(data, currentUserId);
      } else {
        final errorData = json.decode(response.body);
        print(
          '❌ [MatchService] Error: ${errorData['error'] ?? 'Unknown error'}',
        );
        throw Exception(errorData['error'] ?? 'Failed to accept connection');
      }
    } catch (e) {
      print('❌ [MatchService] Error accepting connection: $e');
      throw Exception('Error accepting connection: $e');
    }
  }

  // Get connection requests (pending requests sent to current user)
  Future<List<Match>> getConnectionRequests() async {
    try {
      print('📬 [MatchService] Getting connection requests...');
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${AppConstants.matchesEndpoint}/connection_requests/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 [MatchService] Response status: ${response.statusCode}');
      print('📥 [MatchService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final currentUserId = await _getCurrentUserId();
        final requests = data.map((json) => _matchFromJson(json, currentUserId)).toList();
        print('✅ [MatchService] Found ${requests.length} connection requests');
        return requests;
      }
      return [];
    } catch (e) {
      print('❌ [MatchService] Error getting connection requests: $e');
      return [];
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
  Match _matchFromJson(Map<String, dynamic> json, String? currentUserId) {
    final user1Data = json['user1_data'] ?? <String, dynamic>{};
    final user2Data = json['user2_data'] ?? <String, dynamic>{};
    final flight1Data = json['flight1_data'] as Map<String, dynamic>?;
    final flight2Data = json['flight2_data'] as Map<String, dynamic>?;

    // Determine which user is the "other" user (not current user)
    Map<String, dynamic> otherUserData;
    Map<String, dynamic>? otherFlightData;
    bool? currentUserIsUser1;
    
    final user1Id = user1Data['id']?.toString();
    final user2Id = user2Data['id']?.toString();
    
    if (currentUserId != null && user1Id == currentUserId) {
      // Current user is user1, so other user is user2
      otherUserData = user2Data;
      otherFlightData = flight2Data;
      currentUserIsUser1 = true;
      print('👤 [MatchService] Current user is user1 (ID: $currentUserId), other user is user2 (ID: $user2Id)');
    } else if (currentUserId != null && user2Id == currentUserId) {
      // Current user is user2, so other user is user1
      otherUserData = user1Data;
      otherFlightData = flight1Data;
      currentUserIsUser1 = false;
      print('👤 [MatchService] Current user is user2 (ID: $currentUserId), other user is user1 (ID: $user1Id)');
    } else {
      // Fallback: assume user2 is the match (for backward compatibility)
      otherUserData = user2Data;
      otherFlightData = flight2Data;
      currentUserIsUser1 = null;
      print('⚠️ [MatchService] Could not determine current user (current: $currentUserId, user1: $user1Id, user2: $user2Id), defaulting to user2');
    }

    // Parse match type - explicit mapping from backend to frontend
    final matchTypeStr = json['match_type'] ?? '';
    MatchType matchType;
    
    switch (matchTypeStr) {
      case 'same_route':
        matchType = MatchType.sameRoute;
        break;
      case 'same_layover':
        matchType = MatchType.sameLayover;
        break;
      case 'same_departure':
        matchType = MatchType.departureMatch;
        break;
      case 'same_destination':
        matchType = MatchType.destinationMatch;
        break;
      case 'layover_departure':
      case 'departure_layover':
        // Both represent Scenario 3: Departure is someone's layover/destination
        matchType = MatchType.departureMatch;
        break;
      default:
        // Fallback: try to infer from string (for backward compatibility)
        if (matchTypeStr.contains('layover')) {
          matchType = MatchType.sameLayover;
        } else if (matchTypeStr.contains('departure')) {
          matchType = MatchType.departureMatch;
        } else if (matchTypeStr.contains('destination')) {
          matchType = MatchType.destinationMatch;
        } else {
          matchType = MatchType.sameRoute; // Default fallback
        }
        print('⚠️ [MatchService] Unknown match_type: "$matchTypeStr", defaulting to ${matchType.name}');
    }
    
    print('🔍 [MatchService] Parsed match_type: "$matchTypeStr" → ${matchType.name}');

    // Build flight info
    FlightInfo? flightInfo;
    if (otherFlightData != null) {
      try {
        flightInfo = FlightInfo(
          departure: otherFlightData['departure_airport']?.toString() ?? '',
          departureCity: otherFlightData['departure_city']?.toString() ?? '',
          arrival: otherFlightData['arrival_airport']?.toString() ?? '',
          arrivalCity: otherFlightData['arrival_city']?.toString() ?? '',
          layover: otherFlightData['layover_airport']?.toString(),
          layoverCity: otherFlightData['layover_city']?.toString(),
          airline: otherFlightData['airline']?.toString() ?? '',
          flightNumber: otherFlightData['flight_number']?.toString() ?? '',
          departureTime: otherFlightData['departure_datetime'] != null
              ? DateTime.parse(otherFlightData['departure_datetime'].toString())
              : DateTime.now(),
          arrivalTime: otherFlightData['arrival_datetime'] != null
              ? DateTime.parse(otherFlightData['arrival_datetime'].toString())
              : DateTime.now(),
          duration: otherFlightData['duration_hours'] != null
              ? '${(otherFlightData['duration_hours'] as num).toStringAsFixed(1)}h'
              : '',
          gate: otherFlightData['departure_gate']?.toString(),
          tripPurpose: null,
        );
      } catch (e) {
        print('⚠️ [MatchService] Error parsing flight info: $e');
        // Continue without flight info
      }
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

    // Extract common interests from JSON - Enhanced parsing
    final commonInterestsList = json['common_interests'];
    List<String> commonInterests = [];
    
    print('🔍 [MatchService] Raw common_interests from JSON: $commonInterestsList (type: ${commonInterestsList.runtimeType})');
    
    if (commonInterestsList != null) {
      if (commonInterestsList is List) {
        commonInterests = commonInterestsList
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
        print('🔍 [MatchService] Parsed as List: $commonInterests');
      } else if (commonInterestsList is String) {
        // Handle case where it might be a JSON string
        try {
          final parsed = jsonDecode(commonInterestsList) as List;
          commonInterests = parsed
              .map((e) => e?.toString().trim() ?? '')
              .where((e) => e.isNotEmpty)
              .toList();
          print('🔍 [MatchService] Parsed as JSON string: $commonInterests');
        } catch (e) {
          // If parsing fails, treat as single interest
          final trimmed = commonInterestsList.toString().trim();
          if (trimmed.isNotEmpty) {
            commonInterests = [trimmed];
            print('🔍 [MatchService] Treated as single interest: $commonInterests');
          }
        }
      } else {
        print('⚠️ [MatchService] Unknown type for common_interests: ${commonInterestsList.runtimeType}');
          }
    } else {
      print('⚠️ [MatchService] common_interests is null or missing in JSON');
    }
    
    print('🔍 [MatchService] Final common interests parsed: $commonInterests (count: ${commonInterests.length})');
    
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
    
    // Parse user1_liked and user2_liked
    final user1Liked = json['user1_liked'] as bool? ?? false;
    final user2Liked = json['user2_liked'] as bool? ?? false;
    
    return Match(
      id: json['id'].toString(),
      currentUserIsUser1: currentUserIsUser1,
      user1Liked: user1Liked,
      user2Liked: user2Liked,
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
      status: _getStatusDisplayText(json, currentUserId),
      matchTime: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      matchType: matchType,
      commonInterests: commonInterests, // Set common interests on Match object
      tripPurpose: null,
    );
  }

  // Helper: Get display text for match status
  String _getStatusDisplayText(Map<String, dynamic> json, String? currentUserId) {
    final status = json['status']?.toString().toLowerCase() ?? 'pending';
    final user1Liked = json['user1_liked'] ?? false;
    final user2Liked = json['user2_liked'] ?? false;
    final user1Id = json['user1']?.toString();
    final user2Id = json['user2']?.toString();
    
    // Determine if current user sent the request or received it
    bool currentUserSentRequest = false;
    if (currentUserId != null) {
      if (currentUserId == user1Id && user1Liked && !user2Liked) {
        currentUserSentRequest = true;
      } else if (currentUserId == user2Id && user2Liked && !user1Liked) {
        currentUserSentRequest = true;
      }
    }
    
    // Status display logic
    if (status == 'matched' || (user1Liked && user2Liked)) {
      return 'Connected';
    } else if (status == 'connection_requested') {
      if (currentUserSentRequest) {
        return 'Request Sent';
      } else {
        return 'Connection Request';
      }
    } else if (status == 'rejected') {
      return 'Rejected';
    } else if (status == 'liked') {
      return 'Connected'; // Legacy support
    } else {
      return 'Connect';
    }
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
  
  // Fetch user profile by user ID
  Future<User> getUserProfileById(String userId) async {
    try {
      print('👤 [MatchService] Fetching user profile for ID: $userId');
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final url = '${AppConstants.authBaseUrl}/$userId/user_profile/';
      print('📡 [MatchService] GET: $url');
      
      final response = await _httpClient.get(Uri.parse(url));
      
      print('📥 [MatchService] Response status: ${response.statusCode}');
      print('📥 [MatchService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data'] ?? data;
        
        print('✅ [MatchService] User profile loaded successfully');
        
        // Parse language field
        List<String> languages = [];
        if (userData['language'] != null) {
          if (userData['language'] is List) {
            languages = (userData['language'] as List)
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList();
          } else if (userData['language'] is String) {
            languages = [userData['language']];
          }
        }
        
        // Parse interests - check multiple possible fields
        List<String> interests = [];
        if (userData['interests'] != null) {
          if (userData['interests'] is List) {
            interests = (userData['interests'] as List)
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
        }
        
        // Calculate age from date_joined if age not provided
        int age = userData['age'] ?? 0;
        if (age == 0 && userData['date_joined'] != null) {
          try {
            final dateJoined = DateTime.parse(userData['date_joined']);
            final now = DateTime.now();
            age = now.year - dateJoined.year;
            if (now.month < dateJoined.month || 
                (now.month == dateJoined.month && now.day < dateJoined.day)) {
              age--;
            }
          } catch (e) {
            print('⚠️ [MatchService] Could not calculate age: $e');
          }
        }
        
        return User(
          id: userData['id']?.toString() ?? userId,
          name: userData['fullName'] ?? userData['first_name'] ?? 'User',
          avatar: userData['profileImageUrl'] ?? userData['profileImage'],
          age: age,
          nationality: userData['nationality'] ?? '',
          gender: userData['gender'] ?? 'other',
          languages: languages,
          interests: interests,
          verified: false,
          bio: userData['bio'] ?? '',
          rating: 0.0,
          reviewCount: 0,
          isOnline: false,
          currentLocation: null,
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
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to load user profile');
      }
    } catch (e) {
      print('❌ [MatchService] Error fetching user profile: $e');
      rethrow;
    }
  }
}
