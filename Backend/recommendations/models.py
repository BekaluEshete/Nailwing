from django.db import models
from authentication.models import CustomUser


class AirportPlace(models.Model):
    """Places/amenities at airports"""
    PLACE_TYPE_CHOICES = [
        ('restaurant', 'Restaurant'),
        ('cafe', 'Café'),
        ('lounge', 'Lounge'),
        ('charging_station', 'Charging Station'),
        ('shop', 'Shop'),
        ('restroom', 'Restroom'),
        ('gate', 'Gate'),
        ('information', 'Information Desk'),
    ]
    
    airport_code = models.CharField(max_length=10)  # IATA code
    name = models.CharField(max_length=200)
    place_type = models.CharField(max_length=30, choices=PLACE_TYPE_CHOICES)
    terminal = models.CharField(max_length=20, blank=True)
    description = models.TextField(blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    rating = models.FloatField(default=0.0)
    price_range = models.CharField(max_length=20, blank=True)  # $, $$, $$$, etc.
    opening_hours = models.CharField(max_length=100, blank=True)
    is_24_hours = models.BooleanField(default=False)
    
    class Meta:
        indexes = [
            models.Index(fields=['airport_code', 'place_type']),
        ]
    
    def __str__(self):
        return f"{self.name} - {self.airport_code}"


class UserRecommendation(models.Model):
    """Recommendations for users based on their location and preferences"""
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='recommendations')
    place = models.ForeignKey(AirportPlace, on_delete=models.CASCADE)
    airport_code = models.CharField(max_length=10)
    reason = models.TextField(blank=True)  # Why this was recommended
    distance_meters = models.FloatField(null=True, blank=True)
    is_viewed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['distance_meters', '-place__rating']
    
    def __str__(self):
        return f"Recommendation for {self.user.email} - {self.place.name}"

