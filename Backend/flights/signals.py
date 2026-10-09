"""
Signals for Flight model:
- Expire related matches when a flight is cancelled (pre_save)
- Invalidate the community_posts cache when any flight is created/updated (post_save)
"""
import logging

from django.core.cache import cache
from django.db.models.signals import pre_save, post_save
from django.db.models import Q
from django.dispatch import receiver
from .models import Flight
from .views import CACHE_KEY_COMMUNITY_POSTS

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


@receiver(post_save, sender=Flight)
def invalidate_community_posts_cache(sender, instance, **kwargs):
    """
    Invalidate the community_posts cache whenever any flight is created or updated.
    This ensures the community feed stays fresh after flight changes.
    """
    cache.delete(CACHE_KEY_COMMUNITY_POSTS)
    logger.debug("community_posts cache invalidated after flight %s save", instance.flight_number)
