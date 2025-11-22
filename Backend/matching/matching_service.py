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
    def find_matches_for_user(user, flight=None):
        """
        Find all potential matches for a user based on their flight(s)
        
        Scenarios:
        1. Same Departure, Same Layover, Same Destination
        2. Same Layover, Different Destinations
        3. Departure is Someone's Layover or Destination
        4. Same Departure, Different Layovers
        5. Same Departure & Destination (Direct Flight)
        """
        if not flight:
            # Get user's upcoming or current flight
            flight = Flight.objects.filter(
                user=user,
                is_visible=True,
                departure_datetime__gte=timezone.now() - timedelta(hours=2)
            ).order_by('departure_datetime').first()
        
        if not flight:
            return []
        
        matches = []
        
        # Scenario 1: Same Departure, Same Layover, Same Destination
        matches.extend(MatchingService._same_departure_layover_destination(flight))
        
        # Scenario 2: Same Layover, Different Destinations
        matches.extend(MatchingService._same_layover_different_destination(flight))
        
        # Scenario 3: Departure is Someone's Layover or Destination
        matches.extend(MatchingService._departure_is_layover(flight))
        
        # Scenario 4: Same Departure, Different Layovers
        matches.extend(MatchingService._same_departure_different_layovers(flight))
        
        # Scenario 5: Same Departure & Destination (Direct Flight)
        matches.extend(MatchingService._same_route_direct(flight))
        
        # Remove duplicates and filter by preferences
        unique_matches = MatchingService._deduplicate_matches(matches)
        filtered_matches = MatchingService._apply_user_filters(user, unique_matches)
        
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
                flight.layover_start, flight.layover_end,
                other_flight.layover_start, other_flight.layover_end
            )
            if overlap and overlap['duration_hours'] >= 1.0:  # At least 1 hour overlap
                matches.append({
                    'user': other_flight.user,
                    'flight': other_flight,
                    'match_type': 'same_route',
                    'matching_airport': flight.layover_airport,
                    'matching_city': flight.layover_city or '',
                    'overlap': overlap,
                })
        
        return matches
    
    @staticmethod
    def _same_layover_different_destination(flight):
        """Scenario 2: Same layover, different destinations"""
        if not flight.has_layover:
            return []
        
        matches = []
        overlapping_flights = Flight.objects.filter(
            ~Q(user=flight.user),
            is_visible=True,
            has_layover=True,
            layover_airport=flight.layover_airport,
            layover_start__lte=flight.layover_end,
            layover_end__gte=flight.layover_start,
        ).exclude(arrival_airport=flight.arrival_airport)  # Different destination
        
        for other_flight in overlapping_flights:
            overlap = MatchingService._calculate_overlap(
                flight.layover_start, flight.layover_end,
                other_flight.layover_start, other_flight.layover_end
            )
            if overlap and overlap['duration_hours'] >= 1.0:
                matches.append({
                    'user': other_flight.user,
                    'flight': other_flight,
                    'match_type': 'same_layover',
                    'matching_airport': flight.layover_airport,
                    'matching_city': flight.layover_city or '',
                    'overlap': overlap,
                })
        
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
            if other_flight.layover_end >= flight.departure_datetime - timedelta(hours=2):
                overlap = MatchingService._calculate_overlap(
                    other_flight.layover_start, other_flight.layover_end,
                    flight.departure_datetime - timedelta(hours=2), flight.departure_datetime
                )
                if overlap and overlap['duration_hours'] >= 0.5:  # At least 30 minutes
                    matches.append({
                        'user': other_flight.user,
                        'flight': other_flight,
                        'match_type': 'layover_departure',
                        'matching_airport': flight.departure_airport,
                        'matching_city': flight.departure_city,
                        'overlap': overlap,
                    })
        
        # Case 3B: Departure is someone's destination (they're arriving)
        arriving_flights = Flight.objects.filter(
            ~Q(user=flight.user),
            is_visible=True,
            arrival_airport=flight.departure_airport,
            arrival_datetime__lte=flight.departure_datetime,
            arrival_datetime__gte=flight.departure_datetime - timedelta(hours=4),
        )
        
        for other_flight in arriving_flights:
            overlap_duration = (flight.departure_datetime - other_flight.arrival_datetime).total_seconds() / 3600
            if 0.5 <= overlap_duration <= 4.0:  # Between 30 min and 4 hours
                matches.append({
                    'user': other_flight.user,
                    'flight': other_flight,
                    'match_type': 'layover_departure',
                    'matching_airport': flight.departure_airport,
                    'matching_city': flight.departure_city,
                    'overlap': {
                        'start': other_flight.arrival_datetime,
                        'end': flight.departure_datetime,
                        'duration_hours': overlap_duration,
                    },
                })
        
        return matches
    
    @staticmethod
    def _same_departure_different_layovers(flight):
        """Scenario 4: Same departure, different layovers"""
        matches = []
        same_departure_flights = Flight.objects.filter(
            ~Q(user=flight.user),
            is_visible=True,
            departure_airport=flight.departure_airport,
            departure_datetime__date=flight.departure_datetime.date(),
        ).exclude(
            Q(has_layover=True, layover_airport=flight.layover_airport) if flight.has_layover else Q()
        )
        
        for other_flight in same_departure_flights:
            # Check if departure times are close (within 4 hours)
            time_diff = abs((other_flight.departure_datetime - flight.departure_datetime).total_seconds() / 3600)
            if time_diff <= 4.0:
                matches.append({
                    'user': other_flight.user,
                    'flight': other_flight,
                    'match_type': 'same_departure',
                    'matching_airport': flight.departure_airport,
                    'matching_city': flight.departure_city,
                    'overlap': {
                        'start': min(flight.departure_datetime, other_flight.departure_datetime) - timedelta(hours=2),
                        'end': max(flight.departure_datetime, other_flight.departure_datetime),
                        'duration_hours': time_diff + 2,
                    },
                })
        
        return matches
    
    @staticmethod
    def _same_route_direct(flight):
        """Scenario 5: Same departure & destination (direct flight)"""
        if flight.has_layover:
            return []
        
        matches = []
        same_route_flights = Flight.objects.filter(
            ~Q(user=flight.user),
            is_visible=True,
            has_layover=False,
            departure_airport=flight.departure_airport,
            arrival_airport=flight.arrival_airport,
            departure_datetime__date=flight.departure_datetime.date(),
        )
        
        for other_flight in same_route_flights:
            time_diff = abs((other_flight.departure_datetime - flight.departure_datetime).total_seconds() / 3600)
            if time_diff <= 2.0:  # Same day, within 2 hours
                matches.append({
                    'user': other_flight.user,
                    'flight': other_flight,
                    'match_type': 'same_route',
                    'matching_airport': flight.departure_airport,
                    'matching_city': flight.departure_city,
                    'overlap': {
                        'start': min(flight.departure_datetime, other_flight.departure_datetime) - timedelta(hours=1),
                        'end': max(flight.departure_datetime, other_flight.departure_datetime),
                        'duration_hours': time_diff + 1,
                    },
                })
        
        return matches
    
    @staticmethod
    def _calculate_overlap(start1, end1, start2, end2):
        """Calculate overlap between two time ranges"""
        overlap_start = max(start1, start2)
        overlap_end = min(end1, end2)
        
        if overlap_start < overlap_end:
            duration = (overlap_end - overlap_start).total_seconds() / 3600
            return {
                'start': overlap_start,
                'end': overlap_end,
                'duration_hours': duration,
            }
        return None
    
    @staticmethod
    def _deduplicate_matches(matches):
        """Remove duplicate matches (same user)"""
        seen_users = set()
        unique_matches = []
        
        for match in matches:
            user_id = match['user'].id
            if user_id not in seen_users:
                seen_users.add(user_id)
                unique_matches.append(match)
        
        return unique_matches
    
    @staticmethod
    def _apply_user_filters(user, matches):
        """Apply user's matching preferences/filters"""
        try:
            match_filter = user.match_filter
        except MatchFilter.DoesNotExist:
            match_filter = None
        
        filtered = []
        
        for match in matches:
            other_user = match['user']
            score = 1.0
            
            # Gender preference
            if match_filter and match_filter.preferred_gender:
                if other_user.gender != match_filter.preferred_gender:
                    continue
            
            # Travel experience preferences
            try:
                other_pref = other_user.travel_preference
                user_pref = user.travel_preference
                
                if match_filter:
                    if match_filter.prefer_first_time_travelers and not other_pref.is_first_international:
                        score *= 0.8
                    if match_filter.prefer_experienced_travelers and other_pref.is_first_international:
                        score *= 0.8
                
                # Guide matching
                if user_pref.looking_for_guide and other_pref.offering_guidance:
                    score *= 1.5
                if user_pref.offering_guidance and other_pref.looking_for_guide:
                    score *= 1.5
                
            except TravelPreference.DoesNotExist:
                pass
            
            # Common interests
            user_interests = set(user.interests.values_list('interest', flat=True))
            other_interests = set(other_user.interests.values_list('interest', flat=True))
            common = user_interests & other_interests
            
            if common:
                match['common_interests'] = list(common)
                score *= (1 + len(common) * 0.2)  # Boost score for common interests
            
            match['match_score'] = score
            filtered.append(match)
        
        # Sort by match score
        filtered.sort(key=lambda x: x['match_score'], reverse=True)
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
                'match_type': match_data['match_type'],
                'matching_airport': match_data['matching_airport'],
                'matching_city': match_data['matching_city'],
                'overlap_start': match_data['overlap']['start'],
                'overlap_end': match_data['overlap']['end'],
                'overlap_duration_hours': match_data['overlap']['duration_hours'],
                'match_score': match_data.get('match_score', 1.0),
                'common_interests': match_data.get('common_interests', []),
            }
        )
        
        if not created:
            # Update existing match
            match.match_score = match_data.get('match_score', match.match_score)
            match.common_interests = match_data.get('common_interests', match.common_interests)
            match.save()
        
        return match

