import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../model/flight_post_model.dart'; // Adjust path as needed

class AirportService {
  // Cache for airlines
  static List<String>? _cachedAirlines;
  
  // Cache for airports loaded from CSV
  static List<Airport>? _cachedAirports;

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
  
  // Helper to clean string values from CSV
  static String? _cleanString(dynamic value) {
    if (value == null) return null;
    try {
      final str = value.toString().trim();
      if (str.isEmpty || str == '\\N' || str == 'N/A' || str.toLowerCase() == 'null') {
        return null;
      }
      // Remove quotes if present
      return str.replaceAll('"', '').trim();
    } catch (e) {
      return null;
    }
  }
  
  // Helper to safely get CSV row value
  static dynamic _safeGetRowValue(List<dynamic> row, int index) {
    if (row == null || index < 0 || index >= row.length) {
      return null;
    }
    try {
      return row[index];
    } catch (e) {
      return null;
    }
  }

  // Load airports from API and cache
  static Future<List<Airport>> _loadAirportsFromAPI({bool forceRefresh = false}) async {
    if (forceRefresh) {
      print('🔄 Force refresh requested - clearing cache...');
      _cachedAirports = null;
      await clearAirportCache();
    } else if (_cachedAirports != null && _cachedAirports!.isNotEmpty) {
      // Validate cache quality - if less than 100 airports, it's invalid
      if (_cachedAirports!.length >= 100) {
        print('✅ Using in-memory cached airports: ${_cachedAirports!.length} airports');
        return _cachedAirports!;
      } else {
        print('⚠️ Invalid in-memory cache detected (${_cachedAirports!.length} airports), forcing refresh...');
        _cachedAirports = null;
        await clearAirportCache();
        forceRefresh = true; // Force refresh after clearing
      }
    }

    // Try to load from SharedPreferences cache first
    final prefs = await SharedPreferences.getInstance();
    try {
      final cachedJson = prefs.getString('airports_cache');
      final cacheTimestamp = prefs.getInt('airports_cache_timestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      // Cache valid for 7 days
      final cacheValidDuration = 7 * 24 * 60 * 60 * 1000;
      
      if (cachedJson != null && 
          cachedJson.isNotEmpty && 
          (now - cacheTimestamp) < cacheValidDuration) {
        final List<dynamic> cached = json.decode(cachedJson);
        final cachedAirportsList = cached.map((item) => Airport(
          code: item['code'] ?? '',
          name: item['name'] ?? '',
          city: item['city'] ?? '',
          country: item['country'] ?? '',
        )).where((a) => a.code.isNotEmpty).toList();
        
        // If cache has too few airports (< 100), it's invalid - force refresh
        if (cachedAirportsList.length < 100) {
          print('⚠️ Cache has only ${cachedAirportsList.length} airports, forcing refresh...');
          await clearAirportCache();
        } else {
          _cachedAirports = cachedAirportsList;
          print('✅ Loaded ${_cachedAirports!.length} airports from cache');
          return _cachedAirports!;
        }
      }
    } catch (e) {
      print('⚠️ Error loading airports from cache: $e');
      // Clear bad cache
      await clearAirportCache();
    }

    // Try to fetch from free public airport APIs
    try {
      print('🌐 Fetching airports from API...');
      
      // Method 1: Try OpenFlights GitHub (primary source)
      List<Airport>? airports = await _fetchFromApiNinjas();
      
      // Method 2: Try public GitHub-hosted JSON as fallback
      if (airports == null || airports.isEmpty || airports.length < 100) {
        print('🔄 Trying public JSON endpoint...');
        airports = await _fetchFromPublicJSON();
      }
      
      // Method 3: Try RapidAPI free endpoint as last resort
      if (airports == null || airports.isEmpty || airports.length < 100) {
        airports = await _fetchFromRapidAPI();
      }

      if (airports != null && airports.isNotEmpty) {
        // Remove duplicates (by IATA code)
        final uniqueAirports = <String, Airport>{};
        for (var airport in airports) {
          if (airport.code.isNotEmpty && !uniqueAirports.containsKey(airport.code)) {
            uniqueAirports[airport.code] = airport;
          }
        }
        final deduplicated = uniqueAirports.values.toList();
        
        // Sort by airport code for better UX
        deduplicated.sort((a, b) => a.code.compareTo(b.code));
        
        _cachedAirports = deduplicated;
        
        // Cache in SharedPreferences as JSON
        final airportsJson = json.encode(deduplicated.map((a) => {
          'code': a.code,
          'name': a.name,
          'city': a.city,
          'country': a.country,
        }).toList());
        await prefs.setString('airports_cache', airportsJson);
        await prefs.setInt('airports_cache_timestamp', DateTime.now().millisecondsSinceEpoch);
        
        print('✅ Loaded ${deduplicated.length} unique airports from API');
        return deduplicated;
      }
    } catch (e) {
      print('⚠️ Error loading airports from API: $e');
    }

    // Fallback to hardcoded list
    print('⚠️ Using hardcoded airport list as fallback');
    _cachedAirports = _majorAirports;
    return _majorAirports;
  }
  
  // Fetch from API Ninjas (free tier)
  static Future<List<Airport>?> _fetchFromApiNinjas() async {
    try {
      // API Ninjas has a free tier - we can fetch all airports
      // Using a public JSON endpoint that doesn't require API key
      final response = await http.get(
        Uri.parse('https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat'),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final csvString = response.body;
        print('📥 Received ${csvString.length} characters from OpenFlights API');
        
        final csv = const CsvToListConverter(
          eol: '\n',
          fieldDelimiter: ',',
          textDelimiter: '"',
          textEndDelimiter: '"',
        ).convert(csvString);
        
        print('📊 Parsed ${csv.length} CSV rows');
        
        final airports = <Airport>[];
        int validCount = 0;
        int skippedCount = 0;
        
        for (var row in csv) {
          try {
            // Skip null or empty rows
            if (row == null || !(row is List) || row.isEmpty) {
              skippedCount++;
              continue;
            }
            
            // Safely check row length and access indices
            if (row.length >= 6) {
              // Use safe getter to access array indices
              final iataCode = _cleanString(_safeGetRowValue(row, 4));
              final name = _cleanString(_safeGetRowValue(row, 1)) ?? '';
              final city = _cleanString(_safeGetRowValue(row, 2)) ?? '';
              final country = _cleanString(_safeGetRowValue(row, 3)) ?? '';
              
              if (iataCode != null && 
                  iataCode.isNotEmpty &&
                  iataCode.length == 3 && 
                  iataCode != 'N/A' &&
                  iataCode != '\\N' &&
                  !iataCode.contains('null') &&
                  name.isNotEmpty) {
                airports.add(Airport(
                  code: iataCode.toUpperCase(),
                  name: name,
                  city: city.isNotEmpty ? city : name,
                  country: country.isNotEmpty ? country : 'Unknown',
                ));
                validCount++;
              } else {
                skippedCount++;
              }
            } else {
              skippedCount++;
            }
          } catch (e) {
            skippedCount++;
            // Log error for debugging but continue
            if (skippedCount % 100 == 0) {
              print('⚠️ Skipped $skippedCount rows so far (last error: $e)');
            }
            continue;
          }
        }
        
        print('✅ Valid airports: $validCount, Skipped: $skippedCount');
        
        if (airports.length >= 100) {
          print('✅ Fetched ${airports.length} airports from OpenFlights GitHub');
          return airports;
        } else {
          print('⚠️ Only ${airports.length} valid airports found (expected 100+), trying next source...');
        }
      } else {
        print('⚠️ OpenFlights API returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error fetching from OpenFlights: $e');
    }
    return null;
  }
  
  // Fetch from RapidAPI (alternative)
  static Future<List<Airport>?> _fetchFromRapidAPI() async {
    // RapidAPI endpoints typically require API keys
    // This is a placeholder for future implementation
    return null;
  }
  
  // Fetch from public JSON endpoint
  static Future<List<Airport>?> _fetchFromPublicJSON() async {
    try {
      // Try a public JSON endpoint with airport data
      final response = await http.get(
        Uri.parse('https://raw.githubusercontent.com/mwgg/Airports/master/airports.json'),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final airports = <Airport>[];
        
        data.forEach((code, airportData) {
          try {
            if (airportData is Map && 
                code.length == 3 && 
                airportData['name'] != null) {
              airports.add(Airport(
                code: code.toUpperCase(),
                name: airportData['name'] ?? '',
                city: airportData['city'] ?? airportData['name'] ?? '',
                country: airportData['country'] ?? 'Unknown',
              ));
            }
          } catch (e) {
            // Skip invalid entries
          }
        });
        
        if (airports.isNotEmpty) {
          print('✅ Fetched ${airports.length} airports from public JSON');
          return airports;
        }
      }
    } catch (e) {
      print('⚠️ Error fetching from public JSON: $e');
    }
    return null;
  }
  

  // Existing airport-related methods
  static Future<AirportSearchResponse> searchAirports(String query) async {
    try {
      final allAirports = await _loadAirportsFromAPI();
      print('🔍 Searching through ${allAirports.length} total airports');
      
      List<Airport> filtered;
      if (query.isEmpty) {
        // Show ALL airports when no query (user can scroll/search)
        // No limit - show everything for maximum selection
        filtered = allAirports;
      } else {
        // Search through ALL airports when user types
        filtered = _filterAirports(allAirports, query);
        print('🔍 Found ${filtered.length} airports matching "$query"');
      }
      return AirportSearchResponse(airports: filtered);
    } catch (e) {
      print('❌ Error searching airports: $e');
      return AirportSearchResponse(
        airports: _filterAirports(_majorAirports, query),
        error: 'Using fallback airport database',
      );
    }
  }

  static List<Airport> _filterAirports(List<Airport> airports, String query) {
    if (query.isEmpty) {
      // Return ALL airports when no query - no limit
      return airports;
    }
    final lowercaseQuery = query.toLowerCase();
    return airports.where((airport) {
      return airport.code.toLowerCase().contains(lowercaseQuery) ||
          airport.city.toLowerCase().contains(lowercaseQuery) ||
          airport.name.toLowerCase().contains(lowercaseQuery) ||
          airport.country.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  static Future<List<Airport>> getPopularAirports() async {
    final allAirports = await _loadAirportsFromAPI();
    // Return ALL airports for initial display - no limit
    // Users can scroll or search to find specific airports
    return allAirports;
  }

  // Get all airports (for searching - no limit)
  static Future<List<Airport>> getAllAirports() async {
    return await _loadAirportsFromAPI();
  }
  
  // Clear airport cache to force fresh fetch
  static Future<void> clearAirportCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('airports_cache');
    await prefs.remove('airports_cache_timestamp');
    _cachedAirports = null;
    print('🗑️ Airport cache cleared');
  }
  
  // Force refresh airports from API (clears cache and fetches fresh)
  static Future<List<Airport>> forceRefreshAirports() async {
    print('🔄 Forcing airport refresh from API...');
    await clearAirportCache();
    return await _loadAirportsFromAPI();
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
