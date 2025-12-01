"""
Service for fetching places (hotels, cafes, restaurants) from third-party APIs
"""
import requests
import os
from typing import List, Dict, Optional
from django.conf import settings


class PlacesAPIService:
    """Service to fetch places from third-party APIs"""
    
    # Try to get API keys from environment variables
    GOOGLE_PLACES_API_KEY = os.environ.get('GOOGLE_PLACES_API_KEY', '')
    FOURSQUARE_API_KEY = os.environ.get('FOURSQUARE_API_KEY', '')
    FOURSQUARE_API_SECRET = os.environ.get('FOURSQUARE_API_SECRET', '')
    
    @staticmethod
    def get_airport_coordinates(airport_code: str) -> Optional[Dict[str, float]]:
        """
        Get airport coordinates from airport code
        Tries to fetch from public API, falls back to hardcoded list
        """
        airport_code = airport_code.upper()
        
        # Try to fetch from public airport API first
        try:
            # Use OpenFlights airport database via public API
            url = "https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat"
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                lines = response.text.split('\n')
                for line in lines:
                    if not line.strip():
                        continue
                    # Parse CSV line (OpenFlights format)
                    parts = []
                    current_part = ""
                    in_quotes = False
                    
                    for char in line:
                        if char == '"':
                            in_quotes = not in_quotes
                        elif char == ',' and not in_quotes:
                            parts.append(current_part.strip().strip('"'))
                            current_part = ""
                            continue
                        current_part += char
                    if current_part:
                        parts.append(current_part.strip().strip('"'))
                    
                    # Check if this is the airport we're looking for
                    # Format: ID, Name, City, Country, IATA, ICAO, Lat, Lon, ...
                    if len(parts) >= 7:
                        iata_code = parts[4].strip().strip('"')
                        if iata_code == airport_code:
                            try:
                                lat = float(parts[6])
                                lng = float(parts[7])
                                if lat != 0.0 or lng != 0.0:  # Valid coordinates
                                    print(f"✅ Found coordinates for {airport_code}: {lat}, {lng}")
                                    return {'lat': lat, 'lng': lng}
                            except (ValueError, IndexError):
                                continue
        except Exception as e:
            print(f"⚠️ Error fetching airport coordinates from API: {e}")
        
        # Fallback to hardcoded list for major airports
        airport_coords = {
            'JFK': {'lat': 40.6413, 'lng': -73.7781}, 'LGA': {'lat': 40.7769, 'lng': -73.8740},
            'LAX': {'lat': 33.9425, 'lng': -118.4081}, 'SFO': {'lat': 37.6213, 'lng': -122.3790},
            'LHR': {'lat': 51.4700, 'lng': -0.4543}, 'LGW': {'lat': 51.1481, 'lng': -0.1903},
            'DXB': {'lat': 25.2532, 'lng': 55.3657}, 'AUH': {'lat': 24.4330, 'lng': 54.6511},
            'CDG': {'lat': 49.0097, 'lng': 2.5479}, 'ORY': {'lat': 48.7233, 'lng': 2.3794},
            'AMS': {'lat': 52.3105, 'lng': 4.7683}, 'RTM': {'lat': 51.9569, 'lng': 4.4372},
            'FRA': {'lat': 50.0379, 'lng': 8.5622}, 'MUC': {'lat': 48.3538, 'lng': 11.7861},
            'IST': {'lat': 41.2753, 'lng': 28.7519}, 'SAW': {'lat': 40.8986, 'lng': 29.3092},
            'ADD': {'lat': 8.9806, 'lng': 38.7994}, 'BJM': {'lat': -3.3240, 'lng': 29.3185},
            'CAI': {'lat': 30.1219, 'lng': 31.4056}, 'SSH': {'lat': 27.9773, 'lng': 34.3947},
            'NBO': {'lat': -1.3192, 'lng': 36.9278}, 'JNB': {'lat': -26.1367, 'lng': 28.2411},
            'ATL': {'lat': 33.6367, 'lng': -84.4281}, 'ORD': {'lat': 41.9742, 'lng': -87.9073},
            'DFW': {'lat': 32.8998, 'lng': -97.0403}, 'DEN': {'lat': 39.8561, 'lng': -104.6737},
            'SIN': {'lat': 1.3644, 'lng': 103.9915}, 'HKG': {'lat': 22.3080, 'lng': 113.9185},
            'PEK': {'lat': 40.0799, 'lng': 116.6031}, 'PVG': {'lat': 31.1434, 'lng': 121.8052},
            'NRT': {'lat': 35.7647, 'lng': 140.3863}, 'HND': {'lat': 35.5494, 'lng': 139.7798},
            'ICN': {'lat': 37.4602, 'lng': 126.4407}, 'BKK': {'lat': 13.6811, 'lng': 100.7473},
            'MEL': {'lat': -37.6733, 'lng': 144.8433}, 'SYD': {'lat': -33.9399, 'lng': 151.1753},
        }
        
        if airport_code in airport_coords:
            return airport_coords[airport_code]
        
        # Last resort: return None to indicate coordinates not found
        print(f"⚠️ No coordinates found for airport: {airport_code}")
        return None
    
    @staticmethod
    def fetch_places_from_foursquare(
        lat: float,
        lng: float,
        category: str,
        limit: int = 10
    ) -> List[Dict]:
        """
        Fetch places from Foursquare API
        Categories: hotel, cafe, restaurant
        """
        if not PlacesAPIService.FOURSQUARE_API_KEY:
            return []
        
        try:
            # Map our categories to Foursquare category IDs
            category_map = {
                'hotel': '4bf58dd8d48988d1fa931735',  # Hotels
                'restaurant': '4d4b7105d754a06374d81259',  # Restaurants
                'cafe': '4bf58dd8d48988d16d941735',  # Cafes
            }
            
            category_id = category_map.get(category, '4d4b7105d754a06374d81259')
            
            url = "https://api.foursquare.com/v3/places/search"
            headers = {
                "Accept": "application/json",
                "Authorization": PlacesAPIService.FOURSQUARE_API_KEY
            }
            params = {
                "ll": f"{lat},{lng}",
                "categories": category_id,
                "radius": 10000,  # 10km radius
                "limit": limit
            }
            
            response = requests.get(url, headers=headers, params=params, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                places = []
                
                for result in data.get('results', [])[:limit]:
                    location = result.get('location', {})
                    place = {
                        'name': result.get('name', ''),
                        'type': category,
                        'rating': result.get('rating', 0.0),
                        'latitude': location.get('lat', lat),
                        'longitude': location.get('lng', lng),
                        'address': location.get('formatted_address', ''),
                        'distance': location.get('distance', 0),  # in meters
                        'price_range': '',  # Foursquare doesn't always provide this
                        'opening_hours': '',
                        'is_24_hours': False,
                        'description': '',
                        'photos': [],
                    }
                    places.append(place)
                
                return places
        except Exception as e:
            print(f"Error fetching from Foursquare: {e}")
        
        return []
    
    @staticmethod
    def fetch_places_from_google(
        lat: float,
        lng: float,
        category: str,
        limit: int = 10
    ) -> List[Dict]:
        """
        Fetch places from Google Places API
        """
        if not PlacesAPIService.GOOGLE_PLACES_API_KEY:
            return []
        
        try:
            # Map categories to Google Place types
            type_map = {
                'hotel': 'lodging',
                'restaurant': 'restaurant',
                'cafe': 'cafe',
            }
            
            place_type = type_map.get(category, 'restaurant')
            
            # First, search for places
            search_url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
            params = {
                'location': f'{lat},{lng}',
                'radius': 10000,  # 10km
                'type': place_type,
                'key': PlacesAPIService.GOOGLE_PLACES_API_KEY
            }
            
            response = requests.get(search_url, params=params, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                places = []
                
                for result in data.get('results', [])[:limit]:
                    geometry = result.get('geometry', {})
                    location = geometry.get('location', {})
                    
                    place = {
                        'name': result.get('name', ''),
                        'type': category,
                        'rating': result.get('rating', 0.0),
                        'latitude': location.get('lat', lat),
                        'longitude': location.get('lng', lng),
                        'address': result.get('vicinity', ''),
                        'distance': 0,  # Google doesn't provide distance in nearby search
                        'price_range': '$' * result.get('price_level', 0) if result.get('price_level') else '',
                        'opening_hours': '',
                        'is_24_hours': False,
                        'description': '',
                        'photos': result.get('photos', [])[:3] if result.get('photos') else [],
                    }
                    places.append(place)
                
                return places
        except Exception as e:
            print(f"Error fetching from Google Places: {e}")
        
        return []
    
    @staticmethod
    def fetch_places_from_overpass(
        lat: float,
        lng: float,
        category: str,
        limit: int = 10
    ) -> List[Dict]:
        """
        Fetch places from Overpass API (OpenStreetMap) - free alternative
        """
        try:
            # Map categories to OSM tags
            tag_map = {
                'hotel': 'tourism=hotel',
                'restaurant': 'amenity=restaurant',
                'cafe': 'amenity=cafe',
            }
            
            tag = tag_map.get(category, 'amenity=restaurant')
            
            # Overpass query to find places within 10km
            overpass_url = "https://overpass-api.de/api/interpreter"
            query = f"""
            [out:json][timeout:25];
            (
              node[{tag}](around:10000,{lat},{lng});
              way[{tag}](around:10000,{lat},{lng});
              relation[{tag}](around:10000,{lat},{lng});
            );
            out center;
            """
            
            response = requests.post(overpass_url, data=query, timeout=15)
            
            if response.status_code == 200:
                data = response.json()
                places = []
                
                for element in data.get('elements', [])[:limit]:
                    tags = element.get('tags', {})
                    lat_elem = element.get('lat') or (element.get('center', {}).get('lat') if element.get('center') else lat)
                    lon_elem = element.get('lon') or (element.get('center', {}).get('lon') if element.get('center') else lng)
                    
                    place = {
                        'name': tags.get('name', 'Unnamed'),
                        'type': category,
                        'rating': 0.0,  # OSM doesn't provide ratings
                        'latitude': lat_elem,
                        'longitude': lon_elem,
                        'address': tags.get('addr:street', '') + ' ' + tags.get('addr:city', ''),
                        'distance': 0,
                        'price_range': '',
                        'opening_hours': tags.get('opening_hours', ''),
                        'is_24_hours': False,
                        'description': tags.get('description', ''),
                        'photos': [],
                    }
                    places.append(place)
                
                return places
        except Exception as e:
            print(f"Error fetching from Overpass API: {e}")
        
        return []
    
    @staticmethod
    def get_places_near_airport(
        airport_code: str,
        categories: List[str] = ['hotel', 'restaurant', 'cafe'],
        limit_per_category: int = 10
    ) -> Dict[str, List[Dict]]:
        """
        Get places near an airport by code
        Returns a dictionary with categories as keys and lists of places as values
        """
        coords = PlacesAPIService.get_airport_coordinates(airport_code)
        
        if not coords or coords.get('lat') == 0.0 or coords.get('lat') is None:
            print(f"⚠️ Could not get coordinates for airport {airport_code}, returning empty results")
            return {cat: [] for cat in categories}
        
        results = {}
        
        for category in categories:
            places = []
            
            # Try Google Places first
            if PlacesAPIService.GOOGLE_PLACES_API_KEY:
                places = PlacesAPIService.fetch_places_from_google(
                    coords['lat'], coords['lng'], category, limit_per_category
                )
            
            # Fallback to Foursquare
            if not places and PlacesAPIService.FOURSQUARE_API_KEY:
                places = PlacesAPIService.fetch_places_from_foursquare(
                    coords['lat'], coords['lng'], category, limit_per_category
                )
            
            # Final fallback to Overpass (OpenStreetMap) - always available
            if not places:
                places = PlacesAPIService.fetch_places_from_overpass(
                    coords['lat'], coords['lng'], category, limit_per_category
                )
            
            results[category] = places
        
        return results

