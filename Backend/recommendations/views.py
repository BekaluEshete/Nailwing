from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from .models import AirportPlace, UserRecommendation
from flights.models import Flight
from django.utils import timezone


class AirportPlaceViewSet(viewsets.ReadOnlyModelViewSet):
    """View airport places/amenities"""
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        airport_code = self.request.query_params.get('airport')
        place_type = self.request.query_params.get('type')
        
        queryset = AirportPlace.objects.all()
        
        if airport_code:
            queryset = queryset.filter(airport_code=airport_code.upper())
        
        if place_type:
            queryset = queryset.filter(place_type=place_type)
        
        return queryset.order_by('-rating', 'name')
    
    def list(self, request):
        """List places with optional filters"""
        queryset = self.get_queryset()
        
        # Serialize manually for now
        places = []
        for place in queryset:
            places.append({
                'id': place.id,
                'name': place.name,
                'type': place.place_type,
                'airport_code': place.airport_code,
                'terminal': place.terminal,
                'description': place.description,
                'rating': place.rating,
                'price_range': place.price_range,
                'opening_hours': place.opening_hours,
                'is_24_hours': place.is_24_hours,
                'latitude': place.latitude,
                'longitude': place.longitude,
            })
        
        return Response(places)


class RecommendationViewSet(viewsets.ModelViewSet):
    """User recommendations"""
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return UserRecommendation.objects.filter(user=self.request.user).order_by('-created_at')
    
    @action(detail=False, methods=['get'])
    def get_recommendations(self, request):
        """Get recommendations for user's current location/flight"""
        user = request.user
        
        # Get user's current or upcoming flight
        flight = Flight.objects.filter(
            user=user,
            is_visible=True,
            departure_datetime__lte=timezone.now() + timezone.timedelta(hours=4),
            arrival_datetime__gte=timezone.now() - timezone.timedelta(hours=2),
        ).order_by('-departure_datetime').first()
        
        if not flight:
            return Response({'message': 'No active flight found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Determine which airport user is at
        now = timezone.now()
        if flight.departure_datetime <= now <= flight.arrival_datetime:
            if flight.has_layover and flight.layover_start <= now <= flight.layover_end:
                airport_code = flight.layover_airport
            elif now < flight.departure_datetime + timezone.timedelta(hours=2):
                airport_code = flight.departure_airport
            else:
                airport_code = flight.arrival_airport
        else:
            airport_code = flight.departure_airport
        
        # Get recommendations for this airport
        places = AirportPlace.objects.filter(airport_code=airport_code).order_by('-rating')[:10]
        
        recommendations = []
        for place in places:
            rec, created = UserRecommendation.objects.get_or_create(
                user=user,
                place=place,
                defaults={
                    'airport_code': airport_code,
                    'reason': f'Popular {place.get_place_type_display()} at {airport_code}',
                }
            )
            recommendations.append({
                'id': rec.id,
                'place': {
                    'id': place.id,
                    'name': place.name,
                    'type': place.place_type,
                    'terminal': place.terminal,
                    'description': place.description,
                    'rating': place.rating,
                    'price_range': place.price_range,
                    'opening_hours': place.opening_hours,
                    'is_24_hours': place.is_24_hours,
                    'latitude': place.latitude,
                    'longitude': place.longitude,
                },
                'reason': rec.reason,
                'distance_meters': rec.distance_meters,
                'is_viewed': rec.is_viewed,
            })
        
        return Response(recommendations)

