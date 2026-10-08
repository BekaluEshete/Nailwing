import logging

from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Case, When, Value, CharField
from django.utils import timezone
from datetime import timedelta
from .models import Flight, UserInterest, TravelPreference
from .serializers import FlightSerializer, UserInterestSerializer, TravelPreferenceSerializer
from authentication.models import CustomUser

logger = logging.getLogger("flights")


class FlightViewSet(viewsets.ModelViewSet):
    serializer_class = FlightSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Return flights for the current user, auto-updating status in bulk."""
        now = timezone.now()
        user = self.request.user

        # Bulk-update statuses in a single SQL statement using Case/When.
        # Only affects non-cancelled flights whose calculated status differs
        # from what is stored. This replaces the previous per-flight UPDATE loop.
        Flight.objects.filter(user=user).exclude(status="cancelled").update(
            status=Case(
                # Landed: arrival has passed
                When(arrival_datetime__lt=now, then=Value("landed")),
                # In flight: departed but not yet arrived
                When(departure_datetime__lt=now, arrival_datetime__gt=now, then=Value("in_flight")),
                # Boarding: departure within 2 hours
                When(
                    departure_datetime__lt=now + timedelta(hours=2),
                    departure_datetime__gt=now,
                    then=Value("boarding"),
                ),
                # Otherwise keep as scheduled
                default=Value("scheduled"),
                output_field=CharField(),
            )
        )

        return Flight.objects.filter(user=user).order_by("-departure_datetime")
    
    def retrieve(self, request, *args, **kwargs):
        """Get a single flight detail and auto-update its status"""
        instance = self.get_object()
        # Auto-update status based on datetime
        calculated_status = instance.calculate_status_based_on_datetime()
        if calculated_status != instance.status and instance.status != 'cancelled':
            instance.status = calculated_status
            instance.save(update_fields=['status'])
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
    
    @action(detail=False, methods=['get'])
    def upcoming(self, request):
        """Get user's upcoming flights"""
        flights = Flight.objects.filter(
            user=request.user,
            departure_datetime__gte=timezone.now() - timedelta(hours=2),
            is_visible=True
        ).order_by('departure_datetime')
        serializer = self.get_serializer(flights, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def current(self, request):
        """Get user's current flight (in progress or at airport)"""
        now = timezone.now()
        flights = Flight.objects.filter(
            user=request.user,
            departure_datetime__lte=now + timedelta(hours=2),
            arrival_datetime__gte=now - timedelta(hours=2),
            is_visible=True
        ).order_by('-departure_datetime')
        serializer = self.get_serializer(flights, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        """Update flight status (for delays, etc.)"""
        flight = self.get_object()
        flight.status = request.data.get('status', flight.status)
        flight.delay_minutes = request.data.get('delay_minutes', flight.delay_minutes)
        flight.save()
        serializer = self.get_serializer(flight)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def community_posts(self, request):
        """Get community flight posts — select_related prevents N+1 user queries."""
        flights = Flight.objects.filter(
            is_visible=True,
            departure_datetime__gte=timezone.now()
        ).select_related("user").order_by('-created_at')[:20]

        posts = []
        for flight in flights:
            user = flight.user
            avatar = user.profile_image_url if user.profile_image_url else None
            if not avatar and user.profile_image:
                avatar = user.profile_image.url
                
            content = f"Hey everyone! I'll be flying from {flight.departure_city} to {flight.arrival_city} on {flight.departure_datetime.strftime('%b %d')}."
            full_content = content
            if flight.has_layover and flight.layover_city:
                full_content += f" Looking forward to meeting new people during my layover in {flight.layover_city}!"
            else:
                full_content += " Direct flight! Let me know if anyone is on the same route."

            posts.append({
                "id": str(flight.id),
                "user": {
                    "name": user.full_name if user.full_name else user.email.split('@')[0],
                    "avatar": avatar,
                    "nationality": user.nationality or "Global",
                },
                "flight": {
                    "number": flight.flight_number,
                    "route": flight.route,
                },
                "post": {
                    "title": f"Traveling to {flight.arrival_city}",
                    "content": content,
                    "full_content": full_content,
                    "timestamp": flight.created_at.isoformat(),
                    "likes": 0,
                    "comments": 0,
                    "isLiked": False,
                    "rating": 5
                }
            })
        return Response(posts)


class UserInterestViewSet(viewsets.ModelViewSet):
    serializer_class = UserInterestSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return UserInterest.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class TravelPreferenceViewSet(viewsets.ModelViewSet):
    serializer_class = TravelPreferenceSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return TravelPreference.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
    
    @action(detail=False, methods=['get', 'put'])
    def my_preferences(self, request):
        """Get or update current user's preferences"""
        pref, created = TravelPreference.objects.get_or_create(user=request.user)
        
        if request.method == 'PUT':
            serializer = self.get_serializer(pref, data=request.data, partial=True)
            serializer.is_valid(raise_exception=True)
            serializer.save()
            return Response(serializer.data)
        
        serializer = self.get_serializer(pref)
        return Response(serializer.data)

