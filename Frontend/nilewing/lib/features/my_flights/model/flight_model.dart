// features/my_flights/model/my_flights_model.dart
class Flight {
  final String id;
  final String flightNumber;
  final String airline;
  final String route;
  final FlightLeg departure;
  final FlightLeg arrival;
  final String duration;
  final String aircraft;
  final String seat;
  final String gate;
  final FlightStatus status;
  final String? delayTime;
  final String? transitTime;
  final String? transitAirport;
  final int? rating;
  final String? postTitle;
  final String? postContent;
  final int? likes;
  final int? comments;
  final bool hasPost;
  final bool isVisible;

  Flight({
    required this.id,
    required this.flightNumber,
    required this.airline,
    required this.route,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.aircraft,
    required this.seat,
    required this.gate,
    required this.status,
    this.delayTime,
    this.transitTime,
    this.transitAirport,
    this.rating,
    this.postTitle,
    this.postContent,
    this.likes,
    this.comments,
    required this.hasPost,
    required this.isVisible,
  });
}

class FlightLeg {
  final String airport;
  final String city;
  final String time;
  final String date;
  final String terminal;

  FlightLeg({
    required this.airport,
    required this.city,
    required this.time,
    required this.date,
    required this.terminal,
  });
}

enum FlightStatus { upcoming, boarding, delayed, completed, cancelled }

class DelayFormData {
  String newDepartureTime;
  String newArrivalTime;
  String delayReason;
  String delayDuration;

  DelayFormData({
    this.newDepartureTime = '',
    this.newArrivalTime = '',
    this.delayReason = '',
    this.delayDuration = '',
  });
}

class FlightDetail {
  final String id;
  final String flightNumber;
  final String airline;
  final FlightLegDetail departure;
  final FlightLegDetail arrival;
  final String duration;
  final String aircraft;
  final String seat;
  final String bookingReference;
  final String eTicketNumber;
  final String status;
  final String flightClass;
  final String price;
  final Baggage baggage;
  final Passenger passenger;
  final CheckIn checkIn;
  final List<String> amenities;
  final List<FlightTimeline> timeline;

  FlightDetail({
    required this.id,
    required this.flightNumber,
    required this.airline,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.aircraft,
    required this.seat,
    required this.bookingReference,
    required this.eTicketNumber,
    required this.status,
    required this.flightClass,
    required this.price,
    required this.baggage,
    required this.passenger,
    required this.checkIn,
    required this.amenities,
    required this.timeline,
  });
}

class FlightLegDetail {
  final String airport;
  final String city;
  final String country;
  final String time;
  final String date;
  final String terminal;
  final String gate;

  FlightLegDetail({
    required this.airport,
    required this.city,
    required this.country,
    required this.time,
    required this.date,
    required this.terminal,
    required this.gate,
  });
}

class Baggage {
  final String checkedBags;
  final String carryOn;
  final String personalItem;

  Baggage({
    required this.checkedBags,
    required this.carryOn,
    required this.personalItem,
  });
}

class Passenger {
  final String name;
  final String frequentFlyer;
  final List<String> specialRequests;

  Passenger({
    required this.name,
    required this.frequentFlyer,
    required this.specialRequests,
  });
}

class CheckIn {
  final String opensAt;
  final String closesAt;
  final String status;

  CheckIn({
    required this.opensAt,
    required this.closesAt,
    required this.status,
  });
}

class FlightTimeline {
  final String time;
  final String event;
  final String status;

  FlightTimeline({
    required this.time,
    required this.event,
    required this.status,
  });
}
