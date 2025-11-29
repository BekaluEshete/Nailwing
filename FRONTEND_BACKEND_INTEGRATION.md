# 🔗 Frontend-Backend Integration Guide

## ✅ Integration Status

All frontend services are now integrated with the backend APIs with comprehensive debug logging.

## 📡 API Endpoints Integrated

### 1. **Authentication** ✅
- `POST /api/auth/register/` - User registration
- `POST /api/auth/login/` - User login
- `POST /api/auth/logout/` - User logout
- `GET /api/auth/profile/` - Get user profile
- `PATCH /api/auth/profile/` - Update user profile
- `POST /api/auth/change_password/` - Change password

### 2. **Flights** ✅
- `GET /api/flights/flights/` - Get all user flights
- `POST /api/flights/flights/` - Create new flight
- `GET /api/flights/flights/upcoming/` - Get upcoming flights
- `GET /api/flights/flights/current/` - Get current flight
- `PATCH /api/flights/flights/{id}/update_status/` - Update flight status
- `GET /api/flights/interests/` - Get user interests
- `POST /api/flights/interests/` - Add interest
- `DELETE /api/flights/interests/{id}/` - Delete interest
- `GET /api/flights/preferences/my_preferences/` - Get travel preferences
- `PUT /api/flights/preferences/my_preferences/` - Update travel preferences

### 3. **Matching** ✅
- `GET /api/matching/matches/find_matches/` - Find new matches
- `GET /api/matching/matches/` - Get user's matches
- `POST /api/matching/matches/{id}/like/` - Like a match
- `POST /api/matching/matches/{id}/reject/` - Reject a match
- `POST /api/matching/matches/{id}/view/` - Mark match as viewed
- `GET /api/matching/filters/my_filters/` - Get match filters
- `PUT /api/matching/filters/my_filters/` - Update match filters

### 4. **Recommendations** ✅
- `GET /api/recommendations/places/` - Get airport places
- `GET /api/recommendations/recommendations/get_recommendations/` - Get personalized recommendations

### 5. **Chat** ✅
- WebSocket: `ws://{baseUrl}/ws/chat/{room_name}/?token={jwt_token}`
- `GET /chat/api/rooms/` - Get chat rooms
- `POST /chat/api/rooms/` - Create chat room

## 🐛 Debug Logging

All services now include comprehensive debug logging with emojis for easy identification:

- 🛫 **FlightService** - Flight operations
- 🔍 **MatchService** - Matching operations
- 📍 **RecommendationService** - Recommendations
- 👤 **UserService** - User profile operations
- ✈️ **FlightViewModel** - Flight view model operations

### Debug Output Format:
```
🛫 [FlightService] Getting user flights...
📡 [FlightService] Calling: https://nilewing-backend.onrender.com/api/flights/flights/
📥 [FlightService] Response status: 200
📥 [FlightService] Response body: {...}
✅ [FlightService] Parsed 3 flights
```

## 🔧 Data Format Conversion

### Flight Creation
The frontend converts `FlightPostData` → `Flight` → Backend format:

**Frontend Format:**
```dart
Flight(
  flightNumber: "ET302",
  departure: FlightLeg(
    airport: "ADD",
    city: "Addis Ababa",
    time: "23:35",
    date: "Today",
    terminal: "T2",
  ),
  ...
)
```

**Backend Format:**
```json
{
  "flight_number": "ET302",
  "departure_airport": "ADD",
  "departure_city": "Addis Ababa",
  "departure_datetime": "2024-12-22T23:35:00Z",
  "departure_terminal": "T2",
  ...
}
```

### Match Data
Backend match data is converted to frontend `Match` model with proper user and flight info mapping.

## ⚠️ Important Notes

1. **Date/Time Parsing**: The frontend parses dates like "Today", "Tomorrow", or "mm/dd/yyyy" format and converts to ISO 8601 for backend.

2. **Layover Handling**: If `transitAirport` is provided, the flight is marked as `has_layover: true` and layover times are calculated.

3. **Status Mapping**:
   - Frontend `FlightStatus.upcoming` → Backend `"scheduled"`
   - Frontend `FlightStatus.delayed` → Backend `"delayed"`
   - Frontend `FlightStatus.completed` → Backend `"landed"`

4. **Empty Fields**: Empty strings are sent for optional fields (nationality, language) to allow clearing them on the backend.

5. **Token Management**: All API calls include JWT token in `Authorization: Bearer {token}` header.

## 🧪 Testing

To test the integration:

1. **Check Debug Logs**: All API calls print debug information to console
2. **Monitor Network**: Use Flutter DevTools to see network requests
3. **Verify Responses**: Check response status codes and data format

## 📝 Next Steps

1. Test flight creation end-to-end
2. Test matching flow
3. Test profile updates
4. Test recommendations
5. Verify WebSocket chat connection

---

**All services are integrated and ready for testing!** 🚀

