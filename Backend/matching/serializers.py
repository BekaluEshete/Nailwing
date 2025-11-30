from rest_framework import serializers
from .models import Match, MatchFilter
from authentication.serializers import UserProfileSerializer
from flights.serializers import FlightSerializer
from .matching_service import MatchingService


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
        """Recalculate common interests dynamically to ensure they're always current"""
        try:
            # Recalculate common interests on-the-fly (case-insensitive)
            common = MatchingService.calculate_common_interests(obj.user1, obj.user2)
            print(f"🔍 [MatchSerializer] Calculated common interests for match {obj.id}: {common}")
            
            # Return calculated interests (don't save during serialization for performance)
            return common if common else []
        except Exception as e:
            print(f"⚠️ [MatchSerializer] Error calculating common interests: {e}")
            import traceback
            traceback.print_exc()
            # Return stored value as fallback
            stored = obj.common_interests or []
            print(f"📦 [MatchSerializer] Using stored common_interests as fallback: {stored}")
            return stored


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

