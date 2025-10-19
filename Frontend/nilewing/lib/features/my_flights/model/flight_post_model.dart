// features/my_flights/models/flight_post_model.dart
import 'package:flutter/material.dart';
// REMOVE this conflicting import:
// import 'package:nilewing/features/home/model/home_model.dart' hide Flight, FlightLeg;
import 'package:nilewing/features/my_flights/model/flight_model.dart'; // Use only this one

class FlightPostData {
  String airlineName;
  String flightNumber;
  String departureTime;
  String departureDate;
  String departureAirport;
  String departureCity;
  String arrivalTime;
  String arrivalDate;
  String arrivalAirport;
  String arrivalCity;
  String transitTime;
  String transitAirport;
  String transitCity;
  String destinationPlace;
  bool isDelayed;
  String delayDuration;
  List<String> interests;
  String postTitle;
  String postContent;
  int rating;
  String aircraft;
  String seat;
  String gate;
  String terminal;
  bool hasLayover;
  String layoverDuration;
  List<String> layoverActivities;
  bool lookingForCompany;
  bool openToMeeting;
  String preferredGender;
  String travelExperience;
  bool isFirstInternationalFlight;
  bool needsGuidance;
  bool offeringGuidance;

  FlightPostData({
    this.airlineName = '',
    this.flightNumber = '',
    this.departureTime = '',
    this.departureDate = '',
    this.departureAirport = '',
    this.departureCity = '',
    this.arrivalTime = '',
    this.arrivalDate = '',
    this.arrivalAirport = '',
    this.arrivalCity = '',
    this.transitTime = '',
    this.transitAirport = '',
    this.transitCity = '',
    this.destinationPlace = '',
    this.isDelayed = false,
    this.delayDuration = '',
    List<String>? interests,
    this.postTitle = '',
    this.postContent = '',
    this.rating = 5,
    this.aircraft = '',
    this.seat = '',
    this.gate = '',
    this.terminal = '',
    this.hasLayover = false,
    this.layoverDuration = '',
    List<String>? layoverActivities,
    this.lookingForCompany = false,
    this.openToMeeting = true,
    this.preferredGender = 'Any',
    this.travelExperience = 'Occasional',
    this.isFirstInternationalFlight = false,
    this.needsGuidance = false,
    this.offeringGuidance = false,
  }) : interests = interests ?? [],
       layoverActivities = layoverActivities ?? [];

  // Convert to Flight model for saving
  Flight toFlight() {
    return Flight(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      flightNumber: flightNumber,
      airline: airlineName,
      route: '$departureAirport → $arrivalAirport',
      departure: FlightLeg(
        airport: departureAirport,
        city: departureCity,
        time: departureTime,
        date: departureDate,
        terminal: terminal,
      ),
      arrival: FlightLeg(
        airport: arrivalAirport,
        city: arrivalCity,
        time: arrivalTime,
        date: arrivalDate,
        terminal: terminal,
      ),
      duration: _calculateDuration(),
      aircraft: aircraft,
      seat: seat,
      gate: gate,
      status: FlightStatus.upcoming,
      delayTime: isDelayed ? delayDuration : null,
      transitTime: transitTime.isNotEmpty ? transitTime : null,
      transitAirport: transitAirport.isNotEmpty ? transitAirport : null,
      rating: rating,
      postTitle: postTitle.isNotEmpty ? postTitle : null,
      postContent: postContent.isNotEmpty ? postContent : null,
      likes: 0,
      comments: 0,
      hasPost: postTitle.isNotEmpty && postContent.isNotEmpty,
      isVisible: true,
    );
  }

  String _calculateDuration() {
    if (departureTime.isNotEmpty && arrivalTime.isNotEmpty) {
      return '${_parseTimeDifference(departureTime, arrivalTime)}h';
    }
    return '--';
  }

  String _parseTimeDifference(String depTime, String arrTime) {
    try {
      final dep = TimeOfDay(
        hour: int.parse(depTime.split(':')[0]),
        minute: int.parse(depTime.split(':')[1]),
      );
      final arr = TimeOfDay(
        hour: int.parse(arrTime.split(':')[0]),
        minute: int.parse(arrTime.split(':')[1]),
      );

      final depMinutes = dep.hour * 60 + dep.minute;
      final arrMinutes = arr.hour * 60 + arr.minute;
      var difference = arrMinutes - depMinutes;

      if (difference < 0) {
        difference += 24 * 60;
      }

      return (difference / 60).toStringAsFixed(1);
    } catch (e) {
      return '--';
    }
  }

