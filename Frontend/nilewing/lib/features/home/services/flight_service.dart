// features/home/services/flight_service.dart
import '../model/home_model.dart';

class FlightService {
  static final FlightService _instance = FlightService._internal();
  factory FlightService() => _instance;
  FlightService._internal();

  // Get user's upcoming flight
  Future<Flight> getUserUpcomingFlight(String userId) async {
    // Simulate API delay
    await Future.delayed(Duration(milliseconds: 500));

    return Flight(
      flightNumber: "ET302",
      airline: "Ethiopian Airlines",
      route: "ADD → CDG",
      departure: FlightLeg(
        airport: "ADD",
        city: "Addis Ababa",
        time: "23:35",
        date: "Today",
        terminal: "T2",
      ),
      arrival: FlightLeg(
        airport: "CDG",
        city: "Paris",
        time: "06:50+1",
        date: "Tomorrow",
        terminal: "2E",
      ),
      duration: "7h 15m",
      aircraft: "Boeing 787-9",
      seat: "12A",
      gate: "B7",
      status: "On Time",
      checkInTime: "21:35",
      boardingTime: "23:00",
      timeUntilDeparture: "5h 23m",
    );
  }

  // Get community flight posts
  Future<List<FlightPost>> getFlightPosts({
    int page = 1,
    int limit = 10,
  }) async {
    // Simulate API delay
    await Future.delayed(Duration(milliseconds: 800));

    return [
      FlightPost(
        id: '1',
        user: PostUser(
          name: 'Sarah Mitchell',
          avatar: null,
          nationality: 'British',
        ),
        flight: PostFlight(number: 'LH440', route: 'FRA → JFK'),
        post: PostContent(
          title: 'Incredible sunset over the Atlantic ✈️',
          content:
              'Just caught the most breathtaking sunset on my flight from Frankfurt to New York! The view from 35,000 feet was absolutely magical...',
          fullContent:
              'Just caught the most breathtaking sunset on my flight from Frankfurt to New York! The view from 35,000 feet was absolutely magical. The sky was painted in shades of orange, pink, and purple that seemed almost unreal. I was seated by the window (always book window seats for long flights!), and for about 20 minutes, I was completely mesmerized by this natural spectacle. The crew on Lufthansa was fantastic - they even dimmed the cabin lights so passengers could enjoy the view better. Met some amazing fellow travelers too, including a photographer who shared some incredible tips about capturing aerial shots. These are the moments that remind me why I love traveling so much. There\'s something truly special about being suspended between earth and sky, watching the world transform beneath you. If you\'re flying this route, I highly recommend requesting a window seat on the right side of the aircraft for the best sunset views! #TravelMagic #LufthansaExperience #SunsetFromAbove',
          timestamp: '2 hours ago',
          likes: 127,
          comments: 23,
          isLiked: false,
          rating: 5,
        ),
      ),
      FlightPost(
        id: '2',
        user: PostUser(
          name: 'Ahmed Hassan',
          avatar: null,
          nationality: 'Egyptian',
        ),
        flight: PostFlight(number: 'EK203', route: 'DXB → LHR'),
        post: PostContent(
          title: 'Emirates A380 First Class Experience',
          content:
              'What an incredible journey! The Emirates A380 first class exceeded all expectations. The private suite, shower spa, and gourmet dining were outstanding...',
          fullContent:
              'What an incredible journey! The Emirates A380 first class exceeded all expectations. The private suite, shower spa, and gourmet dining were outstanding. From the moment I stepped into the private suite, I knew this was going to be a special flight. The suite felt more like a luxury hotel room than an airplane seat. The sliding doors provided complete privacy, and the 32-inch TV screen was perfect for the long flight entertainment. But the real highlight was the onboard shower spa - yes, you can actually take a shower at 40,000 feet! The experience was surreal and refreshing. The crew anticipated every need, and the sommelier helped me pair wines with the multi-course dinner prepared by renowned chefs. I had the Arabic mezze selection followed by the wagyu beef, and it was restaurant-quality food. The bed was incredibly comfortable with luxury linens, and I slept for 6 hours straight. Landing in London, I felt refreshed and ready to explore. Worth every penny for special occasions! The Emirates A380 truly redefines luxury travel. #EmiratesFirstClass #A380Experience #LuxuryTravel',
          timestamp: '6 hours ago',
          likes: 89,
          comments: 15,
          isLiked: true,
          rating: 5,
        ),
      ),
      FlightPost(
        id: '3',
        user: PostUser(
          name: 'Maria Rodriguez',
          avatar: null,
          nationality: 'Spanish',
        ),
        flight: PostFlight(number: 'IB6275', route: 'MAD → LAX'),
        post: PostContent(
          title: 'Long haul flight tips and cloud formations',
          content:
              'Flying from Madrid to LA and captured stunning cloud formations! Sharing my top tips for long-haul comfort...',
          fullContent:
              'Flying from Madrid to LA and captured stunning cloud formations! Sharing my top tips for long-haul comfort that I\'ve learned from years of international travel. First, hydration is key - I drink water constantly and avoid alcohol and too much caffeine. I bring my own water bottle and ask the crew to refill it regularly. Second, movement is crucial - I set a timer to walk the aisles every hour and do simple stretches in my seat. The Airbus A350 on this Iberia flight is incredibly quiet and comfortable, making the 12+ hour journey much more pleasant. The new premium economy seats have great legroom and adjustable headrests. Entertainment-wise, I downloaded several movies and podcasts before the flight, but honestly, spending time looking out the window was the best entertainment. We flew over the Pyrenees, the Atlantic, Greenland, and parts of Canada - each view was spectacular. The cloud formations over the Atlantic were like nothing I\'ve ever seen - towering cumulus clouds that looked like white mountains floating in the sky. Pro tip: bring your own snacks (nuts, energy bars), a good neck pillow, noise-canceling headphones, and layers for temperature changes. The crew was helpful throughout, and the meal service was excellent. Already planning my next adventure! #LongHaulTips #IberiaAirlines #CloudWatching',
          timestamp: '1 day ago',
          likes: 156,
          comments: 31,
          isLiked: false,
          rating: 4,
        ),
      ),
    ];
  }

  // Get pre-flight matches
  Future<Map<String, dynamic>> getPreFlightMatches(String userId) async {
    await Future.delayed(Duration(milliseconds: 300));

    return {
      'matchCount': 2,
      'matches': [
        {
          'name': 'Mariam from Kenya',
          'initials': 'MW',
          'route': 'Same flight DXB → LHR',
          'message': 'Looking for coffee companions during Dubai layover!',
          'matchScore': 88,
        },
      ],
      'commonRoute': 'Same route • Dubai layover',
    };
  }

  // Check in for flight
  Future<bool> checkInForFlight(String flightNumber, String userId) async {
    await Future.delayed(Duration(seconds: 2));
    // Simulate successful check-in
    return true;
  }

  // Get flight details
  Future<Map<String, dynamic>> getFlightDetails(String flightNumber) async {
    await Future.delayed(Duration(milliseconds: 400));

    return {
      'flightNumber': flightNumber,
      'status': 'On Time',
      'gate': 'B7',
      'terminal': 'T2',
      'boardingTime': '23:00',
      'duration': '7h 15m',
    };
  }
}
