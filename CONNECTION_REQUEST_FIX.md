# Connection Request UI Fix

## Problem

When a user sent a connection request to a matched user, the "Accept" button also appeared to them (the sender) to accept their own connection request. This was incorrect behavior - users should not be able to accept their own requests.

## Solution

Added logic to distinguish between:
1. **Connection requests sent by the current user** → Show "Request Sent" status
2. **Connection requests received by the current user** → Show "Accept/Reject" buttons

## Changes Made

### 1. Updated Match Model (`match_model.dart`)

Added fields to track who sent the connection request:
- `currentUserIsUser1`: Boolean indicating if current user is user1 (null if unknown)
- `user1Liked`: Boolean indicating if user1 sent the request
- `user2Liked`: Boolean indicating if user2 sent the request

Added helper method:
- `isRequestSentByCurrentUser`: Returns `true` if the current user sent the connection request

### 2. Updated Match Service (`match_service.dart`)

- Parses `user1_liked` and `user2_liked` from API response
- Determines if current user is user1 or user2
- Sets these fields when creating Match objects

### 3. Updated Match Detail Screen (`match_detail_screen.dart`)

Modified the UI logic to check `isRequestSentByCurrentUser`:
- **If request was sent by current user** → Show "Request Sent" status (orange badge)
- **If request was received by current user** → Show "Accept" and "Reject" buttons

**Before:**
```dart
// Show Accept/Reject buttons if connection request received
else if (currentMatch.status.toLowerCase() == 'connection_requested')
  // Show Accept/Reject buttons
```

**After:**
```dart
// Show Accept/Reject buttons if connection request received (NOT sent by current user)
else if ((currentMatch.status.toLowerCase() == 'connection_requested') &&
         !currentMatch.isRequestSentByCurrentUser)
  // Show Accept/Reject buttons

// Show "Request Sent" status if connection request was sent by current user
else if (currentMatch.status.toLowerCase() == 'connection_requested' &&
         currentMatch.isRequestSentByCurrentUser)
  // Show "Request Sent" badge
```

## How It Works

### Backend Logic
The backend tracks:
- `user1_liked`: True if user1 sent the connection request
- `user2_liked`: True if user2 sent the connection request
- `status`: "connection_requested" when one user sends a request

### Frontend Logic
When parsing a match:
1. Determines if current user is `user1` or `user2`
2. Checks `user1_liked` and `user2_liked` flags
3. Calculates `isRequestSentByCurrentUser`:
   - If current user is user1: `user1_liked == true && user2_liked == false`
   - If current user is user2: `user2_liked == true && user1_liked == false`

### UI Display Logic
```
Status: "connection_requested"

IF isRequestSentByCurrentUser == true:
  → Show "Request Sent" badge (cannot accept own request)

IF isRequestSentByCurrentUser == false:
  → Show "Accept" and "Reject" buttons (can accept/reject received request)
```

## Testing Checklist

- [x] User sends connection request → Shows "Request Sent" status
- [x] Other user receives connection request → Shows "Accept/Reject" buttons
- [x] Other user accepts → Status changes to "matched", shows "Chat" button
- [x] Other user rejects → Status changes to "rejected"
- [x] Connection requests screen only shows received requests (already working)

## Files Modified

1. `Frontend/nilewing/lib/features/match/model/match_model.dart`
   - Added `currentUserIsUser1`, `user1Liked`, `user2Liked` fields
   - Added `isRequestSentByCurrentUser` getter
   - Updated `copyWith` method

2. `Frontend/nilewing/lib/features/match/service/match_service.dart`
   - Parse `user1_liked` and `user2_liked` from JSON
   - Determine `currentUserIsUser1` during parsing
   - Pass these fields to Match constructor

3. `Frontend/nilewing/lib/features/match/view/match_detail_screen.dart`
   - Updated condition to check `isRequestSentByCurrentUser`
   - Show Accept/Reject only for received requests
   - Show "Request Sent" for sent requests

## Related Features

- **Connection Requests Screen**: Already correctly filters to show only received requests (uses backend endpoint `/connection_requests/`)
- **Match Card**: Only shows "Connect" or "Chat" buttons, doesn't show Accept/Reject (no changes needed)

