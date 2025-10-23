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
  final List<String> commonInterests;
  final String? tripPurpose;

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
    required this.commonInterests,
    this.tripPurpose,
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
    List<String>? commonInterests,
    String? tripPurpose,
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
      commonInterests: commonInterests ?? this.commonInterests,
      tripPurpose: tripPurpose ?? this.tripPurpose,
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
  final bool isOnline;
  final String? currentLocation;
  final LocationAccuracy? locationAccuracy;
  final DateTime? lastSeen;
  final int mutualConnections;
  final TravelStats travelStats;
  final String? favoriteDestination;

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
    this.isOnline = false,
    this.currentLocation,
    this.locationAccuracy,
    this.lastSeen,
    this.mutualConnections = 0,
    required this.travelStats,
    this.favoriteDestination,
  });

  String get initials => name.split(' ').map((n) => n[0]).join();

  String get lastSeenText {
    if (isOnline) return 'Active now';
    if (lastSeen == null) return 'Recently active';

    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

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
    bool? isOnline,
    String? currentLocation,
    LocationAccuracy? locationAccuracy,
    DateTime? lastSeen,
    int? mutualConnections,
    TravelStats? travelStats,
    String? favoriteDestination,
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
      isOnline: isOnline ?? this.isOnline,
      currentLocation: currentLocation ?? this.currentLocation,
      locationAccuracy: locationAccuracy ?? this.locationAccuracy,
      lastSeen: lastSeen ?? this.lastSeen,
      mutualConnections: mutualConnections ?? this.mutualConnections,
      travelStats: travelStats ?? this.travelStats,
      favoriteDestination: favoriteDestination ?? this.favoriteDestination,
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
  final String? tripPurpose;

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
    this.tripPurpose,
  });

  String get route {
    if (layover != null) {
      return '$departure → $layover → $arrival';
    }
    return '$departure → $arrival';
  }

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
    String? tripPurpose,
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
      tripPurpose: tripPurpose ?? this.tripPurpose,
    );
  }
}

class TravelStats {
  final int countriesVisited;
  final int totalFlights;
  final int flightsThisYear;
  final String frequentFlyerTier;

  const TravelStats({
    required this.countriesVisited,
    required this.totalFlights,
    required this.flightsThisYear,
    required this.frequentFlyerTier,
  });
}

class LocationAccuracy {
  final double accuracy;
  final String unit;

  const LocationAccuracy({required this.accuracy, this.unit = 'm'});

  String get displayText => 'Accuracy: ${accuracy.toInt()}$unit';
}

// ... (Keep the existing MatchFilters and MatchType classes)

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
