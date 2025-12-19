# Backend URL Troubleshooting Guide

## Issue: "Failed host lookup" Error

If you're seeing a "Failed host lookup" error when trying to login/register, it means the app cannot connect to the backend server at `nilewing-backend.onrender.com`.

### Important: CORS vs DNS Errors

**"Failed host lookup" is NOT a CORS issue** - it's a DNS/connectivity problem that occurs BEFORE any HTTP request is made:

- **DNS Error**: App can't find the IP address for the domain name → "Failed host lookup"
- **CORS Error**: App connects successfully but browser blocks the response → Different error message (usually visible in browser console, not in mobile apps)

**For Flutter mobile apps (Android/iOS)**, CORS is less critical because they're not subject to browser same-origin policy. However, CORS configuration has been added to the backend for best practices and web compatibility.

## Quick Solutions

### 1. Check if Backend is Running on Render

1. Go to your [Render Dashboard](https://dashboard.render.com/)
2. Check if your service `nilewing-backend` is running (should show "Live" status)
3. If it's paused, click "Manual Deploy" or "Deploy Latest Commit" to wake it up
4. On Render free tier, services sleep after 15 minutes of inactivity - the first request may take 30-60 seconds to wake up

### 2. Verify Backend URL is Correct

Check if the URL in `Frontend/nilewing/lib/core/utils/app_constants.dart` matches your actual Render service URL:

```dart
static const String baseUrl = 'https://nilewing-backend.onrender.com';
```

**Note**: Make sure there's no trailing slash and it matches exactly what's shown in your Render dashboard.

### 3. Test Backend Connection

You can test if the backend is accessible by opening this URL in a web browser:

```
https://nilewing-backend.onrender.com/api/auth/
```

- If you see a JSON response or API documentation → Backend is working
- If you see "This site can't be reached" → Backend is not accessible
- If you see a timeout → Backend is sleeping (on free tier, wait 30-60 seconds)

### 4. Use Local Backend (For Testing)

If you want to test with a local backend running on your computer:

1. **Update `app_constants.dart`**:

   ```dart
   // For Android Emulator
   static const String baseUrl = 'http://10.0.2.2:8000';

   // For iOS Simulator (Mac only)
   // static const String baseUrl = 'http://localhost:8000';

   // For Physical Device (replace with your computer's IP address)
   // Find your IP: On Windows, run `ipconfig` in Command Prompt
   // Look for "IPv4 Address" (e.g., 192.168.1.100)
   // static const String baseUrl = 'http://192.168.1.100:8000';
   ```

2. **Make sure your local Django backend is running**:

   ```bash
   cd Backend
   python manage.py runserver
   ```

3. **Rebuild the app**:
   ```bash
   cd Frontend/nilewing
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

### 5. Network/Device Issues

- **Check Internet Connection**: Make sure your device/emulator has internet access
- **Check Firewall**: If testing locally, ensure your firewall allows connections on port 8000
- **Check VPN**: If using a VPN, try disabling it temporarily
- **Try Different Network**: Switch from WiFi to mobile data or vice versa

## Improved Error Messages

The app now shows more helpful error messages:

- "Cannot reach the server" → Check internet connection and backend status
- "Connection timeout" → Server may be slow (common on Render free tier)
- Specific DNS errors → Backend URL might be incorrect

## Next Steps

1. **If backend is on Render**: Verify it's running and not paused
2. **If using local backend**: Make sure it's running and use the correct IP address
3. **Rebuild the app** after changing the backend URL

## Still Having Issues?

1. Check Render service logs for errors
2. Verify database migrations have been run on Render
3. Check if the backend service has sufficient resources
4. **CORS is already configured** - It's set to allow all origins (can be restricted for production)

### CORS Configuration Status

✅ CORS middleware is properly configured in `settings.py`
✅ CORS_ALLOW_ALL_ORIGINS = True (allows all origins)
✅ Proper headers and methods are allowed

**Note**: CORS doesn't affect the "Failed host lookup" error. That's a DNS/connectivity issue.
