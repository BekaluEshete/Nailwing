"""
Celery tasks for the recommendations app.

fetch_airport_recommendations — fetches places from Google/Foursquare/Overpass
                                 for an airport and stores the result in Redis.
                                 Called when the cache is cold so the HTTP call
                                 happens in a worker, not in the request cycle.
"""
import logging
from celery import shared_task
from django.core.cache import cache

logger = logging.getLogger("recommendations")


@shared_task(
    bind=True,
    max_retries=3,
    default_retry_delay=10,
    soft_time_limit=25,
    time_limit=40,
    name="recommendations.tasks.fetch_airport_recommendations",
)
def fetch_airport_recommendations(self, airport_code: str):
    """
    Fetch places (hotels, cafes, restaurants) near an airport and cache the result.

    This task is triggered when the recommendations cache is cold. Running it in
    a Celery worker means the external HTTP call (Google Places API / Foursquare /
    Overpass) never blocks a Django worker thread.

    Args:
        airport_code: IATA airport code (e.g. "DXB", "ADD")
    """
    from recommendations.places_api_service import PlacesAPIService
    from recommendations.views import _recommendations_cache_key, CACHE_TTL_RECOMMENDATIONS

    airport_code = airport_code.upper()
    logger.info("fetch_airport_recommendations started for %s", airport_code)

    try:
        places_api = PlacesAPIService()
        places_data = places_api.get_places_near_airport(
            airport_code=airport_code,
            categories=["hotel", "cafe", "restaurant"],
            limit_per_category=15,
        )

        cache_key = _recommendations_cache_key(airport_code)
        cache.set(cache_key, places_data, CACHE_TTL_RECOMMENDATIONS)

        total = sum(len(v) for v in places_data.values())
        logger.info(
            "fetch_airport_recommendations cached %d places for %s",
            total, airport_code,
        )
        return {"status": "ok", "airport": airport_code, "total_places": total}

    except Exception as exc:
        logger.error("fetch_airport_recommendations failed for %s: %s", airport_code, exc)
        raise self.retry(exc=exc)
