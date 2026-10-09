"""
Celery tasks for the matching app.

run_matching_for_user  — finds and persists matches for a user asynchronously.
                         Called from find_matches view after returning the cached
                         or stale result, so the expensive 6-query algorithm runs
                         in a worker instead of the request-response cycle.
"""
import logging
from celery import shared_task
from django.core.cache import cache

logger = logging.getLogger("matching")


@shared_task(
    bind=True,
    max_retries=3,
    default_retry_delay=5,
    soft_time_limit=30,
    time_limit=60,
    name="matching.tasks.run_matching_for_user",
)
def run_matching_for_user(self, user_id: int, flight_id: int = None):
    """
    Run the full matching algorithm for a user and persist the results.

    This task:
    1. Fetches the user and optional flight from the DB
    2. Runs MatchingService.find_matches_for_user (6 DB queries + scoring)
    3. Creates/updates Match records for all candidates found
    4. Invalidates the find_matches cache for this user so the next API
       call returns fresh results

    Args:
        user_id:   ID of the user to find matches for
        flight_id: (optional) specific flight ID to match against
    """
    from authentication.models import CustomUser
    from flights.models import Flight
    from matching.models import Match
    from matching.matching_service import MatchingService
    from matching.views import _matches_cache_key
    from django.utils import timezone
    from datetime import timedelta

    logger.info("run_matching_for_user started for user_id=%s flight_id=%s", user_id, flight_id)

    try:
        user = CustomUser.objects.get(id=user_id)
    except CustomUser.DoesNotExist:
        logger.error("run_matching_for_user: user %s not found", user_id)
        return {"status": "error", "reason": "user_not_found"}

    flight = None
    if flight_id:
        try:
            flight = Flight.objects.get(id=flight_id, user=user)
        except Flight.DoesNotExist:
            logger.warning("run_matching_for_user: flight %s not found for user %s", flight_id, user_id)
            return {"status": "error", "reason": "flight_not_found"}

    try:
        match_data_list = MatchingService.find_matches_for_user(user, flight)
    except Exception as exc:
        logger.error("run_matching_for_user: matching service error for user %s: %s", user_id, exc)
        raise self.retry(exc=exc)

    if not match_data_list:
        logger.info("run_matching_for_user: no matches found for user %s", user_id)
        return {"status": "ok", "matches_found": 0}

    # Determine which flight was actually used (service may have auto-selected one)
    if not flight:
        now = timezone.now()
        flight = (
            Flight.objects.filter(
                user=user,
                is_visible=True,
                departure_datetime__gte=now - timedelta(hours=24),
                departure_datetime__lte=now + timedelta(days=7),
            )
            .order_by("departure_datetime")
            .first()
        )

    if not flight:
        return {"status": "ok", "matches_found": 0}

    created_count = 0
    updated_count = 0

    for match_data in match_data_list:
        other_user = match_data["user"]
        other_flight = match_data["flight"]

        # Enforce user1 = smaller ID for consistent unique_together constraint
        if user.id < other_user.id:
            u1, u2, f1, f2 = user, other_user, flight, other_flight
        else:
            u1, u2, f1, f2 = other_user, user, other_flight, flight

        match, created = Match.objects.get_or_create(
            user1=u1,
            user2=u2,
            flight1=f1,
            flight2=f2,
            defaults={
                "match_type": match_data["match_type"],
                "matching_airport": match_data["matching_airport"],
                "matching_city": match_data["matching_city"],
                "overlap_start": match_data["overlap"]["start"],
                "overlap_end": match_data["overlap"]["end"],
                "overlap_duration_hours": match_data["overlap"]["duration_hours"],
                "match_score": match_data.get("match_score", 0.5),
                "common_interests": match_data.get("common_interests", []),
            },
        )

        if not created:
            # Update score and interests if match already exists
            match.match_score = match_data.get("match_score", match.match_score)
            match.common_interests = match_data.get("common_interests", match.common_interests)
            match.save(update_fields=["match_score", "common_interests", "updated_at"])
            updated_count += 1
        else:
            created_count += 1

    # Invalidate cache so next API call reflects the fresh results
    cache.delete(_matches_cache_key(user_id, flight_id))
    cache.delete(_matches_cache_key(user_id))

    logger.info(
        "run_matching_for_user complete for user %s: %d created, %d updated",
        user_id, created_count, updated_count,
    )
    return {"status": "ok", "matches_found": len(match_data_list), "created": created_count, "updated": updated_count}
