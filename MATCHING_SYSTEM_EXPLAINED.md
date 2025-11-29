# 🎯 Nilewing Matching System - Complete Guide

## 📋 Overview

The Nilewing matching system connects travelers based on their flight paths, layovers, and personal preferences. It uses a smart algorithm that analyzes flight data to find potential travel companions.

---

## 🔄 How It Works - Step by Step

### 1. **User Adds a Flight**
- User creates a flight with departure, arrival, and optional layover information
- Flight must be `is_visible=True` and `open_to_meeting=True` to be included in matching

### 2. **Finding Matches**
When a user requests matches (via `/api/matching/matches/find_matches/`):

1. **System identifies the user's active flight** (upcoming or current, within 2 hours)
2. **Runs 5 matching scenarios** in parallel
3. **Removes duplicates** (same user matched multiple times)
4. **Applies user filters** (gender, interests, preferences)
5. **Calculates match scores** (based on compatibility)
6. **Sorts by score** (highest first)
7. **Returns matches** to the frontend

### 3. **User Interaction**
- User can **view** match details
- User can **like** a match
- User can **reject** a match
- When **both users like** → Status changes to `matched` ✅

---

## 🎯 The 5 Matching Scenarios

### **Scenario 1: Same Departure, Same Layover, Same Destination**
**Example:** Both users flying LAX → DXB → BOM

```
User A: LAX → DXB (layover 3h) → BOM
User B: LAX → DXB (layover 4h) → BOM
Match: ✅ Same route, overlapping layover in DXB
```

**Requirements:**
- Same departure airport
- Same layover airport
- Same destination airport
- Layover times overlap by **at least 1 hour**

**Match Type:** `same_route`
**Meeting Point:** Layover airport (DXB)

---

### **Scenario 2: Same Layover, Different Destinations**
**Example:** Both users have a layover in Dubai, but going to different places

```
User A: LAX → DXB (layover 3h) → BOM
User B: NYC → DXB (layover 4h) → SYD
Match: ✅ Same layover airport, overlapping time
```

**Requirements:**
- Same layover airport
- Different destination airports
- Layover times overlap by **at least 1 hour**

**Match Type:** `same_layover`
**Meeting Point:** Layover airport (DXB)

---

### **Scenario 3: Departure is Someone's Layover or Destination**
**Example:** Your departure airport is where someone else is waiting

**Case 3A: Your departure is their layover**
```
User A: DXB → BOM (departing at 2 PM)
User B: LAX → DXB (layover until 3 PM) → BOM
Match: ✅ User B is in DXB when User A departs
```

**Case 3B: Your departure is their destination**
```
User A: DXB → BOM (departing at 2 PM)
User B: LAX → DXB (arriving at 12 PM)
Match: ✅ User B arrives before User A departs (30 min - 4 hours gap)
```

**Requirements:**
- Your departure airport = Their layover/destination airport
- Time overlap of **at least 30 minutes** (Case 3A) or **30 min - 4 hours** (Case 3B)

**Match Type:** `layover_departure`
**Meeting Point:** Your departure airport

---

### **Scenario 4: Same Departure, Different Layovers**
**Example:** Both leaving from the same airport on the same day

```
User A: LAX → DXB → BOM (departing 10 AM)
User B: LAX → LHR → PAR (departing 11 AM)
Match: ✅ Same departure, same day, within 4 hours
```

**Requirements:**
- Same departure airport
- Same departure date
- Departure times within **4 hours** of each other

**Match Type:** `same_departure`
**Meeting Point:** Departure airport

---

### **Scenario 5: Same Route (Direct Flight)**
**Example:** Both users on the same direct flight route

```
User A: LAX → BOM (direct, 10 AM)
User B: LAX → BOM (direct, 11 AM)
Match: ✅ Same route, same day, within 2 hours
```

**Requirements:**
- Same departure airport
- Same destination airport
- No layovers (direct flights)
- Same departure date
- Departure times within **2 hours**

**Match Type:** `same_route`
**Meeting Point:** Departure airport

---

## 🎲 Match Scoring System

Each match gets a **match score** (default: 1.0) that can be boosted or reduced:

### **Score Boosters** ⬆️
- **Common Interests:** +0.2 per shared interest
  - Example: 3 common interests = 1.0 × (1 + 3 × 0.2) = **1.6**
- **Guide Matching:** ×1.5 multiplier
  - User A looking for guide + User B offering guidance = **1.5× boost**
  - User A offering guidance + User B looking for guide = **1.5× boost**

### **Score Reducers** ⬇️
- **Travel Experience Mismatch:** ×0.8 multiplier
  - User prefers first-time travelers but match is experienced = **0.8×**
  - User prefers experienced travelers but match is first-time = **0.8×**

### **Filters (Exclude from Results)** ❌
- **Gender Preference:** If user has `preferred_gender` set and match doesn't match → **Excluded**

**Final Score Example:**
```
Base: 1.0
+ 2 common interests: ×1.4 (1 + 2×0.2)
+ Guide match: ×1.5
= Final Score: 2.1
```

**Matches are sorted by score (highest first)**

---

## 🔍 User Filters

Users can set preferences in `MatchFilter`:

### **Gender Filter**
- `preferred_gender`: Only match with specific gender (or null for any)

### **Travel Experience**
- `prefer_first_time_travelers`: Prefer matching with first-time travelers
- `prefer_experienced_travelers`: Prefer matching with experienced travelers

