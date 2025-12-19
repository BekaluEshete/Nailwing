# Test Backend Endpoints

Your backend is now live! Test these endpoints:

## ✅ Health Check Endpoints

### 1. Authentication API Info
```
https://nilewing-backend.onrender.com/api/auth/
```
**Expected:** JSON response with available endpoints

### 2. Test Registration Endpoint
```
POST https://nilewing-backend.onrender.com/api/auth/register/
```

### 3. Test Login Endpoint
```
POST https://nilewing-backend.onrender.com/api/auth/login/
```

---

## 🔍 How to Test

### Option 1: Browser (for GET requests)
Open: `https://nilewing-backend.onrender.com/api/auth/`

### Option 2: Postman/Insomnia
Test POST requests with JSON body

### Option 3: cURL
```bash
# Test GET endpoint
curl https://nilewing-backend.onrender.com/api/auth/

# Test POST registration
curl -X POST https://nilewing-backend.onrender.com/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "Test User",
    "email": "test@example.com",
    "password": "test123",
    "password2": "test123",
    "age": "25",
    "gender": "Male",
    "nationality": "US",
    "language": "English"
  }'
```

---

## 📱 Update Your Flutter App

Your Flutter app should now be able to connect! Make sure:

1. **Backend URL is correct** in `app_constants.dart`:
   ```dart
   static const String baseUrl = 'https://nilewing-backend.onrender.com';
   ```

2. **Rebuild your Flutter app**:
   ```bash
   cd Frontend/nilewing
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

3. **Test login/registration** from your app

---

## ⚠️ Still Need to Fix (Important!)

Even though the server is running, you should still fix these environment variables:

1. **DEBUG** = `False` (currently `True`)
2. **REDIS_URL** = Get from Render Redis service (currently `redis://redis:6379/1`)
3. **SECRET_KEY** = Generate a secure key (currently `django-insecure-key`)

See `RENDER_ENV_VARIABLES_FIX.md` for detailed instructions.

---

## 🎉 Success Indicators

- ✅ Server logs show "Listening on TCP address"
- ✅ Service shows "Live" status on Render
- ✅ Can access `/api/auth/` endpoint
- ✅ No Redis connection errors in logs (or graceful handling)

If you see Redis warnings but the server is still running, that's okay for now - the graceful error handling is working!

