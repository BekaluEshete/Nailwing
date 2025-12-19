# Matching Fetch Fix

## Problem

Matches were not being correctly fetched based on the 5 matching scenarios, even when there were valid matches available.

## Root Causes

1. **Overly restrictive absolute time filters**: Scenarios 2, 4, and 5 were filtering flights by absolute time windows (comparing against "now"), which excluded valid matches that should have been found based on relative time differences.

2. **Missing `open_to_meeting` filter**: All scenarios were missing the `open_to_meeting=True` filter, which is required per documentation.

3. **Missing same-date checks**: Scenarios 4 and 5 should only match flights on the same departure date (per documentation), but this check was not implemented.

## Fixes Applied

### 1. Removed Absolute Time Window Filters

**Scenario 2 (Same Layover, Different Destinations):**
- **Removed:** `layover_start__gte=now - timedelta(days=1)`, `layover_end__lte=now + timedelta(days=7)`
- **Kept:** Relative overlap checks between flights' layover times
- **Reason:** Matches should be based on relative time overlap, not absolute time windows

**Scenario 4 (Same Departure, Different Layovers):**
- **Removed:** `departure_datetime__gte=now - timedelta(days=1)`, `departure_datetime__lte=now + timedelta(days=7)`
- **Kept:** Relative time difference check (≤ 4 hours)
- **Reason:** Matches should be based on relative departure times, not absolute windows

**Scenario 5 (Same Route Direct):**
- **Removed:** `departure_datetime__gte=now - timedelta(days=1)`, `departure_datetime__lte=now + timedelta(days=7)`
- **Kept:** Relative time difference check (≤ 2 hours)
- **Reason:** Matches should be based on relative departure times, not absolute windows

### 2. Added Same-Date Checks

**Scenario 4:**
- Added check: `if flight.departure_datetime.date() != other_flight.departure_datetime.date(): continue`
- **Reason:** Documentation requires same departure date for this scenario

**Scenario 5:**
- Added check: `if flight.departure_datetime.date() != other_flight.departure_datetime.date(): continue`
- **Reason:** Documentation requires same departure date for this scenario

### 3. Added `open_to_meeting=True` Filter

Added to **all 5 scenarios**:
- Scenario 1: Same Departure, Same Layover, Same Destination
- Scenario 2: Same Layover, Different Destinations
- Scenario 3: Departure is Someone's Layover or Destination (both Case 3A and 3B)
- Scenario 4: Same Departure, Different Layovers
- Scenario 5: Same Route (Direct Flight)
- Scenario 6: Same Airport Flexible (fallback scenario)

**Reason:** Documentation states flights must have `is_visible=True` and `open_to_meeting=True` to be included in matching.

## Time Windows (Per Documentation)

These are still enforced correctly:
- **Scenario 1:** ≥ 1 hour layover overlap
- **Scenario 2:** ≥ 1 hour layover overlap
- **Scenario 3A:** ≥ 30 minutes overlap
- **Scenario 3B:** 30 minutes to 4 hours gap
- **Scenario 4:** ≤ 4 hours departure time difference, **same date**
- **Scenario 5:** ≤ 2 hours departure time difference, **same date**

## Testing Checklist

- [x] Scenario 1: Finds matches with same route and layover overlap
- [x] Scenario 2: Finds matches with same layover but different destinations
- [x] Scenario 3: Finds matches where departure is someone's layover/destination
- [x] Scenario 4: Finds matches with same departure on same date (within 4 hours)
- [x] Scenario 5: Finds matches with same route on same date (within 2 hours)
- [x] All scenarios respect `open_to_meeting=True` filter
- [x] All scenarios respect `is_visible=True` filter

## Files Modified

- `Backend/matching/matching_service.py`
  - Removed absolute time filters from scenarios 2, 4, 5
  - Added same-date checks to scenarios 4 and 5
  - Added `open_to_meeting=True` filter to all scenarios

## Expected Behavior

After these fixes:
1. Matches will be found based on **relative time differences** between flights, not absolute time windows
2. Scenarios 4 and 5 will only match flights on the **same departure date**
3. Only flights with `open_to_meeting=True` will be considered for matching
4. Time windows (4 hours, 2 hours, 1 hour) are still enforced correctly per documentation

