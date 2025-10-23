// features/matches/models/match_model.dart
class Match {
  final String id;
  final User user;
  final FlightInfo flightInfo;
  final int compatibility;
  final String compatibilityText;
  final String description;
  final String overlapTime;
  final List<String> sharedSegments;
  final List<String> suggestedActivities;
  final String status;
  final DateTime matchTime;
  final MatchType matchType;

  Match({
    required this.id,
    required this.user,
    required this.flightInfo,
    required this.compatibility,
    required this.compatibilityText,
    required this.description,
    required this.overlapTime,
    required this.sharedSegments,
    required this.suggestedActivities,
    required this.status,
    required this.matchTime,
    required this.matchType,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(matchTime);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${difference.inDays ~/ 7}w ago';
  }

  Match copyWith({
    String? id,
    User? user,
    FlightInfo? flightInfo,
    int? compatibility,
    String? compatibilityText,
    String? description,
    String? overlapTime,
    List<String>? sharedSegments,
    List<String>? suggestedActivities,
    String? status,
    DateTime? matchTime,
    MatchType? matchType,
  }) {
    return Match(
      id: id ?? this.id,
      user: user ?? this.user,
      flightInfo: flightInfo ?? this.flightInfo,
      compatibility: compatibility ?? this.compatibility,
      compatibilityText: compatibilityText ?? this.compatibilityText,
      description: description ?? this.description,
      overlapTime: overlapTime ?? this.overlapTime,
      sharedSegments: sharedSegments ?? this.sharedSegments,
      suggestedActivities: suggestedActivities ?? this.suggestedActivities,
      status: status ?? this.status,
      matchTime: matchTime ?? this.matchTime,
      matchType: matchType ?? this.matchType,
    );
  }
}

class User {
  final String id;
  final String name;
  final String? avatar;
  final int age;
  final String nationality;
  final String gender;
  final List<String> languages;
  final List<String> interests;
  final bool verified;
  final String? bio;
  final double rating;
  final int reviewCount;

  User({
    required this.id,
    required this.name,
    this.avatar,
    required this.age,
    required this.nationality,
    required this.gender,
    required this.languages,
    required this.interests,
    required this.verified,
    this.bio,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  String get initials => name.split(' ').map((n) => n[0]).join();

  User copyWith({
    String? id,
    String? name,
    String? avatar,
    int? age,
    String? nationality,
    String? gender,
    List<String>? languages,
    List<String>? interests,
    bool? verified,
    String? bio,
    double? rating,
    int? reviewCount,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      age: age ?? this.age,
      nationality: nationality ?? this.nationality,
      gender: gender ?? this.gender,
      languages: languages ?? this.languages,
      interests: interests ?? this.interests,
      verified: verified ?? this.verified,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}

class FlightInfo {
  final String departure;
  final String departureCity;
  final String arrival;
  final String arrivalCity;
  final String? layover;
  final String? layoverCity;
  final String airline;
  final String flightNumber;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final String duration;
  final String? gate;

  FlightInfo({
    required this.departure,
    required this.departureCity,
    required this.arrival,
    required this.arrivalCity,
    this.layover,
    this.layoverCity,
    required this.airline,
    required this.flightNumber,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    this.gate,
  });

  FlightInfo copyWith({
    String? departure,
    String? departureCity,
    String? arrival,
    String? arrivalCity,
    String? layover,
    String? layoverCity,
    String? airline,
    String? flightNumber,
    DateTime? departureTime,
    DateTime? arrivalTime,
    String? duration,
    String? gate,
  }) {
    return FlightInfo(
      departure: departure ?? this.departure,
      departureCity: departureCity ?? this.departureCity,
      arrival: arrival ?? this.arrival,
      arrivalCity: arrivalCity ?? this.arrivalCity,
      layover: layover ?? this.layover,
      layoverCity: layoverCity ?? this.layoverCity,
      airline: airline ?? this.airline,
      flightNumber: flightNumber ?? this.flightNumber,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      duration: duration ?? this.duration,
      gate: gate ?? this.gate,
    );
  }
}

class MatchFilters {
  final String gender;
  final String ageRange;
  final String nationality;
  final String language;
  final List<String> interests;
  final int minCompatibility;
  final List<MatchType> matchTypes;

  const MatchFilters({
    this.gender = 'all',
    this.ageRange = 'all',
    this.nationality = 'all',
    this.language = 'all',
    this.interests = const [],
    this.minCompatibility = 0,
    this.matchTypes = const [],
  });

  MatchFilters copyWith({
    String? gender,
    String? ageRange,
    String? nationality,
    String? language,
    List<String>? interests,
    int? minCompatibility,
    List<MatchType>? matchTypes,
  }) {
    return MatchFilters(
      gender: gender ?? this.gender,
      ageRange: ageRange ?? this.ageRange,
      nationality: nationality ?? this.nationality,
      language: language ?? this.language,
      interests: interests ?? this.interests,
      minCompatibility: minCompatibility ?? this.minCompatibility,
      matchTypes: matchTypes ?? this.matchTypes,
    );
  }

  bool get isDefault {
    return gender == 'all' &&
        ageRange == 'all' &&
        nationality == 'all' &&
        language == 'all' &&
        interests.isEmpty &&
        minCompatibility == 0 &&
        matchTypes.isEmpty;
  }
}

enum MatchType {
  sameRoute,
  sameLayover,
  departureMatch,
  destinationMatch,
  groupMeetup,
}

extension MatchTypeExtension on MatchType {
  String get displayName {
    switch (this) {
      case MatchType.sameRoute:
        return 'Same Route';
      case MatchType.sameLayover:
        return 'Same Layover';
      case MatchType.departureMatch:
        return 'Departure Match';
      case MatchType.destinationMatch:
        return 'Destination Match';
      case MatchType.groupMeetup:
        return 'Group Meetup';
    }
  }

  String get description {
    switch (this) {
      case MatchType.sameRoute:
        return 'Traveling the same route';
      case MatchType.sameLayover:
        return 'Same layover location';
      case MatchType.departureMatch:
        return 'Departing from same airport';
      case MatchType.destinationMatch:
        return 'Same destination city';
      case MatchType.groupMeetup:
        return 'Group meeting opportunity';
    }
  }
}