  FlightPostData copyWith({
    String? airlineName,
    String? flightNumber,
    String? departureTime,
    String? departureDate,
    String? departureAirport,
    String? departureCity,
    String? arrivalTime,
    String? arrivalDate,
    String? arrivalAirport,
    String? arrivalCity,
    String? transitTime,
    String? transitAirport,
    String? transitCity,
    String? destinationPlace,
    bool? isDelayed,
    String? delayDuration,
    List<String>? interests,
    String? postTitle,
    String? postContent,
    int? rating,
    String? aircraft,
    String? seat,
    String? gate,
    String? terminal,
    bool? hasLayover,
    String? layoverDuration,
    List<String>? layoverActivities,
    bool? lookingForCompany,
    bool? openToMeeting,
    String? preferredGender,
    String? travelExperience,
    bool? isFirstInternationalFlight,
    bool? needsGuidance,
    bool? offeringGuidance,
  }) {
    return FlightPostData(
      airlineName: airlineName ?? this.airlineName,
      flightNumber: flightNumber ?? this.flightNumber,
      departureTime: departureTime ?? this.departureTime,
      departureDate: departureDate ?? this.departureDate,
      departureAirport: departureAirport ?? this.departureAirport,
      departureCity: departureCity ?? this.departureCity,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      arrivalAirport: arrivalAirport ?? this.arrivalAirport,
      arrivalCity: arrivalCity ?? this.arrivalCity,
      transitTime: transitTime ?? this.transitTime,
      transitAirport: transitAirport ?? this.transitAirport,
      transitCity: transitCity ?? this.transitCity,
      destinationPlace: destinationPlace ?? this.destinationPlace,
      isDelayed: isDelayed ?? this.isDelayed,
      delayDuration: delayDuration ?? this.delayDuration,
      interests: interests ?? this.interests,
      postTitle: postTitle ?? this.postTitle,
      postContent: postContent ?? this.postContent,
      rating: rating ?? this.rating,
      aircraft: aircraft ?? this.aircraft,
      seat: seat ?? this.seat,
      gate: gate ?? this.gate,
      terminal: terminal ?? this.terminal,
      hasLayover: hasLayover ?? this.hasLayover,
      layoverDuration: layoverDuration ?? this.layoverDuration,
      layoverActivities: layoverActivities ?? this.layoverActivities,
      lookingForCompany: lookingForCompany ?? this.lookingForCompany,
      openToMeeting: openToMeeting ?? this.openToMeeting,
      preferredGender: preferredGender ?? this.preferredGender,
      travelExperience: travelExperience ?? this.travelExperience,
      isFirstInternationalFlight:
          isFirstInternationalFlight ?? this.isFirstInternationalFlight,
      needsGuidance: needsGuidance ?? this.needsGuidance,
      offeringGuidance: offeringGuidance ?? this.offeringGuidance,
    );
  }
}

class Airport {
  final String code;
  final String name;
  final String city;
  final String country;
  final double? latitude;
  final double? longitude;

  Airport({
    required this.code,
    required this.name,
    required this.city,
    required this.country,
    this.latitude,
    this.longitude,
  });

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      code: json['airport_iata'] ?? json['iata_code'] ?? json['iata'] ?? '',
      name: json['airport_name'] ?? json['name'] ?? '',
      city: json['city_iata'] ?? json['city'] ?? json['municipality'] ?? '',
      country: json['country_name'] ?? json['country'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }

  @override
  String toString() => '$code - $city, $country';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Airport &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class AirportSearchResponse {
  final List<Airport> airports;
  final String? error;

  AirportSearchResponse({required this.airports, this.error});
}

// Constants
const List<String> popularAirlines = [
  'Ethiopian Airlines',
  'Air France',
  'Lufthansa',
  'Emirates',
  'British Airways',
  'KLM',
  'Turkish Airlines',
  'Qatar Airways',
  'Singapore Airlines',
  'Delta',
  'American Airlines',
  'United Airlines',
  'Swiss International',
  'Austrian Airlines',
  'Iberia',
  'Alitalia',
  'SAS',
  'Air Canada',
  'Japan Airlines',
  'Korean Air',
];

const List<String> travelInterests = [
  'Photography',
  'Food & Dining',
  'Culture',
  'Art & Museums',
  'Architecture',
  'Business Travel',
  'Adventure',
  'Nature',
  'Shopping',
  'Nightlife',
  'History',
  'Local Experiences',
  'Music',
  'Sports',
  'Technology',
  'Fashion',
  'Wine & Spirits',
  'Family Travel',
  'Solo Travel',
  'Luxury Travel',
];
