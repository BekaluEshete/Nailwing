from rest_framework import serializers
import logging
from .models import Match, MatchFilter
from authentication.serializers import UserProfileSerializer
from flights.serializers import FlightSerializer
from .matching_service import MatchingService

logger = logging.getLogger("matching")


class MatchSerializer(serializers.ModelSerializer):
    user1_data = UserProfileSerializer(source='user1', read_only=True)
    user2_data = UserProfileSerializer(source='user2', read_only=True)
    flight1_data = FlightSerializer(source='flight1', read_only=True)
    flight2_data = FlightSerializer(source='flight2', read_only=True)
    common_interests = serializers.SerializerMethodField()
    
    class Meta:
        model = Match
        fields = [
            'id', 'user1', 'user2', 'user1_data', 'user2_data',
            'flight1', 'flight2', 'flight1_data', 'flight2_data',
            'match_type', 'matching_airport', 'matching_city',
            'overlap_start', 'overlap_end', 'overlap_duration_hours',
            'match_score', 'common_interests', 'status',
            'user1_liked', 'user2_liked', 'user1_viewed', 'user2_viewed',
            'created_at', 'updated_at', 'matched_at',
        ]
        read_only_fields = [
            'id', 'user1', 'user2', 'created_at', 'updated_at',
            'matched_at', 'match_score',
        ]
    
    def get_common_interests(self, obj):
        """Recalculate common interests dynamically"""
        try:
            common = MatchingService.calculate_common_interests(obj.user1, obj.user2)
            logger.debug("Common interests for match %s: %s", obj.id, common)
            return common if common else []
        except Exception as exc:
            logger.warning("Error calculating common interests for match %s: %s", obj.id, exc)
            return obj.common_interests or []


class MatchFilterSerializer(serializers.ModelSerializer):
    class Meta:
        model = MatchFilter
        fields = [
            'preferred_gender', 'prefer_first_time_travelers',
            'prefer_experienced_travelers', 'require_common_interests',
            'min_common_interests', 'prefer_business_travelers',
            'min_age', 'max_age', 'updated_at',
        ]
        read_only_fields = ['updated_at']

