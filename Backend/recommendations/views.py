from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from .models import AirportPlace, UserRecommendation
from .places_api_service import PlacesAPIService
from flights.models import Flight
from matching.models import Match
from authentication.models import CustomUser
from django.utils import timezone
from datetime import timedelta


class AirportPlaceViewSet(viewsets.ReadOnlyModelViewSet):
    """View airport places/amenities"""

    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        airport_code = self.request.query_params.get("airport")
        place_type = self.request.query_params.get("type")

        queryset = AirportPlace.objects.all()

        if airport_code:
            queryset = queryset.filter(airport_code=airport_code.upper())

        if place_type:
            queryset = queryset.filter(place_type=place_type)

        return queryset.order_by("-rating", "name")

    def list(self, request):
        """List places with optional filters"""
        queryset = self.get_queryset()

        # Serialize manually for now
        places = []
        for place in queryset:
            places.append(
                {
                    "id": place.id,
                    "name": place.name,
                    "type": place.place_type,
                    "airport_code": place.airport_code,
                    "terminal": place.terminal,
                    "description": place.description,
                    "rating": place.rating,
                    "price_range": place.price_range,
                    "opening_hours": place.opening_hours,
                    "is_24_hours": place.is_24_hours,
                    "latitude": place.latitude,
                    "longitude": place.longitude,
                }
            )

        return Response(places)


