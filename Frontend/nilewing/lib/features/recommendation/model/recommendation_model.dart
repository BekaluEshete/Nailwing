// features/recommendations/models/recommendation_models.dart
class Place {
  final String id;
  final String name;
  final PlaceType type;
  final double rating;
  final int reviewCount;
  final int priceLevel;
  final String distance;
  final String walkTime;
  final bool openNow;
  final List<String> openingHours;
  final String address;
  final String phoneNumber;
  final String? website;
  final List<String> photos;
  final List<String> amenities;
  final String description;
  final Map<String, int> popularTimes;
  final String averageSpend;
  final List<String>? specialties;
  final String? roomPrice;
  final bool wifi;
  final bool parking;
  final Coordinates coordinates;

  Place({
    required this.id,
    required this.name,
    required this.type,
    required this.rating,
    required this.reviewCount,
    required this.priceLevel,
    required this.distance,
    required this.walkTime,
    required this.openNow,
    required this.openingHours,
    required this.address,
    required this.phoneNumber,
    this.website,
    required this.photos,
    required this.amenities,
    required this.description,
    required this.popularTimes,
    required this.averageSpend,
    this.specialties,
    this.roomPrice,
    required this.wifi,
    required this.parking,
    required this.coordinates,
  });

  Place copyWith({
    String? id,
    String? name,
    PlaceType? type,
    double? rating,
    int? reviewCount,
    int? priceLevel,
    String? distance,
    String? walkTime,
    bool? openNow,
    List<String>? openingHours,
    String? address,
    String? phoneNumber,
    String? website,
    List<String>? photos,
    List<String>? amenities,
    String? description,
    Map<String, int>? popularTimes,
    String? averageSpend,
    List<String>? specialties,
    String? roomPrice,
    bool? wifi,
    bool? parking,
    Coordinates? coordinates,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      priceLevel: priceLevel ?? this.priceLevel,
      distance: distance ?? this.distance,
      walkTime: walkTime ?? this.walkTime,
      openNow: openNow ?? this.openNow,
      openingHours: openingHours ?? this.openingHours,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      photos: photos ?? this.photos,
      amenities: amenities ?? this.amenities,
      description: description ?? this.description,
      popularTimes: popularTimes ?? this.popularTimes,
      averageSpend: averageSpend ?? this.averageSpend,
      specialties: specialties ?? this.specialties,
      roomPrice: roomPrice ?? this.roomPrice,
      wifi: wifi ?? this.wifi,
      parking: parking ?? this.parking,
      coordinates: coordinates ?? this.coordinates,
    );
  }
}

class NearbyUser {
  final String id;
  final String name;
  final String? avatar;
  final int age;
  final String nationality;
  final String currentLocation;
  final String distanceFromAirport;
  final List<String> interests;
  final bool isOnline;
  final int mutualConnections;
  final String currentActivity;
  final List<String> localRecommendations;

  NearbyUser({
    required this.id,
    required this.name,
    this.avatar,
    required this.age,
    required this.nationality,
    required this.currentLocation,
    required this.distanceFromAirport,
    required this.interests,
    required this.isOnline,
    required this.mutualConnections,
    required this.currentActivity,
    required this.localRecommendations,
  });

  NearbyUser copyWith({
    String? id,
    String? name,
    String? avatar,
    int? age,
    String? nationality,
    String? currentLocation,
    String? distanceFromAirport,
    List<String>? interests,
    bool? isOnline,
    int? mutualConnections,
    String? currentActivity,
    List<String>? localRecommendations,
  }) {
    return NearbyUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      age: age ?? this.age,
      nationality: nationality ?? this.nationality,
      currentLocation: currentLocation ?? this.currentLocation,
      distanceFromAirport: distanceFromAirport ?? this.distanceFromAirport,
      interests: interests ?? this.interests,
      isOnline: isOnline ?? this.isOnline,
      mutualConnections: mutualConnections ?? this.mutualConnections,
      currentActivity: currentActivity ?? this.currentActivity,
      localRecommendations: localRecommendations ?? this.localRecommendations,
    );
  }
}

class Coordinates {
  final double lat;
  final double lng;

  Coordinates({required this.lat, required this.lng});
}

class Airport {
  final String code;
  final String name;
  final String city;
  final String country;

  Airport({
    required this.code,
    required this.name,
    required this.city,
    required this.country,
  });
}

enum PlaceType { hotel, cafe, restaurant }

class RecommendationsState {
  final List<Place> places;
  final List<NearbyUser> nearbyUsers;
  final Set<String> favoriteIds;
  final String searchQuery;
  final int selectedTabIndex;
  final Place? selectedPlace;
  final bool isLoading;
  final String? error;

  RecommendationsState({
    required this.places,
    required this.nearbyUsers,
    required this.favoriteIds,
    required this.searchQuery,
    required this.selectedTabIndex,
    this.selectedPlace,
    required this.isLoading,
    this.error,
  });

  RecommendationsState copyWith({
    List<Place>? places,
    List<NearbyUser>? nearbyUsers,
    Set<String>? favoriteIds,
    String? searchQuery,
    int? selectedTabIndex,
    Place? selectedPlace,
    bool? isLoading,
    String? error,
  }) {
    return RecommendationsState(
      places: places ?? this.places,
      nearbyUsers: nearbyUsers ?? this.nearbyUsers,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      selectedPlace: selectedPlace ?? this.selectedPlace,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  List<Place> get filteredPlaces {
    if (selectedTabIndex == 3) return []; // People tab

    final currentType = _getPlaceTypeForTab(selectedTabIndex);
    return places.where((place) {
      final matchesTab = place.type == currentType;
      final matchesSearch =
          searchQuery.isEmpty ||
          place.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          place.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          place.specialties?.any(
                (s) => s.toLowerCase().contains(searchQuery.toLowerCase()),
              ) ==
              true;

      return matchesTab && matchesSearch;
    }).toList();
  }

  PlaceType? _getPlaceTypeForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return PlaceType.hotel;
      case 1:
        return PlaceType.cafe;
      case 2:
        return PlaceType.restaurant;
      default:
        return null;
    }
  }
}
