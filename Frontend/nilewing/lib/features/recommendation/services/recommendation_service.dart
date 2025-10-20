// features/recommendations/services/recommendations_service.dart

import 'package:nilewing/features/recommendation/model/recommendation_model.dart';

class RecommendationsService {
  static final Airport _currentAirport = Airport(
    code: 'BDR',
    name: 'Belay  Zeleke International Airport',
    city: 'Bahirdar',
    country: 'Ethiopia',
  );

  Future<Airport> getCurrentAirport() async {
    // In real app, this would fetch from API based on user location
    await Future.delayed(const Duration(milliseconds: 500));
    return _currentAirport;
  }

  Future<List<Place>> getPlacesNearAirport(String airportCode) async {
    // Mock API call - replace with actual API
    await Future.delayed(const Duration(milliseconds: 1000));

    return [
      Place(
        id: '1',
        name: 'Sheraton Paris Airport Hotel',
        type: PlaceType.hotel,
        rating: 4.2,
        reviewCount: 1847,
        priceLevel: 3,
        distance: '0.2 km',
        walkTime: '3 min walk',
        openNow: true,
        openingHours: ['Open 24 hours'],
        address:
            'Terminal 2, Charles de Gaulle Airport, 95716 Roissy-en-France',
        phoneNumber: '+33 1 49 19 70 70',
        website: 'sheraton.com/paris-airport',
        photos: ['hotel1.jpg', 'hotel2.jpg'],
        amenities: [
          'Free WiFi',
          'Fitness Center',
          'Restaurant',
          'Bar',
          'Business Center',
          'Airport Shuttle',
        ],
        description:
            'Modern hotel directly connected to Terminal 2 at CDG Airport. Perfect for layovers with soundproof rooms and 24/7 dining options.',
        popularTimes: {'06:00': 20, '12:00': 60, '18:00': 80, '22:00': 40},
        averageSpend: '€180-250/night',
        roomPrice: '€210/night',
        wifi: true,
        parking: true,
        coordinates: Coordinates(lat: 49.0047, lng: 2.5710),
      ),
      Place(
        id: '2',
        name: 'Café Paris',
        type: PlaceType.cafe,
        rating: 4.5,
        reviewCount: 892,
        priceLevel: 2,
        distance: '0.1 km',
        walkTime: '2 min walk',
        openNow: true,
        openingHours: ['5:30 AM - 11:00 PM'],
        address: 'Terminal 2E, Level 2, Charles de Gaulle Airport',
        phoneNumber: '+33 1 48 16 14 24',
        photos: ['cafe1.jpg', 'cafe2.jpg'],
        amenities: [
          'Free WiFi',
          'Power Outlets',
          'Quick Service',
          'Pastries',
          'Coffee',
        ],
        description:
            'Authentic Parisian café experience in the airport with fresh croissants, premium coffee, and a cozy atmosphere.',
        popularTimes: {'06:00': 80, '12:00': 90, '18:00': 70, '22:00': 30},
        averageSpend: '€8-15',
        specialties: ['Croissants', 'Espresso', 'Macarons', 'Quiche'],
        wifi: true,
        parking: false,
        coordinates: Coordinates(lat: 49.0043, lng: 2.5718),
      ),
      Place(
        id: '3',
        name: 'La Brasserie Air France',
        type: PlaceType.restaurant,
        rating: 4.1,
        reviewCount: 654,
        priceLevel: 3,
        distance: '0.3 km',
        walkTime: '5 min walk',
        openNow: true,
        openingHours: ['6:00 AM - 10:00 PM'],
        address: 'Terminal 2F, Charles de Gaulle Airport, Roissy-en-France',
        phoneNumber: '+33 1 48 16 58 00',
        website: 'airfrance-restaurants.com',
        photos: ['restaurant1.jpg', 'restaurant2.jpg'],
        amenities: [
          'Full Bar',
          'Table Service',
          'French Cuisine',
          'Wine Selection',
          'Business Seating',
        ],
        description:
            'Elegant French brasserie offering traditional cuisine and an extensive wine list. Perfect for a leisurely meal during long layovers.',
        popularTimes: {'06:00': 40, '12:00': 85, '18:00': 95, '22:00': 20},
        averageSpend: '€25-45',
        specialties: [
          'Coq au Vin',
          'French Onion Soup',
          'Cheese Selection',
          'Bordeaux Wines',
        ],
        wifi: true,
        parking: false,
        coordinates: Coordinates(lat: 49.0039, lng: 2.5725),
      ),
    ];
  }

  Future<List<NearbyUser>> getNearbyUsers(String airportCode) async {
    // Mock API call - replace with actual API
    await Future.delayed(const Duration(milliseconds: 800));

    return [
      NearbyUser(
        id: '1',
        name: 'Sophie Laurent',
        avatar: null,
        age: 29,
        nationality: 'French',
        currentLocation: 'Terminal 2E Lounge',
        distanceFromAirport: '0.1 km',
        interests: ['Food', 'Photography', 'Local Culture', 'Art'],
        isOnline: true,
        mutualConnections: 2,
        currentActivity: 'Having coffee at Café Paris',
        localRecommendations: [
          'Visit Montmartre',
          'Try macarons at Ladurée',
          'Seine river cruise',
        ],
      ),
      NearbyUser(
        id: '2',
        name: 'Pierre Dubois',
        avatar: null,
        age: 34,
        nationality: 'French',
        currentLocation: 'Sheraton Hotel Lobby',
        distanceFromAirport: '0.2 km',
        interests: ['Business', 'Wine', 'History', 'Architecture'],
        isOnline: true,
        mutualConnections: 1,
        currentActivity: 'Working in hotel business center',
        localRecommendations: [
          'Louvre Museum',
          'Wine tasting in Marais',
          'Notre-Dame area walk',
        ],
      ),
    ];
  }

  Future<void> connectWithUser(String userId) async {
    // Mock API call for connecting with user
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> getDirections(Place place) async {
    // Mock API call for getting directions
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
