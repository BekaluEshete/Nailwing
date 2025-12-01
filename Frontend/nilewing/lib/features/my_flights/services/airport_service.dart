import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/flight_post_model.dart'; // Adjust path as needed

class AirportService {
  // Cache for airlines
  static List<String>? _cachedAirlines;

  // Hardcoded fallback list
  static final List<String> popularAirlines = [
    'American Airlines (AA)',
    'Delta Air Lines (DL)',
    'United Airlines (UA)',
    'Ethiopian Airlines (ET)',
    'Emirates (EK)',
    'British Airways (BA)',
    'Lufthansa (LH)',
    'Singapore Airlines (SQ)',
    'Qatar Airways (QR)',
    'Air France (AF)',
  ];

  // Load and filter airlines from CSV
  static Future<List<String>> getAirlines({String query = ''}) async {
    if (_cachedAirlines != null && _cachedAirlines!.isNotEmpty) {
      print('Using cached airlines: ${_cachedAirlines!.length} airlines');
      return _filterAirlines(_cachedAirlines!, query);
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList('airlines');
    if (cached != null && cached.isNotEmpty) {
      _cachedAirlines = cached;
      print('Loaded ${cached.length} airlines from cache');
      return _filterAirlines(cached, query);
    }

    try {
      final csvString = await rootBundle.loadString('assets/airlines.dat');
      final csv = const CsvToListConverter().convert(csvString);
      final airlines = <String>[];

      for (var row in csv) {
        // Validate row has enough columns and is well-formed
        if (row.length >= 8 &&
            row[1] != null && // Name
            row[1].toString().isNotEmpty &&
            row[3] != null && // IATA code
            row[3].toString().isNotEmpty &&
            row[3] != '-' &&
            row[7] == 'Y') {
          // Active
          final airline = '${row[1]} (${row[3]})';
          airlines.add(airline);
        } else {
          print('Skipping invalid CSV row: $row');
        }
      }

      if (airlines.isEmpty) {
        print('No valid airlines found in CSV');
        return _filterAirlines(popularAirlines, query);
      }

      _cachedAirlines = airlines;
      await prefs.setStringList('airlines', airlines); // Save to cache
      print('Loaded ${airlines.length} airlines from CSV');
      return _filterAirlines(airlines, query);
    } catch (e) {
      print('Error loading airlines from CSV: $e');
      return _filterAirlines(popularAirlines, query);
    }
  }

  // Filter airlines locally
  static List<String> _filterAirlines(List<String> airlines, String query) {
    if (query.isEmpty) {
      print('Returning ${airlines.length} airlines (no query)');
      return airlines;
    }
    final lowercaseQuery = query.toLowerCase();
    final filtered = airlines
        .where((airline) => airline.toLowerCase().contains(lowercaseQuery))
        .toList();
    print('Filtered ${filtered.length} airlines for query: $query');
    return filtered;
  }

  // Existing airport-related methods
  static Future<AirportSearchResponse> searchAirports(String query) async {
    try {
      if (query.length < 2) {
        return AirportSearchResponse(airports: _filterLocalAirports(query));
      }
      return AirportSearchResponse(airports: _filterLocalAirports(query));
    } catch (e) {
      print('Error searching airports: $e');
      return AirportSearchResponse(
        airports: _filterLocalAirports(query),
        error: 'Using local airport database',
      );
    }
  }

  static List<Airport> _filterLocalAirports(String query) {
    if (query.isEmpty) {
      return _majorAirports;
    }
    final lowercaseQuery = query.toLowerCase();
    return _majorAirports.where((airport) {
      return airport.code.toLowerCase().contains(lowercaseQuery) ||
          airport.city.toLowerCase().contains(lowercaseQuery) ||
          airport.name.toLowerCase().contains(lowercaseQuery) ||
          airport.country.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  static Future<List<Airport>> getPopularAirports() async {
    return _majorAirports;
  }

  // Comprehensive airport list with major airports worldwide
  static final List<Airport> _majorAirports = [
    // United States
    Airport(code: 'ATL', name: 'Hartsfield-Jackson Atlanta International', city: 'Atlanta', country: 'United States'),
    Airport(code: 'LAX', name: 'Los Angeles International', city: 'Los Angeles', country: 'United States'),
    Airport(code: 'ORD', name: 'Chicago O\'Hare International', city: 'Chicago', country: 'United States'),
    Airport(code: 'DFW', name: 'Dallas/Fort Worth International', city: 'Dallas', country: 'United States'),
    Airport(code: 'DEN', name: 'Denver International', city: 'Denver', country: 'United States'),
    Airport(code: 'JFK', name: 'John F. Kennedy International', city: 'New York', country: 'United States'),
    Airport(code: 'SFO', name: 'San Francisco International', city: 'San Francisco', country: 'United States'),
    Airport(code: 'SEA', name: 'Seattle-Tacoma International', city: 'Seattle', country: 'United States'),
    Airport(code: 'LAS', name: 'McCarran International', city: 'Las Vegas', country: 'United States'),
    Airport(code: 'MIA', name: 'Miami International', city: 'Miami', country: 'United States'),
    Airport(code: 'BOS', name: 'Logan International', city: 'Boston', country: 'United States'),
    Airport(code: 'PHX', name: 'Phoenix Sky Harbor International', city: 'Phoenix', country: 'United States'),
    Airport(code: 'EWR', name: 'Newark Liberty International', city: 'Newark', country: 'United States'),
    Airport(code: 'IAH', name: 'George Bush Intercontinental', city: 'Houston', country: 'United States'),
    Airport(code: 'MCO', name: 'Orlando International', city: 'Orlando', country: 'United States'),
    
    // United Kingdom & Europe
    Airport(code: 'LHR', name: 'London Heathrow', city: 'London', country: 'United Kingdom'),
    Airport(code: 'LGW', name: 'London Gatwick', city: 'London', country: 'United Kingdom'),
    Airport(code: 'CDG', name: 'Charles de Gaulle', city: 'Paris', country: 'France'),
    Airport(code: 'ORY', name: 'Paris Orly', city: 'Paris', country: 'France'),
    Airport(code: 'FRA', name: 'Frankfurt Airport', city: 'Frankfurt', country: 'Germany'),
    Airport(code: 'MUC', name: 'Munich Airport', city: 'Munich', country: 'Germany'),
    Airport(code: 'AMS', name: 'Amsterdam Airport Schiphol', city: 'Amsterdam', country: 'Netherlands'),
    Airport(code: 'FCO', name: 'Leonardo da Vinci-Fiumicino', city: 'Rome', country: 'Italy'),
    Airport(code: 'MXP', name: 'Milan Malpensa', city: 'Milan', country: 'Italy'),
    Airport(code: 'MAD', name: 'Madrid-Barajas', city: 'Madrid', country: 'Spain'),
    Airport(code: 'BCN', name: 'Barcelona-El Prat', city: 'Barcelona', country: 'Spain'),
    Airport(code: 'IST', name: 'Istanbul Airport', city: 'Istanbul', country: 'Turkey'),
    Airport(code: 'ZUR', name: 'Zurich Airport', city: 'Zurich', country: 'Switzerland'),
    Airport(code: 'VIE', name: 'Vienna International', city: 'Vienna', country: 'Austria'),
    Airport(code: 'BRU', name: 'Brussels Airport', city: 'Brussels', country: 'Belgium'),
    Airport(code: 'CPH', name: 'Copenhagen Airport', city: 'Copenhagen', country: 'Denmark'),
    Airport(code: 'ARN', name: 'Stockholm Arlanda', city: 'Stockholm', country: 'Sweden'),
    Airport(code: 'OSL', name: 'Oslo Gardermoen', city: 'Oslo', country: 'Norway'),
    Airport(code: 'HEL', name: 'Helsinki-Vantaa', city: 'Helsinki', country: 'Finland'),
    Airport(code: 'DUB', name: 'Dublin Airport', city: 'Dublin', country: 'Ireland'),
    Airport(code: 'ATH', name: 'Athens International', city: 'Athens', country: 'Greece'),
    Airport(code: 'LIS', name: 'Lisbon Portela', city: 'Lisbon', country: 'Portugal'),
    
    // Middle East
    Airport(code: 'DXB', name: 'Dubai International', city: 'Dubai', country: 'United Arab Emirates'),
    Airport(code: 'AUH', name: 'Abu Dhabi International', city: 'Abu Dhabi', country: 'United Arab Emirates'),
    Airport(code: 'DOH', name: 'Hamad International', city: 'Doha', country: 'Qatar'),
    Airport(code: 'BAH', name: 'Bahrain International', city: 'Manama', country: 'Bahrain'),
    Airport(code: 'KWI', name: 'Kuwait International', city: 'Kuwait City', country: 'Kuwait'),
    Airport(code: 'RUH', name: 'King Khalid International', city: 'Riyadh', country: 'Saudi Arabia'),
    Airport(code: 'JED', name: 'King Abdulaziz International', city: 'Jeddah', country: 'Saudi Arabia'),
    Airport(code: 'TLV', name: 'Ben Gurion', city: 'Tel Aviv', country: 'Israel'),
    
    // Asia Pacific
    Airport(code: 'PEK', name: 'Beijing Capital International', city: 'Beijing', country: 'China'),
    Airport(code: 'PVG', name: 'Shanghai Pudong International', city: 'Shanghai', country: 'China'),
    Airport(code: 'CAN', name: 'Guangzhou Baiyun International', city: 'Guangzhou', country: 'China'),
    Airport(code: 'SZX', name: 'Shenzhen Bao\'an International', city: 'Shenzhen', country: 'China'),
    Airport(code: 'HKG', name: 'Hong Kong International', city: 'Hong Kong', country: 'Hong Kong'),
    Airport(code: 'NRT', name: 'Narita International', city: 'Tokyo', country: 'Japan'),
    Airport(code: 'HND', name: 'Tokyo Haneda', city: 'Tokyo', country: 'Japan'),
    Airport(code: 'ICN', name: 'Incheon International', city: 'Seoul', country: 'South Korea'),
    Airport(code: 'SIN', name: 'Singapore Changi', city: 'Singapore', country: 'Singapore'),
    Airport(code: 'BKK', name: 'Suvarnabhumi', city: 'Bangkok', country: 'Thailand'),
    Airport(code: 'KUL', name: 'Kuala Lumpur International', city: 'Kuala Lumpur', country: 'Malaysia'),
    Airport(code: 'CGK', name: 'Soekarno-Hatta International', city: 'Jakarta', country: 'Indonesia'),
    Airport(code: 'MNL', name: 'Ninoy Aquino International', city: 'Manila', country: 'Philippines'),
    Airport(code: 'DEL', name: 'Indira Gandhi International', city: 'New Delhi', country: 'India'),
    Airport(code: 'BOM', name: 'Chhatrapati Shivaji Maharaj International', city: 'Mumbai', country: 'India'),
    Airport(code: 'BLR', name: 'Kempegowda International', city: 'Bangalore', country: 'India'),
    Airport(code: 'SYD', name: 'Sydney Kingsford Smith', city: 'Sydney', country: 'Australia'),
    Airport(code: 'MEL', name: 'Melbourne Airport', city: 'Melbourne', country: 'Australia'),
    Airport(code: 'BNE', name: 'Brisbane Airport', city: 'Brisbane', country: 'Australia'),
    Airport(code: 'PER', name: 'Perth Airport', city: 'Perth', country: 'Australia'),
    Airport(code: 'AKL', name: 'Auckland Airport', city: 'Auckland', country: 'New Zealand'),
    
    // Africa
    Airport(code: 'ADD', name: 'Addis Ababa Bole International', city: 'Addis Ababa', country: 'Ethiopia'),
    Airport(code: 'JNB', name: 'O.R. Tambo International', city: 'Johannesburg', country: 'South Africa'),
    Airport(code: 'CPT', name: 'Cape Town International', city: 'Cape Town', country: 'South Africa'),
    Airport(code: 'CAI', name: 'Cairo International', city: 'Cairo', country: 'Egypt'),
    Airport(code: 'NBO', name: 'Jomo Kenyatta International', city: 'Nairobi', country: 'Kenya'),
    Airport(code: 'LAD', name: 'Quatro de Fevereiro', city: 'Luanda', country: 'Angola'),
    Airport(code: 'LOS', name: 'Murtala Muhammed International', city: 'Lagos', country: 'Nigeria'),
    Airport(code: 'CMN', name: 'Mohammed V International', city: 'Casablanca', country: 'Morocco'),
    Airport(code: 'TUN', name: 'Tunis-Carthage International', city: 'Tunis', country: 'Tunisia'),
    Airport(code: 'DAR', name: 'Julius Nyerere International', city: 'Dar es Salaam', country: 'Tanzania'),
    
    // Latin America & Caribbean
    Airport(code: 'GRU', name: 'São Paulo/Guarulhos International', city: 'São Paulo', country: 'Brazil'),
    Airport(code: 'GIG', name: 'Rio de Janeiro-Galeão International', city: 'Rio de Janeiro', country: 'Brazil'),
    Airport(code: 'MEX', name: 'Mexico City International', city: 'Mexico City', country: 'Mexico'),
    Airport(code: 'CUN', name: 'Cancún International', city: 'Cancún', country: 'Mexico'),
    Airport(code: 'EZE', name: 'Ministro Pistarini International', city: 'Buenos Aires', country: 'Argentina'),
    Airport(code: 'SCL', name: 'Arturo Merino Benítez International', city: 'Santiago', country: 'Chile'),
    Airport(code: 'BOG', name: 'El Dorado International', city: 'Bogotá', country: 'Colombia'),
    Airport(code: 'LIM', name: 'Jorge Chávez International', city: 'Lima', country: 'Peru'),
    Airport(code: 'PTY', name: 'Tocumen International', city: 'Panama City', country: 'Panama'),
    
    // Canada
    Airport(code: 'YYZ', name: 'Toronto Pearson International', city: 'Toronto', country: 'Canada'),
    Airport(code: 'YVR', name: 'Vancouver International', city: 'Vancouver', country: 'Canada'),
    Airport(code: 'YUL', name: 'Montréal-Trudeau International', city: 'Montréal', country: 'Canada'),
    Airport(code: 'YYC', name: 'Calgary International', city: 'Calgary', country: 'Canada'),
  ];
}