### **Interests**
- `require_common_interests`: Only show matches with shared interests
- `min_common_interests`: Minimum number of shared interests (default: 1)

### **Business Networking**
- `prefer_business_travelers`: Prefer business travelers

### **Age Range** (if implemented)
- `min_age` / `max_age`: Age range preferences

---

## 📊 Match Lifecycle

```
┌─────────┐
│ Pending │  ← New match created
└────┬────┘
     │
     ├─→ User views match
     │   └─→ Status: "viewed"
     │
     ├─→ User likes match
     │   └─→ Status: "liked"
     │       └─→ If other user also liked → "matched" ✅
     │
     └─→ User rejects match
         └─→ Status: "rejected" (excluded from future results)
```

### **Match Statuses:**
- `pending`: New match, not yet viewed
- `viewed`: User has seen the match
- `liked`: User liked the match (waiting for mutual like)
- `matched`: Both users liked each other ✅
- `rejected`: User rejected the match
- `expired`: Match expired (flight passed)

---

## 🔌 API Endpoints

### **Find Matches**
```
GET /api/matching/matches/find_matches/?flight_id=123
```
- Finds new matches for the current user
- Optional `flight_id` parameter
- Returns: List of `Match` objects

### **Get User's Matches**
```
GET /api/matching/matches/
```
- Returns all matches for the current user (excluding rejected)
- Sorted by match score (highest first)

### **Like a Match**
```
POST /api/matching/matches/{id}/like/
```
- User likes a match
- If both users like → status becomes `matched`

### **Reject a Match**
```
POST /api/matching/matches/{id}/reject/
```
- User rejects a match
- Status becomes `rejected` (excluded from future results)

### **View a Match**
```
POST /api/matching/matches/{id}/view/
```
- Marks match as viewed
- Updates `user1_viewed` or `user2_viewed`

### **Get/Update Match Filters**
```
GET /api/matching/filters/my_filters/
PUT /api/matching/filters/my_filters/
```
- Get or update user's matching preferences

---

## 💻 Frontend Flow

### **1. User Opens Match Screen**
```dart
MatchScreen → initState() → loadMatches()
```

### **2. ViewModel Calls Service**
```dart
MatchViewModel.loadMatches()
  → MatchService.findMatches()
    → GET /api/matching/matches/find_matches/
```

### **3. Display Matches**
- Matches displayed in `MatchListScreen`
- Each match shown as a `MatchCard`
- User can tap to see details

### **4. User Actions**
- **Tap Match** → `MatchDetailScreen` (shows full details)
- **Like** → `MatchService.likeMatch(id)` → `POST /api/matching/matches/{id}/like/`
- **Reject** → `MatchService.rejectMatch(id)` → `POST /api/matching/matches/{id}/reject/`

---

## 🗄️ Database Models

### **Match Model**
```python
- user1, user2: The two matched users
- flight1, flight2: Their respective flights
- match_type: Type of match (same_route, same_layover, etc.)
- matching_airport: Where they can meet
- matching_city: City name
- overlap_start, overlap_end: Time window for meeting
- overlap_duration_hours: How long they can meet
- match_score: Compatibility score
- common_interests: List of shared interests
- status: pending/viewed/liked/matched/rejected
- user1_liked, user2_liked: Boolean flags
- user1_viewed, user2_viewed: Boolean flags
```

### **MatchFilter Model**
```python
- user: One-to-one with CustomUser
- preferred_gender: Gender preference
- prefer_first_time_travelers: Boolean
- prefer_experienced_travelers: Boolean
- require_common_interests: Boolean
- min_common_interests: Integer
- prefer_business_travelers: Boolean
```

---

## 🎯 Real-World Examples

### **Example 1: Coffee Meetup During Layover**
```
Daniel: NYC → DXB (layover 4h) → BOM
Mariam: LAX → DXB (layover 5h) → BOM

Match: ✅ Same route, overlapping layover
Meeting: Dubai Airport (DXB) - 4 hours overlap
Common Interests: ["Coffee", "Networking"]
Score: 1.4 (1.0 base + 2 interests × 0.2)
```

### **Example 2: First-Time Traveler Meets Guide**
```
Liya: First international flight, looking for guide
Omar: Experienced traveler, offering guidance

Match: ✅ Guide matching (1.5× boost)
Meeting: At departure airport
Score: 1.5 (1.0 base × 1.5 guide boost)
```

### **Example 3: Business Networking**
```
Sara: LAX → DXB → BOM (business trip)
Ahmed: LAX → DXB → BOM (business trip)

Match: ✅ Same route, same layover
Common Interests: ["Business", "Networking"]
Both prefer business travelers
Score: 1.4 (1.0 base + 2 interests × 0.2)
```

---

## 🔧 Technical Details

### **Time Overlap Calculation**
```python
def _calculate_overlap(start1, end1, start2, end2):
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
```

### **Deduplication**
- Removes duplicate matches (same user matched multiple times)
- Keeps only the highest-scoring match per user

### **Filtering**
- Applies user's `MatchFilter` preferences
- Excludes matches that don't meet criteria
- Sorts by `match_score` (descending)

---

## ✅ Summary

The matching system:
1. ✅ Analyzes flight paths using 5 scenarios
2. ✅ Calculates compatibility scores
3. ✅ Applies user preferences/filters
4. ✅ Sorts by relevance
5. ✅ Tracks user interactions (view, like, reject)
6. ✅ Creates matches when both users like each other

**The goal:** Connect travelers who can actually meet during their journey! ✈️🤝



