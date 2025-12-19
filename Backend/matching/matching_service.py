"""
Smart Matching Algorithm for Nilewing
Implements all matching scenarios based on flight paths and user preferences
"""

from datetime import timedelta
from django.utils import timezone
from django.db.models import Q
from authentication.models import CustomUser
from flights.models import Flight, UserInterest, TravelPreference
from matching.models import Match, MatchFilter


class MatchingService:
    """Service for finding and creating matches between users"""

    @staticmethod
    def calculate_common_interests(user1, user2):
        """
        Calculate common interests between two users (case-insensitive)
        Returns list of common interests with original casing preserved
        """
        user1_interests_list = list(user1.interests.values_list("interest", flat=True))
        user2_interests_list = list(user2.interests.values_list("interest", flat=True))

        # Normalize interests to lowercase for case-insensitive comparison
        user1_interests_normalized = {
            i.lower().strip() for i in user1_interests_list if i
        }
        user2_interests_normalized = {
            i.lower().strip() for i in user2_interests_list if i
        }

        # Find common interests (case-insensitive)
        common_normalized = user1_interests_normalized & user2_interests_normalized

        # Get original casing from user1's interests for display
        common_interests = []
        for normalized_interest in common_normalized:
            # Try to find original casing from user1's interests first
            for interest in user1_interests_list:
                if interest and interest.lower().strip() == normalized_interest:
                    common_interests.append(interest.strip())
                    break
            else:
                # If not found in user1's, try user2's interests
                for interest in user2_interests_list:
                    if interest and interest.lower().strip() == normalized_interest:
                        common_interests.append(interest.strip())
                        break
                else:
                    # Fallback: use normalized version with title case
                    common_interests.append(normalized_interest.title())

        return common_interests

    @staticmethod
    def find_matches_for_user(user, flight=None):
        """
        Find all potential matches for a user based on their flight(s)

        Scenarios:
        1. Same Departure, Same Layover, Same Destination
        2. Same Layover, Different Destinations
        3. Departure is Someone's Layover or Destination
        4. Same Departure, Different Layovers
        5. Same Departure & Destination (Direct Flight)
        6. Same Airport (any overlap) - Fallback
        """
        if not flight:
            # Get user's upcoming or current flight - EXPANDED TIME WINDOW
            # Look for flights up to 7 days in the future and 24 hours in the past
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

            # If no flight in expanded window, try any visible flight
            if not flight:
                flight = (
                    Flight.objects.filter(user=user, is_visible=True)
                    .order_by("departure_datetime")
                    .first()
                )

        if not flight:
            print(f"❌ [MatchingService] No flight found for user {user.email}")
            return []

        print(
            f"🔍 [MatchingService] Finding matches for flight: {flight.flight_number} ({flight.departure_airport} → {flight.arrival_airport})"
        )
        print(f"   Departure: {flight.departure_datetime}")
        print(f"   Has layover: {flight.has_layover}")
        if flight.has_layover:
            print(
                f"   Layover: {flight.layover_airport} ({flight.layover_start} - {flight.layover_end})"
            )

        matches = []

        # Scenario 1: Same Departure, Same Layover, Same Destination
        scenario1_matches = MatchingService._same_departure_layover_destination(flight)
        matches.extend(scenario1_matches)
        print(f"   Scenario 1 (same route): {len(scenario1_matches)} matches")

        # Scenario 2: Same Layover, Different Destinations
        scenario2_matches = MatchingService._same_layover_different_destination(flight)
        matches.extend(scenario2_matches)
        print(f"   Scenario 2 (same layover): {len(scenario2_matches)} matches")

        # Scenario 3: Departure is Someone's Layover or Destination
        scenario3_matches = MatchingService._departure_is_layover(flight)
        matches.extend(scenario3_matches)
        print(f"   Scenario 3 (departure is layover): {len(scenario3_matches)} matches")

        # Scenario 4: Same Departure, Different Layovers
        scenario4_matches = MatchingService._same_departure_different_layovers(flight)
        matches.extend(scenario4_matches)
        print(f"   Scenario 4 (same departure): {len(scenario4_matches)} matches")

        # Scenario 5: Same Departure & Destination (Direct Flight)
        scenario5_matches = MatchingService._same_route_direct(flight)
        matches.extend(scenario5_matches)
        print(f"   Scenario 5 (same route direct): {len(scenario5_matches)} matches")

        # Scenario 6: Same Airport (any overlap) - More flexible fallback
        # Always try this scenario, not just when others fail
        scenario6_matches = MatchingService._same_airport_flexible(flight)
        matches.extend(scenario6_matches)
        print(
            f"   Scenario 6 (same airport flexible): {len(scenario6_matches)} matches"
        )

        # Remove duplicates and filter by preferences
        unique_matches = MatchingService._deduplicate_matches(matches)
        print(f"   After deduplication: {len(unique_matches)} unique matches")

        filtered_matches = MatchingService._apply_user_filters(user, unique_matches)
        print(f"   After filtering: {len(filtered_matches)} final matches")

        return filtered_matches

    @staticmethod
    def _same_departure_layover_destination(flight):
        """Scenario 1: Same departure, same layover, same destination"""
        if not flight.has_layover:
            return []

        matches = []
        overlapping_flights = Flight.objects.filter(
            ~Q(user=flight.user),
            is_visible=True,
            departure_airport=flight.departure_airport,
            layover_airport=flight.layover_airport,
            arrival_airport=flight.arrival_airport,
            layover_start__lte=flight.layover_end,
            layover_end__gte=flight.layover_start,
        )

        for other_flight in overlapping_flights:
            overlap = MatchingService._calculate_overlap(
                flight.layover_start,
                flight.layover_end,
                other_flight.layover_start,
                other_flight.layover_end,
            )
            if overlap and overlap["duration_hours"] >= 1.0:  # At least 1 hour overlap
                matches.append(
                    {
                        "user": other_flight.user,
                        "flight": other_flight,
                        "match_type": "same_route",
                        "matching_airport": flight.layover_airport,
                        "matching_city": flight.layover_city or "",
                        "overlap": overlap,
                    }
                )

        return matches

    @staticmethod
    def _same_layover_different_destination(flight):
        """Scenario 2: Same layover, different destinations"""
        if not flight.has_layover or not flight.layover_airport:
            return []

        matches = []
        # More flexible time window for layover matching
        now = timezone.now()
        overlapping_flights = Flight.objects.filter(
            ~Q(user=flight.user),
            is_visible=True,
            has_layover=True,
            layover_airport=flight.layover_airport,
            layover_start__lte=flight.layover_end + timedelta(hours=2),
            layover_end__gte=flight.layover_start - timedelta(hours=2),
            layover_start__gte=now - timedelta(days=1),
            layover_end__lte=now + timedelta(days=7),
        ).exclude(
            arrival_airport=flight.arrival_airport
        )  # Different destination

        for other_flight in overlapping_flights:
            overlap = MatchingService._calculate_overlap(
                flight.layover_start,
                flight.layover_end,
                other_flight.layover_start,
                other_flight.layover_end,
            )
            # At least 1 hour overlap required (per documentation)
            if overlap and overlap["duration_hours"] >= 1.0:
                matches.append(
                    {
                        "user": other_flight.user,
                        "flight": other_flight,
                        "match_type": "same_layover",
                        "matching_airport": flight.layover_airport,
                        "matching_city": flight.layover_city or "",
                        "overlap": overlap,
                    }
                )

        return matches

    @staticmethod
    def _departure_is_layover(flight):
        """Scenario 3: User's departure is someone's layover or destination"""
        matches = []

        # Case 3A: Departure is someone's layover
        layover_flights = Flight.objects.filter(
            ~Q(user=flight.user),
            is_visible=True,
            has_layover=True,
            layover_airport=flight.departure_airport,
            layover_start__lte=flight.departure_datetime + timedelta(hours=2),
            layover_end__gte=flight.departure_datetime - timedelta(hours=2),
        )

        for other_flight in layover_flights:
            # Check if there's time overlap before user's departure
            if other_flight.layover_end >= flight.departure_datetime - timedelta(
                hours=2
            ):
                overlap = MatchingService._calculate_overlap(
                    other_flight.layover_start,
                    other_flight.layover_end,
                    flight.departure_datetime - timedelta(hours=2),
                    flight.departure_datetime,
                )
                if overlap and overlap["duration_hours"] >= 0.5:  # At least 30 minutes
                    matches.append(
                        {
                            "user": other_flight.user,
                            "flight": other_flight,
                            "match_type": "layover_departure",
                            "matching_airport": flight.departure_airport,
                            "matching_city": flight.departure_city,
                            "overlap": overlap,
                        }
                    )

        # Case 3B: Departure is someone's destination (they're arriving)
        arriving_flights = Flight.objects.filter(
            ~Q(user=flight.user),
            is_visible=True,
            arrival_airport=flight.departure_airport,
            arrival_datetime__lte=flight.departure_datetime,
            arrival_datetime__gte=flight.departure_datetime - timedelta(hours=4),
        )

        for other_flight in arriving_flights:
            overlap_duration = (
                flight.departure_datetime - other_flight.arrival_datetime
            ).total_seconds() / 3600
            if 0.5 <= overlap_duration <= 4.0:  # Between 30 min and 4 hours
                matches.append(
                    {
                        "user": other_flight.user,
                        "flight": other_flight,
                        "match_type": "layover_departure",
                        "matching_airport": flight.departure_airport,
                        "matching_city": flight.departure_city,
                        "overlap": {
                            "start": other_flight.arrival_datetime,
                            "end": flight.departure_datetime,
                            "duration_hours": overlap_duration,
                        },
                    }
                )

        return matches

    @staticmethod
    def _same_departure_different_layovers(flight):
        """Scenario 4: Same departure, different layovers"""
        matches = []
        now = timezone.now()
        same_departure_flights = Flight.objects.filter(
            ~Q(user=flight.user),
            is_visible=True,
            departure_airport=flight.departure_airport,
            departure_datetime__gte=now - timedelta(days=1),
            departure_datetime__lte=now + timedelta(days=7),
        ).exclude(
            Q(has_layover=True, layover_airport=flight.layover_airport)
            if flight.has_layover and flight.layover_airport
            else Q()
        )

        for other_flight in same_departure_flights:
            # Within 4 hours of each other (per documentation)
            time_diff = abs(
                (
                    other_flight.departure_datetime - flight.departure_datetime
                ).total_seconds()
                / 3600
            )
            if time_diff <= 4.0:
                matches.append(
                    {
                        "user": other_flight.user,
                        "flight": other_flight,
                        "match_type": "same_departure",
                        "matching_airport": flight.departure_airport,
                        "matching_city": flight.departure_city,
                        "overlap": {
                            "start": min(
                                flight.departure_datetime,
                                other_flight.departure_datetime,
                            )
                            - timedelta(hours=2),
                            "end": max(
                                flight.departure_datetime,
                                other_flight.departure_datetime,
                            ),
                            "duration_hours": max(time_diff + 2, 0.5),
                        },
                    }
                )

        return matches

    @staticmethod
    def _same_route_direct(flight):
        """Scenario 5: Same departure & destination (direct flight)"""
        if flight.has_layover:
            return []

        matches = []
        # Expanded time window - same day or within 7 days
        now = timezone.now()
        same_route_flights = Flight.objects.filter(
            ~Q(user=flight.user),
            is_visible=True,
            has_layover=False,
            departure_airport=flight.departure_airport,
            arrival_airport=flight.arrival_airport,
            departure_datetime__gte=now - timedelta(days=1),
            departure_datetime__lte=now + timedelta(days=7),
        )

        for other_flight in same_route_flights:
            time_diff = abs(
                (
                    other_flight.departure_datetime - flight.departure_datetime
                ).total_seconds()
                / 3600
            )
            # Within 2 hours of each other (per documentation)
            if time_diff <= 2.0:
                matches.append(
                    {
                        "user": other_flight.user,
                        "flight": other_flight,
                        "match_type": "same_route",
                        "matching_airport": flight.departure_airport,
                        "matching_city": flight.departure_city,
                        "overlap": {
                            "start": min(
                                flight.departure_datetime,
                                other_flight.departure_datetime,
                            )
                            - timedelta(hours=1),
                            "end": max(
                                flight.departure_datetime,
                                other_flight.departure_datetime,
                            ),
                            "duration_hours": max(
                                time_diff + 1, 0.5
                            ),  # At least 30 minutes
                        },
                    }
                )

        return matches

    @staticmethod
    def _same_airport_flexible(flight):
        """Scenario 6: Same airport with flexible time matching (fallback)"""
        matches = []
        now = timezone.now()

        # Find flights with same departure airport (within 7 days)
        same_departure_flights = Flight.objects.filter(
            ~Q(user=flight.user),
            is_visible=True,
            departure_airport=flight.departure_airport,
            departure_datetime__gte=now - timedelta(days=1),
            departure_datetime__lte=now + timedelta(days=7),
        )[
            :10
        ]  # Limit to 10 to avoid too many matches

        for other_flight in same_departure_flights:
            time_diff = abs(
                (
                    other_flight.departure_datetime - flight.departure_datetime
                ).total_seconds()
                / 3600
            )
            # Match if within 12 hours
            if time_diff <= 12.0:
                matches.append(
                    {
                        "user": other_flight.user,
                        "flight": other_flight,
                        "match_type": "same_departure",
                        "matching_airport": flight.departure_airport,
                        "matching_city": flight.departure_city,
                        "overlap": {
                            "start": min(
                                flight.departure_datetime,
                                other_flight.departure_datetime,
                            )
                            - timedelta(hours=2),
                            "end": max(
                                flight.departure_datetime,
                                other_flight.departure_datetime,
                            ),
                            "duration_hours": max(time_diff + 2, 0.5),
                        },
                    }
                )

        # Also check same arrival airport
        same_arrival_flights = Flight.objects.filter(
            ~Q(user=flight.user),
            is_visible=True,
            arrival_airport=flight.arrival_airport,
            arrival_datetime__gte=now - timedelta(days=1),
            arrival_datetime__lte=now + timedelta(days=7),
        )[:10]

        for other_flight in same_arrival_flights:
            time_diff = abs(
                (
                    other_flight.arrival_datetime - flight.arrival_datetime
                ).total_seconds()
                / 3600
            )
            if time_diff <= 12.0:
                matches.append(
                    {
                        "user": other_flight.user,
                        "flight": other_flight,
                        "match_type": "same_destination",
                        "matching_airport": flight.arrival_airport,
                        "matching_city": flight.arrival_city,
                        "overlap": {
                            "start": min(
                                flight.arrival_datetime, other_flight.arrival_datetime
                            )
                            - timedelta(hours=2),
                            "end": max(
                                flight.arrival_datetime, other_flight.arrival_datetime
                            ),
                            "duration_hours": max(time_diff + 2, 0.5),
                        },
                    }
                )

        return matches

    @staticmethod
    def _calculate_overlap(start1, end1, start2, end2):
        """Calculate overlap between two time ranges"""
        overlap_start = max(start1, start2)
        overlap_end = min(end1, end2)

        if overlap_start < overlap_end:
            duration = (overlap_end - overlap_start).total_seconds() / 3600
            return {
                "start": overlap_start,
                "end": overlap_end,
                "duration_hours": duration,
            }
        return None

    @staticmethod
    def _deduplicate_matches(matches):
        """Remove duplicate matches (same user)"""
        seen_users = set()
        unique_matches = []

        for match in matches:
            user_id = match["user"].id
            if user_id not in seen_users:
                seen_users.add(user_id)
                unique_matches.append(match)

        return unique_matches

    @staticmethod
    def _apply_user_filters(user, matches):
        """Apply user's matching preferences/filters per documentation

        Filters (exclude completely):
        - Gender preference: Exclude if doesn't match
        - Common interests: Exclude if require_common_interests and doesn't meet minimum

        Score adjustments:
        - Travel experience mismatch: ×0.8 multiplier
        - Common interests: +0.2 per shared interest
        - Guide matching: ×1.5 multiplier
        """
        try:
            match_filter = user.match_filter
        except MatchFilter.DoesNotExist:
            match_filter = None

        filtered = []

        for match in matches:
            other_user = match["user"]
            score = 1.0

            # Gender preference - EXCLUDE if doesn't match (per documentation)
            if match_filter and match_filter.preferred_gender:
                if (
                    other_user.gender
                    and other_user.gender != match_filter.preferred_gender
                ):
                    # Exclude this match (per documentation)
                    print(
                        f"   ❌ Gender filter: Excluding {other_user.email} ({other_user.gender} vs required {match_filter.preferred_gender})"
                    )
                    continue  # Skip this match entirely

            # Travel experience preferences - Adjust score only (×0.8 for mismatch)
            try:
                other_pref = other_user.travel_preference
                user_pref = user.travel_preference

                if match_filter:
                    if (
                        match_filter.prefer_first_time_travelers
                        and other_pref
                        and not other_pref.is_first_international
                    ):
                        score *= 0.8  # Travel experience mismatch (per documentation)
                    if (
                        match_filter.prefer_experienced_travelers
                        and other_pref
                        and other_pref.is_first_international
                    ):
                        score *= 0.8  # Travel experience mismatch (per documentation)

                # Guide matching - Boost score
                if user_pref and other_pref:
                    if user_pref.looking_for_guide and other_pref.offering_guidance:
                        score *= 1.5
                    if user_pref.offering_guidance and other_pref.looking_for_guide:
                        score *= 1.5

            except TravelPreference.DoesNotExist:
                pass

            # Common interests - Boost score (case-insensitive comparison)
            common_interests = MatchingService.calculate_common_interests(
                user, other_user
            )

            # Always set common_interests, even if empty
            match["common_interests"] = common_interests

            # Check if user requires common interests filter
            if match_filter and match_filter.require_common_interests:
                min_interests = match_filter.min_common_interests or 1
                if len(common_interests) < min_interests:
                    # Exclude if doesn't meet minimum common interests requirement
                    print(
                        f"   ❌ Common interests filter: Excluding {other_user.email} (only {len(common_interests)} common interests, requires {min_interests})"
                    )
                    continue  # Skip this match entirely

            if common_interests:
                # Boost score: +0.2 per shared interest (per documentation)
                # Formula: 1.0 × (1 + len(common_interests) × 0.2)
                score *= 1 + len(common_interests) * 0.2
                print(
                    f"   ✅ Common interests with {other_user.email}: {common_interests} (score boost: {len(common_interests) * 0.2})"
                )
            else:
                user_interests_list = list(
                    user.interests.values_list("interest", flat=True)
                )
                other_interests_list = list(
                    other_user.interests.values_list("interest", flat=True)
                )
                print(f"   ℹ️ No common interests with {other_user.email}")
                print(f"      User interests: {user_interests_list}")
                print(f"      Other interests: {other_interests_list}")

            match["match_score"] = score
            filtered.append(match)

        # Sort by match score
        filtered.sort(key=lambda x: x["match_score"], reverse=True)
        return filtered

    @staticmethod
    def create_or_update_match(user1, user2, flight1, flight2, match_data):
        """Create or update a match record"""
        match, created = Match.objects.get_or_create(
            user1=user1,
            user2=user2,
            flight1=flight1,
            flight2=flight2,
            defaults={
                "match_type": match_data["match_type"],
                "matching_airport": match_data["matching_airport"],
                "matching_city": match_data["matching_city"],
                "overlap_start": match_data["overlap"]["start"],
                "overlap_end": match_data["overlap"]["end"],
                "overlap_duration_hours": match_data["overlap"]["duration_hours"],
                "match_score": match_data.get("match_score", 1.0),
                "common_interests": match_data.get("common_interests", []),
            },
        )

        if not created:
            # Update existing match
            match.match_score = match_data.get("match_score", match.match_score)
            match.common_interests = match_data.get(
                "common_interests", match.common_interests
            )
            match.save()

        return match
