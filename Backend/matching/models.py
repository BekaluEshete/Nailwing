from django.db import models
from django.utils import timezone
from authentication.models import CustomUser
from flights.models import Flight


class Match(models.Model):
    """Match between two users based on flight compatibility"""
    user1 = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='matches_as_user1')
    user2 = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='matches_as_user2')
    
    # Related Flights
    flight1 = models.ForeignKey(Flight, on_delete=models.CASCADE, related_name='matches_as_flight1', null=True)
    flight2 = models.ForeignKey(Flight, on_delete=models.CASCADE, related_name='matches_as_flight2', null=True)
    
    # Match Type
    MATCH_TYPE_CHOICES = [
        ('same_departure', 'Same Departure'),
        ('same_layover', 'Same Layover'),
        ('same_destination', 'Same Destination'),
        ('departure_layover', 'Departure is Layover'),
        ('layover_departure', 'Layover is Departure'),
        ('same_route', 'Same Route'),
    ]
    match_type = models.CharField(max_length=30, choices=MATCH_TYPE_CHOICES)
    
    # Matching Details
    matching_airport = models.CharField(max_length=10)  # Airport where they can meet
    matching_city = models.CharField(max_length=100)
    overlap_start = models.DateTimeField()
    overlap_end = models.DateTimeField()
    overlap_duration_hours = models.FloatField()
    
    # Match Score (based on interests, preferences, etc.)
    match_score = models.FloatField(default=0.0)
    common_interests = models.JSONField(default=list, blank=True)
    
    # Status
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('viewed', 'Viewed'),
        ('liked', 'Liked'),
        ('matched', 'Matched'),  # Both liked each other
        ('rejected', 'Rejected'),
        ('expired', 'Expired'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # User Actions
    user1_liked = models.BooleanField(default=False)
    user2_liked = models.BooleanField(default=False)
    user1_viewed = models.BooleanField(default=False)
    user2_viewed = models.BooleanField(default=False)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    matched_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        unique_together = ['user1', 'user2', 'flight1', 'flight2']
        ordering = ['-match_score', '-created_at']
        indexes = [
            models.Index(fields=['user1', 'status']),
            models.Index(fields=['user2', 'status']),
            models.Index(fields=['match_type', 'matching_airport']),
        ]
    
    def __str__(self):
        return f"Match: {self.user1.email} & {self.user2.email} - {self.match_type}"
    
    def mark_matched(self):
        """Mark as matched when both users like each other"""
        if self.user1_liked and self.user2_liked and self.status != 'matched':
            self.status = 'matched'
            self.matched_at = timezone.now()
            self.save()


class MatchFilter(models.Model):
    """User's matching preferences/filters"""
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='match_filter')
    
    # Gender Preferences
    preferred_gender = models.CharField(max_length=20, blank=True, null=True)
    
    # Travel Experience Preferences
    prefer_first_time_travelers = models.BooleanField(default=False)
    prefer_experienced_travelers = models.BooleanField(default=False)
    
    # Interest-based matching
    require_common_interests = models.BooleanField(default=False)
    min_common_interests = models.IntegerField(default=1)
    
    # Business Networking
    prefer_business_travelers = models.BooleanField(default=False)
    
    # Age Range (if needed)
    min_age = models.IntegerField(null=True, blank=True)
    max_age = models.IntegerField(null=True, blank=True)
    
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Match Filter for {self.user.email}"

