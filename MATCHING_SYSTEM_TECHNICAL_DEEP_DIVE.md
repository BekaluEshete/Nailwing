# 🔬 Matching System - Technical Deep Dive

**Complete technical analysis of the Nilewing matching algorithm**

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Matching Service Flow](#matching-service-flow)
3. [The 6 Matching Scenarios](#the-6-matching-scenarios)
4. [Match Scoring Algorithm](#match-scoring-algorithm)
5. [Filtering System](#filtering-system)
6. [API Endpoints & Flow](#api-endpoints--flow)
7. [Database Models](#database-models)
8. [Performance Considerations](#performance-considerations)
9. [Code Examples](#code-examples)

---

## 🏗️ Architecture Overview

### **Component Structure**

```
┌─────────────────────────────────────────────────────────┐
│                    Frontend (Flutter)                    │
│  MatchScreen → MatchViewModel → MatchService             │
└──────────────────────┬──────────────────────────────────┘
                        │ HTTP GET
                        ▼
┌─────────────────────────────────────────────────────────┐
│              Backend API (Django REST)                    │
│  MatchViewSet.find_matches()                             │
└──────────────────────┬──────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│            MatchingService.find_matches_for_user()        │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Scenario 1: Same Route (with layover)          │   │
│  │  Scenario 2: Same Layover (different dest)      │   │
│  │  Scenario 3: Departure is Layover/Destination   │   │
│  │  Scenario 4: Same Departure (different layovers) │   │
│  │  Scenario 5: Same Route (direct flight)         │   │
│  │  Scenario 6: Same Airport (flexible fallback)    │   │
│  └──────────────────────────────────────────────────┘   │
│                        │                                 │
│                        ▼                                 │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Deduplication (_deduplicate_matches)            │   │
│  └──────────────────────────────────────────────────┘   │
│                        │                                 │
│                        ▼                                 │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Filtering (_apply_user_filters)                 │   │
│  │  - Gender filter (exclude)                       │   │
│  │  - Common interests filter (exclude)              │   │
│  │  - Score adjustments                              │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│              Database (PostgreSQL)                        │
│  Match.objects.create_or_update()                        │
└─────────────────────────────────────────────────────────┘
```

---

## 🔄 Matching Service Flow

### **Entry Point: `find_matches_for_user(user, flight=None)`**

```python
# Step 1: Get user's active flight
if not flight:
    # Expanded time window: 24 hours past to 7 days future
    flight = Flight.objects.filter(
        user=user,
        is_visible=True,
        open_to_meeting=True,
        departure_datetime__gte=now - timedelta(hours=24),
        departure_datetime__lte=now + timedelta(days=7),
    ).order_by("departure_datetime").first()

# Step 2: Run all 6 scenarios in parallel
matches = []
matches.extend(_same_departure_layover_destination(flight))      # Scenario 1
matches.extend(_same_layover_different_destination(flight))      # Scenario 2
matches.extend(_departure_is_layover(flight))                    # Scenario 3
matches.extend(_same_departure_different_layovers(flight))      # Scenario 4
matches.extend(_same_route_direct(flight))                       # Scenario 5
matches.extend(_same_airport_flexible(flight))                   # Scenario 6

# Step 3: Remove duplicates
unique_matches = _deduplicate_matches(matches)

# Step 4: Apply filters and calculate scores
filtered_matches = _apply_user_filters(user, unique_matches)

# Step 5: Return sorted by score (highest first)
return filtered_matches
```

---

## 🎯 The 6 Matching Scenarios

### **Scenario 1: Same Departure, Same Layover, Same Destination**

**Purpose:** Match users on identical routes with overlapping layovers

**Query Logic:**
```python
Flight.objects.filter(
    ~Q(user=flight.user),                    # Not the same user
    is_visible=True,                         # Flight is visible
    open_to_meeting=True,                    # User open to meeting
    departure_airport=flight.departure_airport,
    layover_airport=flight.layover_airport,
    arrival_airport=flight.arrival_airport,
    layover_start__lte=flight.layover_end,  # Overlap check
    layover_end__gte=flight.layover_start,  # Overlap check
)
```

**Time Overlap Calculation:**
```python
overlap_start = max(flight1.layover_start, flight2.layover_start)
overlap_end = min(flight1.layover_end, flight2.layover_end)
duration_hours = (overlap_end - overlap_start).total_seconds() / 3600

# Minimum requirement: 1 hour overlap
if duration_hours >= 1.0:
    # Create match
```

**Example:**
```
User A: LAX → DXB (layover 2 PM - 6 PM) → BOM
User B: LAX → DXB (layover 3 PM - 7 PM) → BOM
Match: ✅ Overlap from 3 PM - 6 PM (3 hours)
```

---

### **Scenario 2: Same Layover, Different Destinations**

**Purpose:** Match users at the same layover airport going to different places

**Query Logic:**
```python
Flight.objects.filter(
    ~Q(user=flight.user),
    is_visible=True,
    open_to_meeting=True,
    has_layover=True,
    layover_airport=flight.layover_airport,
    layover_start__lte=flight.layover_end + timedelta(hours=2),  # Flexible window
    layover_end__gte=flight.layover_start - timedelta(hours=2),
).exclude(arrival_airport=flight.arrival_airport)  # Different destination
```

**Time Overlap:** Minimum 1 hour required

**Example:**
```
User A: LAX → DXB (layover 2 PM - 6 PM) → BOM
User B: NYC → DXB (layover 3 PM - 7 PM) → SYD
Match: ✅ Overlap from 3 PM - 6 PM (3 hours) at DXB
```

---

### **Scenario 3: Departure is Someone's Layover or Destination**

**Purpose:** Match when your departure airport is where someone else is waiting

#### **Case 3A: Departure is Their Layover**

**Query Logic:**
```python
Flight.objects.filter(
    ~Q(user=flight.user),
    is_visible=True,
    open_to_meeting=True,
    has_layover=True,
    layover_airport=flight.departure_airport,  # Their layover = your departure
    layover_start__lte=flight.departure_datetime + timedelta(hours=2),
    layover_end__gte=flight.departure_datetime - timedelta(hours=2),
)
```

**Time Overlap:** Minimum 30 minutes before your departure

**Example:**
```
User A: DXB → BOM (departing 4 PM)
User B: LAX → DXB (layover 2 PM - 5 PM) → BOM
Match: ✅ User B is in DXB when User A departs
Overlap: 2 PM - 4 PM (2 hours before User A's departure)
```

#### **Case 3B: Departure is Their Destination**

**Query Logic:**
```python
Flight.objects.filter(
    ~Q(user=flight.user),
    is_visible=True,
    open_to_meeting=True,
    arrival_airport=flight.departure_airport,  # They arrive where you depart
    arrival_datetime__lte=flight.departure_datetime,
    arrival_datetime__gte=flight.departure_datetime - timedelta(hours=4),
)
```

**Time Gap:** Between 30 minutes and 4 hours

**Example:**
```
User A: DXB → BOM (departing 4 PM)
User B: LAX → DXB (arriving 1 PM)
Match: ✅ User B arrives 3 hours before User A departs
Gap: 1 PM - 4 PM (3 hours - within acceptable range)
```

---

### **Scenario 4: Same Departure, Different Layovers**

**Purpose:** Match users leaving from the same airport on the same day

**Query Logic:**
```python
Flight.objects.filter(
    ~Q(user=flight.user),
    is_visible=True,
    open_to_meeting=True,
    departure_airport=flight.departure_airport,
).exclude(
    Q(has_layover=True, layover_airport=flight.layover_airport)
    if flight.has_layover else Q()
)
```

**Time Requirements:**
- Same departure date
- Departure times within 4 hours

**Example:**
```
User A: LAX → DXB → BOM (departing 10 AM)
User B: LAX → LHR → PAR (departing 11:30 AM)
Match: ✅ Same departure airport, same day, 1.5 hours apart
```

---

### **Scenario 5: Same Route (Direct Flight)**

**Purpose:** Match users on the same direct flight route

**Query Logic:**
```python
Flight.objects.filter(
    ~Q(user=flight.user),
    is_visible=True,
    open_to_meeting=True,
    has_layover=False,                        # Direct flights only
    departure_airport=flight.departure_airport,
    arrival_airport=flight.arrival_airport,
)
```

**Time Requirements:**
- Same departure date
- Departure times within 2 hours

**Example:**
```
User A: LAX → BOM (direct, 10 AM)
User B: LAX → BOM (direct, 11 AM)
Match: ✅ Same route, same day, 1 hour apart
```

---

### **Scenario 6: Same Airport (Flexible Fallback)**

**Purpose:** Catch-all scenario for any airport overlap

**Query Logic:**
```python
# Same departure airport
Flight.objects.filter(
    ~Q(user=flight.user),
    is_visible=True,
    open_to_meeting=True,
    departure_airport=flight.departure_airport,
    departure_datetime__gte=now - timedelta(days=1),
    departure_datetime__lte=now + timedelta(days=7),
)[:10]  # Limit to 10 matches

# Same arrival airport
Flight.objects.filter(
    ~Q(user=flight.user),
    is_visible=True,
    open_to_meeting=True,
    arrival_airport=flight.arrival_airport,
    arrival_datetime__gte=now - timedelta(days=1),
    arrival_datetime__lte=now + timedelta(days=7),
)[:10]
```

**Time Window:** Within 12 hours

**Note:** This is a fallback scenario that runs regardless of other matches

---

## 🎲 Match Scoring Algorithm

### **Base Score: 1.0**

All matches start with a base score of 1.0, then adjustments are applied:

### **Score Boosters** ⬆️

#### **1. Common Interests**
```python
# Formula: score *= (1 + len(common_interests) × 0.2)
common_interests = calculate_common_interests(user1, user2)
if common_interests:
    score *= 1 + len(common_interests) * 0.2
```

**Example:**
- Base: 1.0
- 3 common interests: 1.0 × (1 + 3 × 0.2) = **1.6**

**Case-Insensitive Matching:**
```python
# Normalizes to lowercase for comparison
user1_interests_normalized = {i.lower().strip() for i in user1_interests}
user2_interests_normalized = {i.lower().strip() for i in user2_interests}
common = user1_interests_normalized & user2_interests_normalized
```

#### **2. Guide Matching**
```python
# ×1.5 multiplier if guide match
if user1_pref.looking_for_guide and user2_pref.offering_guidance:
    score *= 1.5
if user1_pref.offering_guidance and user2_pref.looking_for_guide:
    score *= 1.5
```

**Example:**
- Base: 1.0
- Guide match: 1.0 × 1.5 = **1.5**

### **Score Reducers** ⬇️

#### **Travel Experience Mismatch**
```python
# ×0.8 multiplier for mismatch
if user_prefers_first_time and match_is_experienced:
    score *= 0.8
if user_prefers_experienced and match_is_first_time:
    score *= 0.8
```

**Example:**
- Base: 1.0
- Experience mismatch: 1.0 × 0.8 = **0.8**

### **Complete Score Calculation Example**

```python
# Starting score
score = 1.0

# Common interests boost
common_interests = ["Coffee", "Networking", "Business"]
score *= 1 + 3 * 0.2  # = 1.6

# Guide matching boost
if guide_match:
    score *= 1.5  # = 2.4

# Experience mismatch penalty
if experience_mismatch:
    score *= 0.8  # = 1.92

# Final score: 1.92
```

---

## 🔍 Filtering System

### **Exclusion Filters** (Remove from results)

#### **1. Gender Preference Filter**
```python
if match_filter.preferred_gender:
    if other_user.gender != match_filter.preferred_gender:
        continue  # Exclude this match
```

**Behavior:** Completely removes match from results if gender doesn't match

#### **2. Common Interests Requirement**
```python
if match_filter.require_common_interests:
    min_interests = match_filter.min_common_interests or 1
    if len(common_interests) < min_interests:
        continue  # Exclude this match
```

**Behavior:** Removes match if minimum common interests not met

### **Score Adjustment Filters** (Modify score but keep match)

#### **Travel Experience Preferences**
- Applied as multipliers (×0.8 for mismatch)
- Does not exclude matches

### **Filter Application Order**

```python
for match in matches:
    score = 1.0
    
    # 1. Check exclusion filters first
    if gender_filter_fails:
        continue  # Skip entirely
    
    if common_interests_filter_fails:
        continue  # Skip entirely
    
    # 2. Apply score adjustments
    if experience_mismatch:
        score *= 0.8
    
    if guide_match:
        score *= 1.5
    
    if common_interests:
        score *= 1 + len(common_interests) * 0.2
    
    match["match_score"] = score
    filtered.append(match)

# 3. Sort by score (highest first)
filtered.sort(key=lambda x: x["match_score"], reverse=True)
```

---

## 🔌 API Endpoints & Flow

### **1. Find Matches**

**Endpoint:** `GET /api/matching/matches/find_matches/?flight_id={optional}`

**Flow:**
```
Frontend Request
    ↓
MatchViewSet.find_matches()
    ↓
MatchingService.find_matches_for_user(user, flight)
    ↓
Run all 6 scenarios
    ↓
Deduplicate matches
    ↓
Apply filters & calculate scores
    ↓
Create/Update Match records in database
    ↓
Return serialized matches
```

**Response Format:**
```json
{
  "matches": [
    {
      "id": 123,
      "user1": 1,
      "user2": 2,
      "user1_data": {...},
      "user2_data": {...},
      "flight1": 10,
      "flight2": 20,
      "flight1_data": {...},
      "flight2_data": {...},
      "match_type": "same_layover",
      "matching_airport": "DXB",
      "matching_city": "Dubai",
      "overlap_start": "2024-01-15T15:00:00Z",
      "overlap_end": "2024-01-15T18:00:00Z",
      "overlap_duration_hours": 3.0,
      "match_score": 1.6,
      "common_interests": ["Coffee", "Networking"],
      "status": "pending",
      "user1_liked": false,
      "user2_liked": false,
      "created_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

### **2. Like a Match (Send Connection Request)**

**Endpoint:** `POST /api/matching/matches/{id}/like/`

**Flow:**
```python
match = Match.objects.get(id=id)

if match.user1 == current_user:
    match.user1_liked = True
    if match.user2_liked:
        match.status = "matched"  # Both liked!
    else:
        match.status = "connection_requested"  # Waiting for other user
elif match.user2 == current_user:
    match.user2_liked = True
    if match.user1_liked:
        match.status = "matched"
    else:
        match.status = "connection_requested"

match.save()
```

**Status Transitions:**
```
pending → connection_requested → matched
         (when one user likes)
         (when both users like)
```

### **3. Get Connection Requests**

**Endpoint:** `GET /api/matching/matches/connection_requests/`

**Query Logic:**
```python
Match.objects.filter(
    Q(user1=user, user2_liked=True, user1_liked=False) |
    Q(user2=user, user1_liked=True, user2_liked=False),
    status="connection_requested",
)
```

### **4. Accept Connection Request**

**Endpoint:** `POST /api/matching/matches/{id}/accept_connection/`

**Flow:**
```python
if match.status == "connection_requested":
    if current_user == match.user1:
        match.user1_liked = True
    else:
        match.user2_liked = True
    
    # Both users have liked now
    match.status = "matched"
    match.matched_at = timezone.now()
    match.save()
```

---

## 🗄️ Database Models

### **Match Model**

```python
class Match(models.Model):
    # Users
    user1 = ForeignKey(CustomUser)
    user2 = ForeignKey(CustomUser)
    
    # Flights
    flight1 = ForeignKey(Flight, null=True)
    flight2 = ForeignKey(Flight, null=True)
    
    # Match Details
    match_type = CharField(choices=MATCH_TYPE_CHOICES)
    matching_airport = CharField(max_length=10)
    matching_city = CharField(max_length=100)
    overlap_start = DateTimeField()
    overlap_end = DateTimeField()
    overlap_duration_hours = FloatField()
    
    # Scoring
    match_score = FloatField(default=0.0)
    common_interests = JSONField(default=list)
    
    # Status
    status = CharField(choices=STATUS_CHOICES, default='pending')
    user1_liked = BooleanField(default=False)
    user2_liked = BooleanField(default=False)
    user1_viewed = BooleanField(default=False)
    user2_viewed = BooleanField(default=False)
    
    # Timestamps
    created_at = DateTimeField(auto_now_add=True)
    updated_at = DateTimeField(auto_now=True)
    matched_at = DateTimeField(null=True, blank=True)
    
    class Meta:
        unique_together = [['user1', 'user2', 'flight1', 'flight2']]
        ordering = ['-match_score', '-created_at']
```

**Unique Constraint:** Allows multiple matches between same users if flights are different

### **MatchFilter Model**

```python
class MatchFilter(models.Model):
    user = OneToOneField(CustomUser)
    
    # Exclusion Filters
    preferred_gender = CharField(null=True, blank=True)
    require_common_interests = BooleanField(default=False)
    min_common_interests = IntegerField(default=1)
    
    # Score Adjustment Preferences
    prefer_first_time_travelers = BooleanField(default=False)
    prefer_experienced_travelers = BooleanField(default=False)
    prefer_business_travelers = BooleanField(default=False)
    
    # Age Range
    min_age = IntegerField(null=True, blank=True)
    max_age = IntegerField(null=True, blank=True)
```

---

## ⚡ Performance Considerations

### **Database Indexes**

```python
# Flight model indexes
indexes = [
    Index(fields=['departure_airport', 'departure_datetime']),
    Index(fields=['arrival_airport', 'arrival_datetime']),
    Index(fields=['layover_airport', 'layover_start', 'layover_end']),
    Index(fields=['user', 'is_visible']),
]

# Match model indexes
indexes = [
    Index(fields=['user1', 'status']),
    Index(fields=['user2', 'status']),
    Index(fields=['match_type', 'matching_airport']),
]
```

### **Query Optimization**

1. **Select Related:** Uses `select_related()` for foreign keys
2. **Limit Results:** Scenario 6 limits to 10 matches per airport
3. **Time Windows:** Uses date/time filters to limit query scope
4. **Deduplication:** Removes duplicates before filtering

### **Caching Opportunities**

- Match results could be cached for a short period (5-10 minutes)
- Common interests calculation could be cached per user pair
- Match filters could be cached per user

---

## 💻 Code Examples

### **Example: Finding Matches**

```python
from matching.matching_service import MatchingService
from authentication.models import CustomUser

user = CustomUser.objects.get(email="user@example.com")
matches = MatchingService.find_matches_for_user(user)

for match_data in matches:
    print(f"Match with {match_data['user'].email}")
    print(f"  Type: {match_data['match_type']}")
    print(f"  Airport: {match_data['matching_airport']}")
    print(f"  Score: {match_data['match_score']}")
    print(f"  Common Interests: {match_data['common_interests']}")
```

### **Example: Creating a Match**

```python
from matching.matching_service import MatchingService

match = MatchingService.create_or_update_match(
    user1=user1,
    user2=user2,
    flight1=flight1,
    flight2=flight2,
    match_data={
        "match_type": "same_layover",
        "matching_airport": "DXB",
        "matching_city": "Dubai",
        "overlap": {
            "start": datetime(2024, 1, 15, 15, 0),
            "end": datetime(2024, 1, 15, 18, 0),
            "duration_hours": 3.0,
        },
        "match_score": 1.6,
        "common_interests": ["Coffee", "Networking"],
    }
)
```

### **Example: Calculating Common Interests**

```python
from matching.matching_service import MatchingService

user1 = CustomUser.objects.get(id=1)
user2 = CustomUser.objects.get(id=2)

common = MatchingService.calculate_common_interests(user1, user2)
# Returns: ["Coffee", "Networking", "Business"]
# Case-insensitive matching preserves original casing
```

---

## 📊 Summary

### **Key Features**

1. ✅ **6 Matching Scenarios** - Comprehensive coverage of travel patterns
2. ✅ **Smart Scoring** - Based on interests, preferences, and compatibility
3. ✅ **Flexible Filtering** - Exclusion filters + score adjustments
4. ✅ **Case-Insensitive Interests** - "coffee" matches "Coffee"
5. ✅ **Deduplication** - Prevents duplicate matches
6. ✅ **Performance Optimized** - Indexed queries, limited result sets

### **Match Lifecycle**

```
Flight Added → find_matches() → Scenarios Run → Deduplication → 
Filtering → Scoring → Match Created → User Likes → Connection Request → 
Both Like → Matched ✅
```

---

**Last Updated:** Technical deep dive completed  
**Status:** Production-ready matching algorithm

