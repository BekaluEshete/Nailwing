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

  // Sample airport list (replace with your actual list)
  static final List<Airport> _majorAirports = [
    Airport(
      code: 'ATL',
      name: 'Hartsfield-Jackson Atlanta International',
      city: 'Atlanta',
      country: 'United States',
    ),
    Airport(
      code: 'LAX',
      name: 'Los Angeles International',
      city: 'Los Angeles',
      country: 'United States',
    ),
    Airport(
      code: 'LHR',
      name: 'London Heathrow',
      city: 'London',
      country: 'United Kingdom',
    ),
    Airport(
      code: 'ADD',
      name: 'Addis Ababa Bole International',
      city: 'Addis Ababa',
      country: 'Ethiopia',
    ),
    // Add more airports as needed
  ];
}
