"""
Signals for Flight model to handle match cancellation when flights are cancelled.
"""
import logging

from django.db.models.signals import pre_save
from django.db.models import Q
from django.dispatch import receiver
from .models import Flight

logger = logging.getLogger("flights")


@receiver(pre_save, sender=Flight)
def handle_flight_cancellation(sender, instance, **kwargs):
    """
    Expire all pending/active matches when a flight is cancelled.
    Only runs on updates (not new flight creation).
    """
    if not instance.pk:
        return

    try:
        old_instance = Flight.objects.get(pk=instance.pk)
    except Flight.DoesNotExist:
        return

    if old_instance.status == "cancelled" or instance.status != "cancelled":
        return

    from matching.models import Match

    matches_to_expire = Match.objects.filter(
        Q(flight1=instance) | Q(flight2=instance),
        status__in=["pending", "viewed", "connection_requested", "matched"],
    )

    count = matches_to_expire.count()
    matches_to_expire.update(status="expired")

    logger.info(
        "Flight %s cancelled — expired %d related match(es)",
        instance.flight_number,
        count,
    )
