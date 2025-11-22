from rest_framework import serializers
from .models import Flight, UserInterest, TravelPreference
from authentication.serializers import UserProfileSerializer


class FlightSerializer(serializers.ModelSerializer):
    route = serializers.CharField(read_only=True)
    duration_hours = serializers.FloatField(read_only=True)
    
    class Meta:
        model = Flight
        fields = [
            'id', 'flight_number', 'airline', 'aircraft',
            'departure_airport', 'departure_city', 'departure_country',
            'departure_terminal', 'departure_gate', 'departure_datetime',
            'arrival_airport', 'arrival_city', 'arrival_country',
            'arrival_terminal', 'arrival_gate', 'arrival_datetime',
            'has_layover', 'layover_airport', 'layover_city',
            'layover_terminal', 'layover_start', 'layover_end',
            'layover_duration_hours', 'status', 'delay_minutes',
            'seat', 'booking_reference', 'travel_class',
            'is_visible', 'looking_for_company', 'open_to_meeting',
            'route', 'duration_hours', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class UserInterestSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserInterest
        fields = ['id', 'interest']
        read_only_fields = ['id']


class TravelPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = TravelPreference
        fields = [
            'travel_experience', 'is_first_international',
            'looking_for_guide', 'offering_guidance',
            'preferred_gender', 'open_to_business',
            'business_interests', 'open_to_socializing',
            'preferred_activities', 'updated_at',
        ]
        read_only_fields = ['updated_at']

