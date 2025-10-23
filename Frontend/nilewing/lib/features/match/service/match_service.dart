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

  List<Match> _applyFilters(List<Match> matches, MatchFilters filters) {
    return matches.where((match) {
      if (filters.gender != 'all' && match.user.gender != filters.gender) {
        return false;
      }

      if (filters.ageRange != 'all') {
        final age = match.user.age;
        switch (filters.ageRange) {
          case '18-25':
            if (age < 18 || age > 25) return false;
            break;
          case '26-35':
            if (age < 26 || age > 35) return false;
            break;
          case '36-45':
            if (age < 36 || age > 45) return false;
            break;
          case '46+':
            if (age < 46) return false;
            break;
        }
      }

      if (filters.nationality != 'all' &&
          match.user.nationality != filters.nationality) {
        return false;
      }

      if (filters.language != 'all' &&
          !match.user.languages.contains(filters.language)) {
        return false;
      }

      if (filters.interests.isNotEmpty &&
          !filters.interests.any(
            (interest) => match.user.interests.contains(interest),
          )) {
        return false;
      }

      if (match.compatibility < filters.minCompatibility) {
        return false;
      }

      if (filters.matchTypes.isNotEmpty &&
          !filters.matchTypes.contains(match.matchType)) {
        return false;
      }

      return true;
    }).toList();
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
          interests: ['Coffee', 'Travel', 'Photography', 'Culture'],
          verified: true,
          bio:
              'Love exploring new cultures and meeting people from around the world. Always up for a good coffee chat!',
          rating: 4.8,
          reviewCount: 23,
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
      ),
      Match(
        id: '2',
        user: User(
          id: 'user2',
          name: 'Sophie Laurent',
          age: 28,
          nationality: 'French',
          gender: 'Female',
          languages: ['French', 'English', 'Spanish'],
          interests: ['Art', 'Photography', 'Food', 'Wine'],
          verified: true,
          bio:
              'Art enthusiast and food lover. Always looking for new culinary experiences and cultural exchanges.',
          rating: 4.9,
          reviewCount: 31,
        ),
        flightInfo: FlightInfo(
          departure: 'CDG',
          departureCity: 'Paris',
          arrival: 'DXB',
          arrivalCity: 'Dubai',
          airline: 'Emirates',
          flightNumber: 'EK202',
          departureTime: DateTime.now().add(const Duration(days: 3)),
          arrivalTime: DateTime.now().add(const Duration(days: 3)),
          duration: '6h 45m',
          gate: 'A8',
        ),
        compatibility: 85,
        compatibilityText: 'Destination Match',
        description:
            'Both heading to Dubai - great opportunity to explore the city together!',
        overlapTime: 'Same destination',
        sharedSegments: ['DXB'],
        suggestedActivities: [
          'Desert safari experience',
          'Dubai Mall shopping',
          'Traditional Arabic dinner',
        ],
        status: 'Match request available',
        matchTime: DateTime.now().subtract(const Duration(hours: 5)),
        matchType: MatchType.destinationMatch,
      ),
    ];
  }
}
