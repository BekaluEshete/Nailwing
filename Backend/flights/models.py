from django.db import models
from django.utils import timezone
from authentication.models import CustomUser


class Flight(models.Model):
    """User's flight information"""
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='flights')
    
    # Flight Details
    flight_number = models.CharField(max_length=20)
    airline = models.CharField(max_length=100)
    aircraft = models.CharField(max_length=50, blank=True, null=True)
    
    # Departure
    departure_airport = models.CharField(max_length=10)  # IATA code
    departure_city = models.CharField(max_length=100)
    departure_country = models.CharField(max_length=100, blank=True)
    departure_terminal = models.CharField(max_length=20, blank=True)
    departure_gate = models.CharField(max_length=20, blank=True)
    departure_datetime = models.DateTimeField()
    
    # Arrival
    arrival_airport = models.CharField(max_length=10)  # IATA code
    arrival_city = models.CharField(max_length=100)
    arrival_country = models.CharField(max_length=100, blank=True)
    arrival_terminal = models.CharField(max_length=20, blank=True)
    arrival_gate = models.CharField(max_length=20, blank=True)
    arrival_datetime = models.DateTimeField()
    
    # Layover Information (if applicable)
    has_layover = models.BooleanField(default=False)
    layover_airport = models.CharField(max_length=10, blank=True, null=True)
    layover_city = models.CharField(max_length=100, blank=True, null=True)
    layover_terminal = models.CharField(max_length=20, blank=True, null=True)
    layover_start = models.DateTimeField(blank=True, null=True)
    layover_end = models.DateTimeField(blank=True, null=True)
    layover_duration_hours = models.FloatField(blank=True, null=True)
    
    # Flight Status
    STATUS_CHOICES = [
        ('scheduled', 'Scheduled'),
        ('boarding', 'Boarding'),
        ('delayed', 'Delayed'),
        ('in_flight', 'In Flight'),
        ('landed', 'Landed'),
        ('cancelled', 'Cancelled'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='scheduled')
    delay_minutes = models.IntegerField(default=0)
    
    # Additional Info
    seat = models.CharField(max_length=10, blank=True)
    booking_reference = models.CharField(max_length=50, blank=True)
    travel_class = models.CharField(max_length=20, default='economy')
    
    # Visibility for Matching
    is_visible = models.BooleanField(default=True)
    looking_for_company = models.BooleanField(default=False)
    open_to_meeting = models.BooleanField(default=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['departure_datetime']
        indexes = [
            models.Index(fields=['departure_airport', 'departure_datetime']),
            models.Index(fields=['arrival_airport', 'arrival_datetime']),
            models.Index(fields=['layover_airport', 'layover_start', 'layover_end']),
            models.Index(fields=['user', 'is_visible']),
        ]
    
    def __str__(self):
        return f"{self.flight_number} - {self.user.email}"
    
    @property
    def route(self):
        if self.has_layover:
            return f"{self.departure_airport} → {self.layover_airport} → {self.arrival_airport}"
        return f"{self.departure_airport} → {self.arrival_airport}"
    
    @property
    def duration_hours(self):
        if self.arrival_datetime and self.departure_datetime:
            delta = self.arrival_datetime - self.departure_datetime
            return delta.total_seconds() / 3600
        return None


class UserInterest(models.Model):
    """User interests for matching"""
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='interests')
    interest = models.CharField(max_length=100)
    
    class Meta:
        unique_together = ['user', 'interest']
    
    def __str__(self):
        return f"{self.user.email} - {self.interest}"


class TravelPreference(models.Model):
    """User travel preferences"""
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='travel_preference')
    
    # Travel Experience
    TRAVEL_EXPERIENCE_CHOICES = [
        ('first_time', 'First Time Traveler'),
        ('occasional', 'Occasional Traveler'),
        ('frequent', 'Frequent Traveler'),
        ('business', 'Business Traveler'),
    ]
    travel_experience = models.CharField(max_length=20, choices=TRAVEL_EXPERIENCE_CHOICES, blank=True)
    is_first_international = models.BooleanField(default=False)
    
    # Meeting Preferences
    looking_for_guide = models.BooleanField(default=False)
    offering_guidance = models.BooleanField(default=False)
    preferred_gender = models.CharField(max_length=20, blank=True, null=True)
    
    # Business Networking
    open_to_business = models.BooleanField(default=False)
    business_interests = models.TextField(blank=True)
    
    # Social Preferences
    open_to_socializing = models.BooleanField(default=True)
    preferred_activities = models.JSONField(default=list, blank=True)  # e.g., ["coffee", "networking", "exploring"]
    
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Preferences for {self.user.email}"

