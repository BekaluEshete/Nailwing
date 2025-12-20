"""
Signals for Flight model to handle match cancellation when flights are cancelled
"""
from django.db.models.signals import pre_save
from django.db.models import Q
from django.dispatch import receiver
from .models import Flight


@receiver(pre_save, sender=Flight)
def handle_flight_cancellation(sender, instance, **kwargs):
    """
    Cancel matches when a flight is cancelled
    """
    # Check if this is an update (not a new flight)
    if instance.pk:
        try:
            old_instance = Flight.objects.get(pk=instance.pk)
            # If flight status changed to 'cancelled'
            if old_instance.status != 'cancelled' and instance.status == 'cancelled':
                # Cancel all matches related to this flight
                from matching.models import Match
                
                # Cancel matches where this flight is flight1 or flight2
                matches_to_cancel = Match.objects.filter(
                    (Q(flight1=instance) | Q(flight2=instance)),
                    status__in=['pending', 'viewed', 'connection_requested', 'matched']
                )
                
                for match in matches_to_cancel:
                    match.status = 'expired'
                    match.save(update_fields=['status'])
                    
                print(f"✅ [Flight Signal] Cancelled {matches_to_cancel.count()} matches for cancelled flight {instance.flight_number}")
                
        except Flight.DoesNotExist:
            # New flight, nothing to cancel
            pass

