// features/matches/services/match_service.dart

import 'package:nilewing/features/match/model/match_model.dart';

class MatchService {
  Future<List<Match>> getMatches() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return _getMockMatches();
  }

  Future<List<Match>> getMatchesByFilters(MatchFilters filters) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final allMatches = _getMockMatches();
    return _applyFilters(allMatches, filters);
  }

  Future<void> sendMatchRequest(String matchId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> acceptMatch(String matchId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> declineMatch(String matchId) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<User> getUserDetail(String userId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _getMockUserDetail(userId);
  }

  List<Match> _applyFilters(List<Match> matches, MatchFilters filters) {
    // ... (keep existing filter logic)
    return matches;
  }

  List<Match> _getMockMatches() {
    return [
      Match(
        id: '1',
        user: User(
          id: 'user1',
          name: 'Danei Tadesse',
          age: 29,
          nationality: 'Ethiopian',
          gender: 'Male',
          languages: ['Amharic', 'English'],
          interests: ['Coffee', 'Travel', 'Photography', 'Culture', 'Business'],
          verified: true,
          bio:
              'Love exploring new cultures and meeting people from around the world. Always up for a good coffee chat!',
          rating: 4.8,
          reviewCount: 23,
          isOnline: true,
          currentLocation: 'Charles de Gaulle Airport - Terminal 2E',
          locationAccuracy: const LocationAccuracy(accuracy: 10.0),
          lastSeen: DateTime.now(),
          mutualConnections: 3,
          travelStats: const TravelStats(
            countriesVisited: 34,
            totalFlights: 87,
            flightsThisYear: 12,
            frequentFlyerTier: 'Gold',
          ),
          favoriteDestination: 'Tokyo, Japan',
        ),
        flightInfo: FlightInfo(
          departure: 'ADD',
          departureCity: 'Addis Ababa',
          arrival: 'LHR',
          arrivalCity: 'London',
          layover: 'DXB',
          layoverCity: 'Dubai',
          airline: 'Ethiopian Airlines',
          flightNumber: 'ET701',
          departureTime: DateTime.now().add(const Duration(days: 1)),
          arrivalTime: DateTime.now().add(const Duration(days: 2)),
          duration: '15h 30m',
          gate: 'B12',
          tripPurpose: 'Business trip to London',
        ),
        compatibility: 92,
        compatibilityText: 'Same Route',
        description:
            'Same layover in Dubai & same destination London - Perfect for coffee meetup and shared taxi!',
        overlapTime: '3h 15m overlap',
        sharedSegments: ['DXB LHR'],
        suggestedActivities: [
          'Coffee at Dubai Terminal 3 Airport lounge',
          'Share taxi from Heathrow',
        ],
        status: 'Pre-flight match request sent - awaiting response',
        matchTime: DateTime.now().subtract(const Duration(hours: 2)),
        matchType: MatchType.sameRoute,
        commonInterests: ['Business', 'Coffee', 'Travel'],
        tripPurpose: 'Business trip to London',
      ),
      Match(
        id: '2',
        user: User(
          id: 'user2',
          name: 'Mariam Wanjiku',
          age: 26,
          nationality: 'Kenyan',
          gender: 'Female',
          languages: ['Swahili', 'English'],
          interests: ['Coffee', 'Culture', 'Art', 'Photography'],
          verified: true,
          bio:
              'Art enthusiast traveling to explore contemporary art scenes around the world. Love cultural exchanges over coffee.',
          rating: 4.7,
          reviewCount: 18,
          isOnline: false,
          currentLocation: 'Dubai International Airport - Terminal 3',
          locationAccuracy: const LocationAccuracy(accuracy: 15.0),
          lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
          mutualConnections: 2,
          travelStats: const TravelStats(
            countriesVisited: 28,
            totalFlights: 67,
            flightsThisYear: 18,
            frequentFlyerTier: 'Silver',
          ),
          favoriteDestination: 'Paris, France',
        ),
        flightInfo: FlightInfo(
          departure: 'NBO',
          departureCity: 'Nairobi',
          arrival: 'LHR',
          arrivalCity: 'London',
          layover: 'DXB',
          layoverCity: 'Dubai',
          airline: 'Kenya Airways',
          flightNumber: 'KQ700',
          departureTime: DateTime.now().add(const Duration(days: 1)),
          arrivalTime: DateTime.now().add(const Duration(days: 2)),
          duration: '14h 45m',
          gate: 'C8',
          tripPurpose: 'Art exhibition visit in London',
        ),
        compatibility: 88,
        compatibilityText: 'Same Route',
        description:
            'Long layover in Dubai, same flight to London - Perfect for coffee and cultural exchange!',
        overlapTime: '3h 15m overlap',
        sharedSegments: ['DXB LHR'],
        suggestedActivities: [
          'Coffee meeting at Terminal 3',
          'Dubai city tour',
          'Share taxi in London',
        ],
        status: 'Meeting confirmed Costa Coffee Terminal 3 at 13:00',
        matchTime: DateTime.now().subtract(const Duration(hours: 5)),
        matchType: MatchType.sameRoute,
        commonInterests: ['Coffee', 'Culture', 'Art'],
        tripPurpose: 'Art exhibition visit in London',
      ),
      Match(
        id: '3',
        user: User(
          id: 'user3',
          name: 'Amira Hassan',
          age: 24,
          nationality: 'Moroccan',
          gender: 'Female',
          languages: ['Arabic', 'French', 'English'],
          interests: ['Photography', 'Food', 'Culture', 'Travel'],
          verified: false,
          bio:
              'Food enthusiast and amateur photographer exploring culinary traditions around the world.',
          rating: 4.5,
          reviewCount: 12,
          isOnline: true,
          currentLocation: 'Istanbul Airport - Terminal I',
          locationAccuracy: const LocationAccuracy(accuracy: 20.0),
          lastSeen: DateTime.now(),
          mutualConnections: 1,
          travelStats: const TravelStats(
            countriesVisited: 18,
            totalFlights: 45,
            flightsThisYear: 8,
            frequentFlyerTier: 'Silver',
          ),
          favoriteDestination: 'Istanbul, Turkey',
        ),
        flightInfo: FlightInfo(
          departure: 'CMN',
          departureCity: 'Casablanca',
          arrival: 'DXB',
          arrivalCity: 'Dubai',
          layover: 'IST',
          layoverCity: 'Istanbul',
          airline: 'Turkish Airlines',
          flightNumber: 'TK120',
          departureTime: DateTime.now().add(const Duration(days: 2)),
          arrivalTime: DateTime.now().add(const Duration(days: 2)),
          duration: '8h 30m',
          gate: 'D12',
          tripPurpose: 'Culinary exploration in Dubai',
        ),
        compatibility: 67,
        compatibilityText: 'Same Layover',
        description:
            'Connecting through Istanbul - great opportunity to explore the airport together!',
        overlapTime: '2h 45m overlap',
        sharedSegments: ['IST Layover'],
        suggestedActivities: [
          'Turkish coffee tasting',
          'Airport shopping',
          'Cultural exchange',
        ],
        status: 'Connect',
        matchTime: DateTime.now().subtract(const Duration(minutes: 1)),
        matchType: MatchType.sameLayover,
        commonInterests: ['Food', 'Culture', 'Travel'],
        tripPurpose: 'Culinary exploration in Dubai',
      ),
      Match(
        id: '4',
        user: User(
          id: 'user4',
          name: 'Elena Rodriguez',
          age: 28,
          nationality: 'Spanish',
          gender: 'Female',
          languages: ['Spanish', 'English', 'French'],
          interests: [
            'Photography',
            'Food',
            'Culture',
            'Art',
            'Travel',
            'Music',
            'Architecture',
          ],
          verified: true,
          bio:
              'Passionate photographer and food enthusiast exploring the world one flight at a time. Love connecting with fellow travelers and sharing cultural experiences. Currently on a journey to document the beauty of different cultures through my lens.',
          rating: 4.9,
          reviewCount: 31,
          isOnline: true,
          currentLocation: 'Charles de Gaulle Airport - Terminal 2E',
          locationAccuracy: const LocationAccuracy(accuracy: 10.0),
          lastSeen: DateTime.now(),
          mutualConnections: 3,
          travelStats: const TravelStats(
            countriesVisited: 34,
            totalFlights: 87,
            flightsThisYear: 12,
            frequentFlyerTier: 'Gold',
          ),
          favoriteDestination: 'Tokyo, Japan',
        ),
        flightInfo: FlightInfo(
          departure: 'MAD',
          departureCity: 'Madrid',
          arrival: 'LAX',
          arrivalCity: 'Los Angeles',
          airline: 'Iberia',
          flightNumber: 'IB6275',
          departureTime: DateTime.now().add(const Duration(hours: 3)),
          arrivalTime: DateTime.now().add(const Duration(hours: 15)),
          duration: '12h 45m',
          gate: 'B12',
          tripPurpose: 'Photography project in California',
        ),
        compatibility: 85,
        compatibilityText: 'Destination Match',
        description:
            'Both photography enthusiasts heading to California - great opportunity to collaborate!',
        overlapTime: 'Same destination',
        sharedSegments: ['LAX'],
        suggestedActivities: [
          'Photography walk in LA',
          'Food tour exploration',
          'Cultural sites visit',
        ],
        status: 'Connect',
        matchTime: DateTime.now().subtract(const Duration(hours: 1)),
        matchType: MatchType.destinationMatch,
        commonInterests: ['Photography', 'Food', 'Culture'],
        tripPurpose: 'Photography project in California',
      ),
    ];
  }

  User _getMockUserDetail(String userId) {
    final matches = _getMockMatches();
    final match = matches.firstWhere((m) => m.user.id == userId);
    return match.user;
  }
}
