from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from django.utils import timezone
from datetime import timedelta
from .models import Match, MatchFilter
from .serializers import MatchSerializer, MatchFilterSerializer
from .matching_service import MatchingService
from flights.models import Flight


class MatchViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = MatchSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """Get matches for current user"""
        user = self.request.user
        return (
            Match.objects.filter(Q(user1=user) | Q(user2=user))
            .exclude(status="rejected")
            .order_by("-match_score", "-created_at")
        )

    @action(detail=False, methods=["get"])
    def find_matches(self, request):
        """Find new matches for the current user"""
        user = request.user
        flight_id = request.query_params.get("flight_id")

        flight = None
        if flight_id:
            try:
                flight = Flight.objects.get(id=flight_id, user=user)
                print(
                    f"🔍 [MatchViewSet] Using specified flight: {flight.flight_number} ({flight.departure_airport} → {flight.arrival_airport})"
                )
            except Flight.DoesNotExist:
                return Response(
                    {"error": "Flight not found"}, status=status.HTTP_404_NOT_FOUND
                )
        else:
            # Check if user has any flights
            all_flights = Flight.objects.filter(user=user)
            visible_flights = Flight.objects.filter(user=user, is_visible=True)
            upcoming_flights = Flight.objects.filter(
                user=user,
                is_visible=True,
                departure_datetime__gte=timezone.now() - timedelta(hours=2),
            )

            print(f"🔍 [MatchViewSet] User {user.email} has:")
            print(f"   - Total flights: {all_flights.count()}")
            print(f"   - Visible flights: {visible_flights.count()}")
            print(f"   - Upcoming flights (for matching): {upcoming_flights.count()}")

            if all_flights.count() == 0:
                return Response(
                    {
                        "matches": [],
                        "message": "No flights found. Please add a flight to find matches.",
                        "debug": {
                            "has_flights": False,
                            "has_visible_flights": False,
                            "has_upcoming_flights": False,
                        },
                    }
                )

            if visible_flights.count() == 0:
                return Response(
                    {
                        "matches": [],
                        "message": "No visible flights found. Make sure your flights are set to visible for matching.",
                        "debug": {
                            "has_flights": True,
                            "has_visible_flights": False,
                            "has_upcoming_flights": False,
                        },
                    }
                )

        # Find matches using matching service
        match_data_list = MatchingService.find_matches_for_user(user, flight)

        print(f"🔍 [MatchViewSet] Found {len(match_data_list)} potential matches")

        if not flight:
            # Get the flight that was used for matching
            flight = (
                Flight.objects.filter(
                    user=user,
                    is_visible=True,
                    departure_datetime__gte=timezone.now() - timedelta(hours=2),
                )
                .order_by("departure_datetime")
                .first()
            )

        if not flight:
            return Response(
                {
                    "matches": [],
                    "message": "No suitable flight found for matching. Flights must be visible and within 2 hours of departure.",
                    "debug": {
                        "has_flights": Flight.objects.filter(user=user).exists(),
                        "has_visible_flights": Flight.objects.filter(
                            user=user, is_visible=True
                        ).exists(),
                        "has_upcoming_flights": False,
                    },
                }
            )

        # Create or update match records
        matches = []
        for match_data in match_data_list:
            other_user = match_data["user"]
            other_flight = match_data["flight"]

            # Determine user1 and user2 (smaller ID first for consistency)
            if user.id < other_user.id:
                user1, user2 = user, other_user
                flight1, flight2 = flight, other_flight
            else:
                user1, user2 = other_user, user
                flight1, flight2 = other_flight, flight

            match = MatchingService.create_or_update_match(
                user1, user2, flight1, flight2, match_data
            )
            matches.append(match)

        serializer = self.get_serializer(matches, many=True)

        # Add debug info if no matches found
        response_data = serializer.data
        if len(response_data) == 0:
            # Count other users with visible flights
            other_users_count = (
                Flight.objects.filter(is_visible=True, user__isnull=False)
                .exclude(user=user)
                .values("user")
                .distinct()
                .count()
            )

            response_data = {
                "matches": [],
                "message": "No matches found. This could be because:",
                "reasons": [
                    "No other users with compatible flights",
                    "Flight times don't overlap",
                    "No matching airports or routes",
                ],
                "debug": {
                    "user_flight": {
                        "id": str(flight.id),
                        "flight_number": flight.flight_number,
                        "departure": flight.departure_airport,
                        "arrival": flight.arrival_airport,
                        "departure_time": flight.departure_datetime.isoformat(),
                        "is_visible": flight.is_visible,
                        "has_layover": flight.has_layover,
                    },
                    "other_users_with_flights": other_users_count,
                    "total_visible_flights": Flight.objects.filter(is_visible=True)
                    .exclude(user=user)
                    .count(),
                },
            }

        return Response(response_data)

    @action(detail=True, methods=["post"])
    def like(self, request, pk=None):
        """Like a match"""
        match = self.get_object()
        user = request.user

        if match.user1 == user:
            match.user1_liked = True
            match.user1_viewed = True
        elif match.user2 == user:
            match.user2_liked = True
            match.user2_viewed = True
        else:
            return Response(
                {"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN
            )

        match.mark_matched()
        match.save()

        serializer = self.get_serializer(match)
        return Response(serializer.data)

    @action(detail=True, methods=["post"])
    def reject(self, request, pk=None):
        """Reject a match"""
        match = self.get_object()
        user = request.user

        if match.user1 == user or match.user2 == user:
            match.status = "rejected"
            match.save()
            return Response({"message": "Match rejected"})

        return Response({"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN)

    @action(detail=True, methods=["post"])
    def view(self, request, pk=None):
        """Mark match as viewed"""
        match = self.get_object()
        user = request.user

        if match.user1 == user:
            match.user1_viewed = True
        elif match.user2 == user:
            match.user2_viewed = True
        else:
            return Response(
                {"error": "Not authorized"}, status=status.HTTP_403_FORBIDDEN
            )

        match.save()
        return Response({"message": "Match viewed"})


class MatchFilterViewSet(viewsets.ModelViewSet):
    serializer_class = MatchFilterSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return MatchFilter.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=False, methods=["get", "put"])
    def my_filters(self, request):
        """Get or update current user's match filters"""
        filter_obj, created = MatchFilter.objects.get_or_create(user=request.user)

        if request.method == "PUT":
            serializer = self.get_serializer(
                filter_obj, data=request.data, partial=True
            )
            serializer.is_valid(raise_exception=True)
            serializer.save()
            return Response(serializer.data)

        serializer = self.get_serializer(filter_obj)
        return Response(serializer.data)
