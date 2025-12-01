# Airport CSV File Setup

## Overview
The airport dropdowns (departure, arrival, and transit) now load airports from a CSV file to provide comprehensive worldwide airport coverage.

## Airport CSV File Format

The airports are loaded from `assets/airports.dat` file using the OpenFlights database format:

**File Format:**
- CSV format with the following columns:
  0. Airport ID
  1. Name
  2. City
  3. Country
  4. IATA (3-letter code)
  5. ICAO (4-letter code)
  6. Latitude
  7. Longitude
  8. Altitude
  9. Timezone
  10. DST
  11. Tz database time zone
  12. Type
  13. Source

**Example row:**
```
1,"Goroka Airport","Goroka","Papua New Guinea","GKA","AYGA",-6.081689,145.391881,5282,10,"U","Pacific/Port_Moresby","airport","OurAirports"
```

## Where to Get the Airport Data

You can download the airports.dat file from:
- **OpenFlights Database**: https://openflights.org/data.html
- Direct download: https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat

## Installation Steps

1. Download the `airports.dat` file from OpenFlights
2. Place it in `Frontend/nilewing/assets/airports.dat`
3. The file is already configured in `pubspec.yaml`

## Fallback Behavior

If the `airports.dat` file is not available:
- The system will fall back to a hardcoded list of 100+ major airports worldwide
- All airport dropdowns (departure, arrival, transit) will still function

## How It Works

1. **CSV Loading**: On first use, airports are loaded from `airports.dat`
2. **Caching**: Loaded airports are cached in SharedPreferences for faster subsequent loads
3. **Search**: Users can search by airport code, name, city, or country
4. **Comprehensive List**: All dropdowns use the same comprehensive CSV-loaded airport list

## Current Status

- ✅ Departure airport dropdown - Uses CSV-loaded airports
- ✅ Arrival airport dropdown - Uses CSV-loaded airports  
- ✅ Transit airport dropdown - Uses CSV-loaded airports
- ✅ Search functionality - Searches through all CSV-loaded airports

