// features/my_flights/services/my_flights_service.dart
import '../model/flight_model.dart';

class MyFlightsService {
  static final MyFlightsService _instance = MyFlightsService._internal();
  factory MyFlightsService() => _instance;
  MyFlightsService._internal();

  // Get user's flights
  Future<List<Flight>> getUserFlights(String userId) async {
    await Future.delayed(Duration(milliseconds: 800));

    return [
      Flight(
        id: '1',
        flightNumber: 'ET302',
        airline: 'Ethiopian Airlines',
        route: 'ADD → CDG',
        departure: FlightLeg(
          airport: 'ADD',
          city: 'Addis Ababa',
          time: '23:35',
          date: 'Today',
          terminal: 'T2',
        ),
        arrival: FlightLeg(
          airport: 'CDG',
          city: 'Paris',
          time: '06:50+1',
          date: 'Tomorrow',
          terminal: '2E',
        ),
        duration: '7h 15m',
        aircraft: 'Boeing 787-9',
        seat: '12A',
        gate: 'B7',
        status: FlightStatus.upcoming,
        hasPost: false,
        isVisible: true,
      ),
      Flight(
        id: '2',
        flightNumber: 'AF1234',
        airline: 'Air France',
        route: 'CDG → JFK',
        departure: FlightLeg(
          airport: 'CDG',
          city: 'Paris',
          time: '14:30',
          date: 'Dec 28',
          terminal: '2E',
        ),
        arrival: FlightLeg(
          airport: 'JFK',
          city: 'New York',
          time: '17:45',
          date: 'Dec 28',
          terminal: '4',
        ),
        duration: '8h 15m',
        aircraft: 'Airbus A350',
        seat: '8C',
        gate: 'E12',
        status: FlightStatus.completed,
        rating: 5,
        postTitle: 'Amazing transatlantic flight experience!',
        postContent:
            'The Air France A350 service was exceptional. Great entertainment system and delicious meals...',
        likes: 45,
        comments: 12,
        hasPost: true,
        isVisible: true,
      ),
      Flight(
        id: '3',
        flightNumber: 'LH440',
        airline: 'Lufthansa',
        route: 'FRA → LAX',
        departure: FlightLeg(
          airport: 'FRA',
          city: 'Frankfurt',
          time: '11:20',
          date: 'Dec 15',
          terminal: '1',
        ),
        arrival: FlightLeg(
          airport: 'LAX',
          city: 'Los Angeles',
          time: '14:35',
          date: 'Dec 15',
          terminal: 'B',
        ),
        duration: '11h 15m',
        aircraft: 'Boeing 747-8',
        seat: '14K',
        gate: 'A23',
        status: FlightStatus.delayed,
        delayTime: '2h 30m',
        hasPost: false,
        isVisible: true,
      ),
      Flight(
        id: '4',
        flightNumber: 'EK203',
        airline: 'Emirates',
        route: 'DXB → LHR',
        departure: FlightLeg(
          airport: 'DXB',
          city: 'Dubai',
          time: '03:35',
          date: 'Dec 10',
          terminal: '3',
        ),
        arrival: FlightLeg(
          airport: 'LHR',
          city: 'London',
          time: '08:20',
          date: 'Dec 10',
          terminal: '3',
        ),
        duration: '7h 45m',
        aircraft: 'Airbus A380',
        seat: '2A',
        gate: 'A8',
        status: FlightStatus.completed,
        transitTime: '4h 20m',
        transitAirport: 'DXB',
        rating: 5,
        postTitle: 'Emirates A380 First Class - Worth Every Penny!',
        postContent:
            'Incredible shower spa, private suite, and world-class service. The onboard lounge was amazing...',
        likes: 127,
        comments: 28,
        hasPost: true,
        isVisible: true,
      ),
    ];
  }

  // Get flight details
  Future<FlightDetail> getFlightDetail(String flightId) async {
    await Future.delayed(Duration(milliseconds: 600));

    return FlightDetail(
      id: flightId,
      flightNumber: 'ET302',
      airline: 'Ethiopian Airlines',
      departure: FlightLegDetail(
        airport: 'ADD',
        city: 'Addis Ababa',
        country: 'Ethiopia',
        time: '23:35',
        date: 'Today, Dec 22',
        terminal: 'T2',
        gate: 'B7',
      ),
      arrival: FlightLegDetail(
        airport: 'CDG',
        city: 'Paris',
        country: 'France',
        time: '06:50+1',
        date: 'Tomorrow, Dec 23',
        terminal: '2E',
        gate: 'A12',
      ),
      duration: '7h 15m',
      aircraft: 'Boeing 787-9',
      seat: '12A',
      bookingReference: 'ET9X7K',
      eTicketNumber: '123-4567890123',
      status: 'On Time',
      flightClass: 'Economy',
      price: '\$675',
      baggage: Baggage(
        checkedBags: '1 x 23kg',
        carryOn: '1 x 8kg',
        personalItem: '1 x 3kg',
      ),
      passenger: Passenger(
        name: 'Markos Tesfaye',
        frequentFlyer: 'ShebaMiles Gold',
        specialRequests: ['Window Seat', 'Vegetarian Meal'],
      ),
      checkIn: CheckIn(
        opensAt: '21:35 (2 hours before)',
        closesAt: '22:35 (1 hour before)',
        status: 'Available',
      ),
      amenities: ['WiFi', 'Entertainment', 'Meals', 'USB Power'],
      timeline: [
        FlightTimeline(
          time: '21:35',
          event: 'Check-in opens',
          status: 'upcoming',
        ),
        FlightTimeline(
          time: '22:35',
          event: 'Check-in closes',
          status: 'upcoming',
        ),
        FlightTimeline(
          time: '23:00',
          event: 'Boarding begins',
          status: 'upcoming',
        ),
        FlightTimeline(time: '23:35', event: 'Departure', status: 'upcoming'),
      ],
    );
  }

  // Cancel flight
  Future<bool> cancelFlight(String flightId) async {
    await Future.delayed(Duration(seconds: 2));
    return true;
  }

  // Update flight delay
  Future<bool> updateFlightDelay(
    String flightId,
    DelayFormData delayData,
  ) async {
    await Future.delayed(Duration(seconds: 1));
    return true;
  }
}
