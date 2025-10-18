// features/my_flights/services/airport_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nilewing/features/my_flights/model/flight_post_model.dart';

class AirportService {
  // Primary API - AviationStack
  static const String _aviationStackBaseUrl = 'http://api.aviationstack.com/v1';
  static const String _aviationStackApiKey = '5bca662a2906d65143aaa6bdb8c3f1ef';

  // Local cache of major airports as fallback
  static final List<Airport> _majorAirports = [
    Airport(
      code: 'ATL',
      name: 'Hartsfield-Jackson Atlanta International',
      city: 'Atlanta',
      country: 'United States',
    ),
    Airport(
      code: 'PEK',
      name: 'Beijing Capital International Airport',
      city: 'Beijing',
      country: 'China',
    ),
    Airport(
      code: 'DXB',
      name: 'Dubai International Airport',
      city: 'Dubai',
      country: 'United Arab Emirates',
    ),
    Airport(
      code: 'LAX',
      name: 'Los Angeles International Airport',
      city: 'Los Angeles',
      country: 'United States',
    ),
    Airport(
      code: 'HND',
      name: 'Tokyo Haneda Airport',
      city: 'Tokyo',
      country: 'Japan',
    ),
    Airport(
      code: 'ORD',
      name: 'O\'Hare International Airport',
      city: 'Chicago',
      country: 'United States',
    ),
    Airport(
      code: 'LHR',
      name: 'Heathrow Airport',
      city: 'London',
      country: 'United Kingdom',
    ),
    Airport(
      code: 'PVG',
      name: 'Shanghai Pudong International Airport',
      city: 'Shanghai',
      country: 'China',
    ),
    Airport(
      code: 'CDG',
      name: 'Charles de Gaulle Airport',
      city: 'Paris',
      country: 'France',
    ),
    Airport(
      code: 'DFW',
      name: 'Dallas/Fort Worth International Airport',
      city: 'Dallas',
      country: 'United States',
    ),
    Airport(
      code: 'AMS',
      name: 'Amsterdam Airport Schiphol',
      city: 'Amsterdam',
      country: 'Netherlands',
    ),
    Airport(
      code: 'FRA',
      name: 'Frankfurt Airport',
      city: 'Frankfurt',
      country: 'Germany',
    ),
    Airport(
      code: 'IST',
      name: 'Istanbul Airport',
      city: 'Istanbul',
      country: 'Turkey',
    ),
    Airport(
      code: 'CAN',
      name: 'Guangzhou Baiyun International Airport',
      city: 'Guangzhou',
      country: 'China',
    ),
    Airport(
      code: 'JFK',
      name: 'John F. Kennedy International Airport',
      city: 'New York',
      country: 'United States',
    ),
    Airport(
      code: 'SIN',
      name: 'Singapore Changi Airport',
      city: 'Singapore',
      country: 'Singapore',
    ),
    Airport(
      code: 'DEN',
      name: 'Denver International Airport',
      city: 'Denver',
      country: 'United States',
    ),
    Airport(
      code: 'BKK',
      name: 'Suvarnabhumi Airport',
      city: 'Bangkok',
      country: 'Thailand',
    ),
    Airport(
      code: 'SFO',
      name: 'San Francisco International Airport',
      city: 'San Francisco',
      country: 'United States',
    ),
    Airport(
      code: 'ADD',
      name: 'Addis Ababa Bole International Airport',
      city: 'Addis Ababa',
      country: 'Ethiopia',
    ),
    Airport(
      code: 'NBO',
      name: 'Jomo Kenyatta International Airport',
      city: 'Nairobi',
      country: 'Kenya',
    ),
    Airport(
      code: 'JNB',
      name: 'O.R. Tambo International Airport',
      city: 'Johannesburg',
      country: 'South Africa',
    ),
    Airport(
      code: 'CAI',
      name: 'Cairo International Airport',
      city: 'Cairo',
      country: 'Egypt',
    ),
    Airport(
      code: 'MAD',
      name: 'Adolfo Suárez Madrid–Barajas Airport',
      city: 'Madrid',
      country: 'Spain',
    ),
    Airport(
      code: 'MUC',
      name: 'Munich Airport',
      city: 'Munich',
      country: 'Germany',
    ),
    Airport(
      code: 'YYZ',
      name: 'Toronto Pearson International Airport',
      city: 'Toronto',
      country: 'Canada',
    ),
    Airport(
      code: 'SYD',
      name: 'Sydney Kingsford Smith Airport',
      city: 'Sydney',
      country: 'Australia',
    ),
    Airport(
      code: 'ICN',
      name: 'Incheon International Airport',
      city: 'Seoul',
      country: 'South Korea',
    ),
    Airport(
      code: 'HKG',
      name: 'Hong Kong International Airport',
      city: 'Hong Kong',
      country: 'China',
    ),
    Airport(
      code: 'BOM',
      name: 'Chhatrapati Shivaji Maharaj International Airport',
      city: 'Mumbai',
      country: 'India',
    ),
  ];

  static Future<AirportSearchResponse> searchAirports(String query) async {
    try {
      if (query.length < 2) {
        return AirportSearchResponse(airports: _filterLocalAirports(query));
      }

      // Try AviationStack API
      final response = await http.get(
        Uri.parse(
          '$_aviationStackBaseUrl/airports?access_key=$_aviationStackApiKey&search=$query',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          final airports = (data['data'] as List)
              .map((json) => Airport.fromJson(json))
              .where(
                (airport) => airport.code.isNotEmpty && airport.code != 'null',
              )
              .take(20)
              .toList();

          if (airports.isNotEmpty) {
            return AirportSearchResponse(airports: airports);
          }
        }
      }

      // Fallback to local data with fuzzy search
      return AirportSearchResponse(airports: _filterLocalAirports(query));
    } catch (e) {
      // Final fallback to local data
      return AirportSearchResponse(
        airports: _filterLocalAirports(query),
        error: 'Using local airport database',
      );
    }
  }

  // Get airlines from AviationStack API
  static Future<List<String>> getAirlines({String query = ''}) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_aviationStackBaseUrl/airlines?access_key=$_aviationStackApiKey${query.isNotEmpty ? '&search=$query' : ''}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'] is List) {
          final airlines = (data['data'] as List)
              .where(
                (airline) =>
                    airline['airline_name'] != null &&
                    airline['airline_name'].toString().isNotEmpty &&
                    airline['iata_code'] != null &&
                    airline['iata_code'].toString().isNotEmpty,
              )
              .map(
                (airline) =>
                    '${airline['airline_name']} (${airline['iata_code']})',
              )
              .take(50)
              .toList();

          if (airlines.isNotEmpty) {
            return airlines;
          }
        }
      }

      // Fallback to popular airlines
      return popularAirlines;
    } catch (e) {
      return popularAirlines;
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
    // Try to get updated popular airports from API
    try {
      final response = await searchAirports('');
      if (response.airports.isNotEmpty) {
        return response.airports;
      }
    } catch (e) {
      // Fallback to local data
    }

    return _majorAirports;
  }
}
