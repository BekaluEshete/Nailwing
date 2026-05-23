"""
Service for fetching places (hotels, cafes, restaurants) from third-party APIs
"""
import requests
import os
import time
from typing import List, Dict, Optional

# In-memory cache for places results — keyed by airport+categories
_places_cache: Dict[str, Dict] = {}
_CACHE_TTL_SECONDS = 3600  # 1 hour

# In-memory cache for airport coordinates
_coords_cache: Dict[str, Optional[Dict[str, float]]] = {}


class PlacesAPIService:
    """Service to fetch places from third-party APIs."""

    # Read keys at call time so .env is already loaded by Django
    @classmethod
    def _google_key(cls) -> str:
        return os.environ.get('GOOGLE_PLACES_API_KEY', '')

    @classmethod
    def _foursquare_key(cls) -> str:
        return os.environ.get('FOURSQUARE_API_KEY', '')

    # ─── Airport Coordinates ──────────────────────────────────────────────────

    @staticmethod
    def get_airport_coordinates(airport_code: str) -> Optional[Dict[str, float]]:
        """
        Get lat/lng for an airport IATA code.
        Tries OpenFlights CSV first, falls back to hardcoded list.
        Results are cached in memory for the process lifetime.
        """
        airport_code = airport_code.upper()

        if airport_code in _coords_cache:
            return _coords_cache[airport_code]

        # Try OpenFlights public dataset
        try:
            url = "https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat"
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                for line in response.text.split('\n'):
                    if not line.strip():
                        continue
                    parts = []
                    current = ""
                    in_quotes = False
                    for char in line:
                        if char == '"':
                            in_quotes = not in_quotes
                        elif char == ',' and not in_quotes:
                            parts.append(current.strip().strip('"'))
                            current = ""
                            continue
                        current += char
                    if current:
                        parts.append(current.strip().strip('"'))

                    # Format: ID, Name, City, Country, IATA, ICAO, Lat, Lon, ...
                    if len(parts) >= 8 and parts[4].strip().strip('"') == airport_code:
                        try:
                            lat = float(parts[6])
                            lng = float(parts[7])
                            if lat != 0.0 or lng != 0.0:
                                result = {'lat': lat, 'lng': lng}
                                _coords_cache[airport_code] = result
                                print(f"✅ [PlacesAPI] Coords for {airport_code}: {lat}, {lng}")
                                return result
                        except (ValueError, IndexError):
                            continue
        except Exception as e:
            print(f"⚠️ [PlacesAPI] OpenFlights fetch failed: {e}")

        # Hardcoded fallback for major airports
        hardcoded = {
            'JFK': {'lat': 40.6413, 'lng': -73.7781},
            'LGA': {'lat': 40.7769, 'lng': -73.8740},
            'LAX': {'lat': 33.9425, 'lng': -118.4081},
            'SFO': {'lat': 37.6213, 'lng': -122.3790},
            'LHR': {'lat': 51.4700, 'lng': -0.4543},
            'LGW': {'lat': 51.1481, 'lng': -0.1903},
            'DXB': {'lat': 25.2532, 'lng': 55.3657},
            'AUH': {'lat': 24.4330, 'lng': 54.6511},
            'CDG': {'lat': 49.0097, 'lng': 2.5479},
            'ORY': {'lat': 48.7233, 'lng': 2.3794},
            'AMS': {'lat': 52.3105, 'lng': 4.7683},
            'FRA': {'lat': 50.0379, 'lng': 8.5622},
            'MUC': {'lat': 48.3538, 'lng': 11.7861},
            'IST': {'lat': 41.2753, 'lng': 28.7519},
            'ADD': {'lat': 8.9806, 'lng': 38.7994},
            'CAI': {'lat': 30.1219, 'lng': 31.4056},
            'NBO': {'lat': -1.3192, 'lng': 36.9278},
            'JNB': {'lat': -26.1367, 'lng': 28.2411},
            'ATL': {'lat': 33.6367, 'lng': -84.4281},
            'ORD': {'lat': 41.9742, 'lng': -87.9073},
            'DFW': {'lat': 32.8998, 'lng': -97.0403},
            'DEN': {'lat': 39.8561, 'lng': -104.6737},
            'SIN': {'lat': 1.3644, 'lng': 103.9915},
            'HKG': {'lat': 22.3080, 'lng': 113.9185},
            'PEK': {'lat': 40.0799, 'lng': 116.6031},
            'PVG': {'lat': 31.1434, 'lng': 121.8052},
            'NRT': {'lat': 35.7647, 'lng': 140.3863},
            'HND': {'lat': 35.5494, 'lng': 139.7798},
            'ICN': {'lat': 37.4602, 'lng': 126.4407},
            'BKK': {'lat': 13.6811, 'lng': 100.7473},
            'MEL': {'lat': -37.6733, 'lng': 144.8433},
            'SYD': {'lat': -33.9399, 'lng': 151.1753},
            'SSH': {'lat': 27.9773, 'lng': 34.3947},
            'BJM': {'lat': -3.3240, 'lng': 29.3185},
            'RTM': {'lat': 51.9569, 'lng': 4.4372},
            'SAW': {'lat': 40.8986, 'lng': 29.3092},
        }

        if airport_code in hardcoded:
            _coords_cache[airport_code] = hardcoded[airport_code]
            return hardcoded[airport_code]

        print(f"⚠️ [PlacesAPI] No coordinates found for {airport_code}")
        _coords_cache[airport_code] = None
        return None

    # ─── Google Places ────────────────────────────────────────────────────────

    @staticmethod
    def fetch_places_from_google(
        lat: float,
        lng: float,
        category: str,
        limit: int = 10,
    ) -> List[Dict]:
        """Fetch places using Google Places Nearby Search API."""
        if not PlacesAPIService._google_key():
            return []

        type_map = {
            'hotel': 'lodging',
            'restaurant': 'restaurant',
            'cafe': 'cafe',
        }

        try:
            params = {
                'location': f'{lat},{lng}',
                'radius': 10000,
                'type': type_map.get(category, 'restaurant'),
                'key': PlacesAPIService._google_key(),
            }
            response = requests.get(
                'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
                params=params,
                timeout=10,
            )

            if response.status_code != 200:
                print(f"⚠️ [Google] HTTP {response.status_code}")
                return []

            data = response.json()
            api_status = data.get('status', '')

            if api_status == 'REQUEST_DENIED':
                print(f"❌ [Google] REQUEST_DENIED — {data.get('error_message', 'check API key and enabled APIs')}")
                return []
            if api_status not in ('OK', 'ZERO_RESULTS'):
                print(f"⚠️ [Google] status={api_status} — {data.get('error_message', '')}")
                return []
            if api_status == 'ZERO_RESULTS':
                return []

            places = []
            for result in data.get('results', [])[:limit]:
                loc = result.get('geometry', {}).get('location', {})
                price_level = result.get('price_level') or 0
                oh = result.get('opening_hours') or {}
                types = result.get('types') or []
                description = types[0].replace('_', ' ').title() if types else ''

                places.append({
                    'name': result.get('name', ''),
                    'type': category,
                    'rating': result.get('rating', 0.0),
                    'latitude': loc.get('lat', lat),
                    'longitude': loc.get('lng', lng),
                    'address': result.get('vicinity', ''),
                    'distance': 0,
                    'price_range': '$' * price_level,
                    'opening_hours': '',
                    'is_24_hours': False,
                    'open_now': oh.get('open_now'),
                    'description': description,
                    'photos': [],
                })
            return places

        except Exception as e:
            print(f"❌ [Google] fetch error: {e}")
            return []

    # ─── Foursquare ───────────────────────────────────────────────────────────

    @staticmethod
    def fetch_places_from_foursquare(
        lat: float,
        lng: float,
        category: str,
        limit: int = 10,
    ) -> List[Dict]:
        """Fetch places using Foursquare Places API v3."""
        if not PlacesAPIService._foursquare_key():
            return []

        category_map = {
            'hotel': '4bf58dd8d48988d1fa931735',
            'restaurant': '4d4b7105d754a06374d81259',
            'cafe': '4bf58dd8d48988d16d941735',
        }

        try:
            response = requests.get(
                'https://api.foursquare.com/v3/places/search',
                headers={
                    'Accept': 'application/json',
                    'Authorization': PlacesAPIService._foursquare_key(),
                },
                params={
                    'll': f'{lat},{lng}',
                    'categories': category_map.get(category, category_map['restaurant']),
                    'radius': 10000,
                    'limit': limit,
                },
                timeout=10,
            )

            if response.status_code == 200:
                places = []
                for result in response.json().get('results', [])[:limit]:
                    loc = result.get('location', {})
                    places.append({
                        'name': result.get('name', ''),
                        'type': category,
                        'rating': result.get('rating', 0.0),
                        'latitude': loc.get('lat', lat),
                        'longitude': loc.get('lng', lng),
                        'address': loc.get('formatted_address', ''),
                        'distance': loc.get('distance', 0),
                        'price_range': '',
                        'opening_hours': '',
                        'is_24_hours': False,
                        'description': '',
                        'photos': [],
                    })
                return places

        except Exception as e:
            print(f"❌ [Foursquare] fetch error: {e}")

        return []

    # ─── Overpass (OpenStreetMap) ─────────────────────────────────────────────

    @staticmethod
    def fetch_places_from_overpass(
        lat: float,
        lng: float,
        category: str,
        limit: int = 10,
    ) -> List[Dict]:
        """Fetch places from Overpass API (OpenStreetMap) — always free."""
        tag_map = {
            'hotel': 'tourism=hotel',
            'restaurant': 'amenity=restaurant',
            'cafe': 'amenity=cafe',
        }
        tag = tag_map.get(category, 'amenity=restaurant')

        query = f"""
[out:json][timeout:25];
(
  node[{tag}](around:10000,{lat},{lng});
  way[{tag}](around:10000,{lat},{lng});
  relation[{tag}](around:10000,{lat},{lng});
);
out center;
"""
        try:
            response = requests.post(
                'https://overpass-api.de/api/interpreter',
                data=query,
                timeout=20,
            )
            if response.status_code == 200:
                places = []
                for element in response.json().get('elements', [])[:limit]:
                    tags = element.get('tags', {})
                    center = element.get('center', {})
                    lat_e = element.get('lat') or center.get('lat', lat)
                    lng_e = element.get('lon') or center.get('lon', lng)
                    street = tags.get('addr:street', '')
                    city = tags.get('addr:city', '')
                    address = f"{street} {city}".strip()
                    places.append({
                        'name': tags.get('name', 'Unnamed'),
                        'type': category,
                        'rating': 0.0,
                        'latitude': lat_e,
                        'longitude': lng_e,
                        'address': address,
                        'distance': 0,
                        'price_range': '',
                        'opening_hours': tags.get('opening_hours', ''),
                        'is_24_hours': tags.get('opening_hours', '') == '24/7',
                        'description': tags.get('description', ''),
                        'photos': [],
                    })
                return places

        except Exception as e:
            print(f"❌ [Overpass] fetch error: {e}")

        return []

    # ─── Main entry point ─────────────────────────────────────────────────────

    @staticmethod
    def get_places_near_airport(
        airport_code: str,
        categories: List[str] = None,
        limit_per_category: int = 10,
    ) -> Dict[str, List[Dict]]:
        """
        Get places near an airport by IATA code.
        Priority: Google Places → Foursquare → Overpass.
        Results are cached for 1 hour.
        """
        if categories is None:
            categories = ['hotel', 'restaurant', 'cafe']

        airport_code = airport_code.upper()
        cache_key = f"{airport_code}|{'|'.join(sorted(categories))}|{limit_per_category}"

        cached = _places_cache.get(cache_key)
        if cached and (time.time() - cached['timestamp']) < _CACHE_TTL_SECONDS:
            print(f"✅ [PlacesAPI] Cache hit for {airport_code}")
            return cached['data']

        coords = PlacesAPIService.get_airport_coordinates(airport_code)
        if not coords:
            print(f"⚠️ [PlacesAPI] No coords for {airport_code} — returning empty")
            return {cat: [] for cat in categories}

        lat, lng = coords['lat'], coords['lng']
        results: Dict[str, List[Dict]] = {}

        for category in categories:
            places: List[Dict] = []

            if PlacesAPIService._google_key():
                places = PlacesAPIService.fetch_places_from_google(lat, lng, category, limit_per_category)
                if places:
                    print(f"✅ [Google] {len(places)} {category}s for {airport_code}")

            if not places and PlacesAPIService._foursquare_key():
                places = PlacesAPIService.fetch_places_from_foursquare(lat, lng, category, limit_per_category)
                if places:
                    print(f"✅ [Foursquare] {len(places)} {category}s for {airport_code}")

            if not places:
                print(f"⚠️ [PlacesAPI] Falling back to Overpass for {category}s at {airport_code}")
                places = PlacesAPIService.fetch_places_from_overpass(lat, lng, category, limit_per_category)

            results[category] = places

        _places_cache[cache_key] = {'data': results, 'timestamp': time.time()}
        print(f"✅ [PlacesAPI] Cached {airport_code} results")
        return results
