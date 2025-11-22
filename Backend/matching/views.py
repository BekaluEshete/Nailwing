from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
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
        return Match.objects.filter(
            Q(user1=user) | Q(user2=user)
        ).exclude(status='rejected').order_by('-match_score', '-created_at')
    
    @action(detail=False, methods=['get'])
    def find_matches(self, request):
        """Find new matches for the current user"""
        user = request.user
        flight_id = request.query_params.get('flight_id')
        
        flight = None
        if flight_id:
            try:
                flight = Flight.objects.get(id=flight_id, user=user)
            except Flight.DoesNotExist:
                return Response(
                    {'error': 'Flight not found'},
                    status=status.HTTP_404_NOT_FOUND
                )
        
        # Find matches using matching service
        match_data_list = MatchingService.find_matches_for_user(user, flight)
        
        # Create or update match records
        matches = []
        for match_data in match_data_list:
            other_user = match_data['user']
            other_flight = match_data['flight']
            
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
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
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
                {'error': 'Not authorized'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        match.mark_matched()
        match.save()
        
        serializer = self.get_serializer(match)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        """Reject a match"""
        match = self.get_object()
        user = request.user
        
        if match.user1 == user or match.user2 == user:
            match.status = 'rejected'
            match.save()
            return Response({'message': 'Match rejected'})
        
        return Response(
            {'error': 'Not authorized'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    @action(detail=True, methods=['post'])
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
                {'error': 'Not authorized'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        match.save()
        return Response({'message': 'Match viewed'})


class MatchFilterViewSet(viewsets.ModelViewSet):
    serializer_class = MatchFilterSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return MatchFilter.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
    
    @action(detail=False, methods=['get', 'put'])
    def my_filters(self, request):
        """Get or update current user's match filters"""
        filter_obj, created = MatchFilter.objects.get_or_create(user=request.user)
        
        if request.method == 'PUT':
            serializer = self.get_serializer(filter_obj, data=request.data, partial=True)
            serializer.is_valid(raise_exception=True)
            serializer.save()
            return Response(serializer.data)
        
        serializer = self.get_serializer(filter_obj)
        return Response(serializer.data)