class RecommendationViewSet(viewsets.ModelViewSet):
    """User recommendations"""

    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UserRecommendation.objects.filter(user=self.request.user).order_by(
            "-created_at"
        )

    @action(detail=False, methods=["get"])
    def get_recommendations(self, request):
        """Get comprehensive recommendations based on arrival airport"""
        user = request.user

        # Get user's upcoming flight (focus on arrival airport)
        flight = (
            Flight.objects.filter(
                user=user,
                is_visible=True,
                departure_datetime__gte=timezone.now() - timedelta(hours=2),
                departure_datetime__lte=timezone.now() + timedelta(days=30),
            )
            .order_by("departure_datetime")
            .first()
        )

        if not flight:
            return Response(
                {
                    "message": "No upcoming flight found",
                    "hotels": [],
                    "cafes": [],
                    "restaurants": [],
                    "people": [],
                },
                status=status.HTTP_404_NOT_FOUND,
            )

        # Use arrival airport for recommendations
        arrival_airport = flight.arrival_airport
        arrival_city = flight.arrival_city

        # Fetch places from third-party APIs
        places_api = PlacesAPIService()
        places_data = places_api.get_places_near_airport(
            airport_code=arrival_airport,
            categories=["hotel", "cafe", "restaurant"],
            limit_per_category=15,
        )

        # Format hotels
        hotels = []
        for idx, place in enumerate(places_data.get("hotel", [])[:10]):
            hotels.append(
                {
                    "id": f"api_hotel_{arrival_airport}_{idx}_{place.get('name', '').replace(' ', '_')}",
                    "name": place.get("name", ""),
                    "type": "hotel",
                    "rating": place.get("rating", 0.0),
                    "latitude": place.get("latitude", 0.0),
                    "longitude": place.get("longitude", 0.0),
                    "address": place.get("address", ""),
                    "distance": place.get("distance", 0),
                    "distance_text": (
                        f"{(place.get('distance', 0) / 1000):.1f} km"
                        if place.get("distance")
                        else "Nearby"
                    ),
                    "price_range": place.get("price_range", ""),
                    "opening_hours": place.get("opening_hours", ""),
                    "is_24_hours": place.get("is_24_hours", False),
                    "description": place.get(
                        "description", f"Hotel near {arrival_airport} Airport"
                    ),
                    "photos": place.get("photos", []),
                }
            )

        # Format cafes
        cafes = []
        for idx, place in enumerate(places_data.get("cafe", [])[:10]):
            cafes.append(
                {
                    "id": f"api_cafe_{arrival_airport}_{idx}_{place.get('name', '').replace(' ', '_')}",
                    "name": place.get("name", ""),
                    "type": "cafe",
                    "rating": place.get("rating", 0.0),
                    "latitude": place.get("latitude", 0.0),
                    "longitude": place.get("longitude", 0.0),
                    "address": place.get("address", ""),
                    "distance": place.get("distance", 0),
                    "distance_text": (
                        f"{(place.get('distance', 0) / 1000):.1f} km"
                        if place.get("distance")
                        else "Nearby"
                    ),
                    "price_range": place.get("price_range", ""),
                    "opening_hours": place.get("opening_hours", ""),
                    "is_24_hours": place.get("is_24_hours", False),
                    "description": place.get(
                        "description", f"Cafe near {arrival_airport} Airport"
                    ),
                    "photos": place.get("photos", []),
                }
            )

        # Format restaurants/dining
        restaurants = []
        for idx, place in enumerate(places_data.get("restaurant", [])[:10]):
            restaurants.append(
                {
                    "id": f"api_restaurant_{arrival_airport}_{idx}_{place.get('name', '').replace(' ', '_')}",
                    "name": place.get("name", ""),
                    "type": "restaurant",
                    "rating": place.get("rating", 0.0),
                    "latitude": place.get("latitude", 0.0),
                    "longitude": place.get("longitude", 0.0),
                    "address": place.get("address", ""),
                    "distance": place.get("distance", 0),
                    "distance_text": (
                        f"{(place.get('distance', 0) / 1000):.1f} km"
                        if place.get("distance")
                        else "Nearby"
                    ),
                    "price_range": place.get("price_range", ""),
                    "opening_hours": place.get("opening_hours", ""),
                    "is_24_hours": place.get("is_24_hours", False),
                    "description": place.get(
                        "description", f"Restaurant near {arrival_airport} Airport"
                    ),
                    "photos": place.get("photos", []),
                }
            )

        # Get matched people going to the same destination airport
        people_matches = []
        try:
            # Find matches where both users are going to the same destination
            matches = Match.objects.filter(
                (Q(user1=user) | Q(user2=user)),
                Q(status__in=["pending", "matched", "connection_requested"]),
                matching_airport=arrival_airport,
            ).select_related("user1", "user2", "flight1", "flight2")[:10]

            for match in matches:
                # Determine which user is the other person
                other_user = match.user2 if match.user1 == user else match.user1
                
                # Safely determine other flight (flight1/flight2 can be null)
                try:
                    if match.flight1 and match.flight1.user == user:
                        other_flight = match.flight2
                    else:
                        other_flight = match.flight1
                except Exception:
                    other_flight = None

                # Get user profile information
                people_matches.append(
                    {
                        "id": f"match_{match.id}",
                        "user_id": other_user.id,
                        "name": other_user.full_name or other_user.username,
                        "avatar": other_user.profile_image_url,
                        "age": other_user.age,
                        "nationality": other_user.nationality or "",
                        "match_type": match.match_type,
                        "matching_airport": match.matching_airport,
                        "arrival_airport": arrival_airport,
                        "arrival_time": (
                            other_flight.arrival_datetime.isoformat()
                            if other_flight
                            else None
                        ),
                        "common_interests": match.common_interests or [],
                        "match_score": match.match_score,
                        "description": f"Traveling to {arrival_city} - {arrival_airport}",
                    }
                )

        except Exception as e:
            print(f"Error fetching people matches: {e}")

        return Response(
            {
                "airport_code": arrival_airport,
                "airport_city": arrival_city,
                "hotels": hotels,
                "cafes": cafes,
                "restaurants": restaurants,
                "people": people_matches,
                "flight_info": {
                    "flight_number": flight.flight_number,
                    "arrival_airport": flight.arrival_airport,
                    "arrival_city": flight.arrival_city,
                    "arrival_datetime": flight.arrival_datetime.isoformat(),
                },
            }
        )
