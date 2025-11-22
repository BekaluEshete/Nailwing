# ✅ Post-Deployment Checklist

Your backend is now live at: **https://nilewing-backend.onrender.com**

## 🎯 Immediate Actions

### 1. ✅ Deployment Status

- ✅ Build successful
- ✅ Service is live
- ⚠️ "Not Found: /" is **NORMAL** - your API is at `/api/` and `/chat/`

### 2. Run Database Migrations

**In Render Dashboard:**

1. Go to your service → **Shell** tab
2. Run:
   ```bash
   python manage.py migrate
   ```
3. Create superuser (optional):
   ```bash
   python manage.py createsuperuser
   ```

### 3. Test API Endpoints

Test these URLs in your browser or Postman:

✅ **Authentication API Info:**

```
https://nilewing-backend.onrender.com/api/auth/
```

✅ **Admin Panel:**

```
https://nilewing-backend.onrender.com/admin/
```

✅ **Chat API:**

```
https://nilewing-backend.onrender.com/chat/api/rooms/
```

### 4. Update Frontend Configuration

Update `Frontend/nilewing/lib/core/utils/app_constants.dart`:

```dart
class AppConstants {
  // Production Backend URL
  static const String baseUrl = 'https://nilewing-backend.onrender.com';

  // API Endpoints
  static const String apiBaseUrl = '$baseUrl/api';
  static const String authBaseUrl = '$apiBaseUrl/auth';

  // Auth Endpoints
  static const String registerEndpoint = '$authBaseUrl/register/';
  static const String loginEndpoint = '$authBaseUrl/login/';
  static const String logoutEndpoint = '$authBaseUrl/logout/';
  static const String profileEndpoint = '$authBaseUrl/profile/';
  static const String tokenRefreshEndpoint = '$apiBaseUrl/token/refresh/';

  // ... rest of the code
}
```

### 5. Test Authentication Flow

1. **Test Registration:**

   - Open your Flutter app
   - Try to register a new user
   - Check if it succeeds

2. **Test Login:**

   - Try logging in with registered credentials
   - Verify tokens are saved

3. **Check Logs:**
   - Monitor Render logs for any errors
   - Look for successful API calls

## 🔍 Troubleshooting

### Issue: "Not Found: /"

✅ **This is NORMAL!** Your API doesn't have a root endpoint. Test:

- `/api/auth/` - Should show available endpoints
- `/admin/` - Should show Django admin login

### Issue: Database Connection Error

- Check `DATABASE_URL` environment variable
- Ensure PostgreSQL service is running
- Verify you're using **Internal Database URL**

### Issue: Redis Connection Error

- Check `REDIS_URL` environment variable
- Ensure Redis service is running
- Verify you're using **Internal Redis URL**

### Issue: CORS Errors in Frontend

Add to `Backend/core/settings.py`:

```python
CORS_ALLOWED_ORIGINS = [
    "https://your-frontend-domain.com",
    "http://localhost:3000",  # For local dev
]

CORS_ALLOW_CREDENTIALS = True
```

### Issue: Static Files Not Found

- Verify `collectstatic` ran in build command
- Check WhiteNoise is installed
- Verify STATIC_ROOT is set

## 📝 Environment Variables Check

Verify these are set in Render Dashboard → Environment:

- ✅ `SECRET_KEY` - Strong random key
- ✅ `DEBUG=False` - Production mode
- ✅ `ALLOWED_HOSTS=nilewing-backend.onrender.com,localhost`
- ✅ `DATABASE_URL` - Internal PostgreSQL URL
- ✅ `REDIS_URL` - Internal Redis URL
- ✅ `PYTHON_VERSION=3.13`

## 🧪 Quick API Tests

### Test Registration (using curl or Postman):

```bash
curl -X POST https://nilewing-backend.onrender.com/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "Test User",
    "email": "test@example.com",
    "password": "testpass123",
    "password2": "testpass123",
    "age": "25",
    "gender": "male",
    "nationality": "Ethiopian",
    "language": "English"
  }'
```

### Test Login:

```bash
curl -X POST https://nilewing-backend.onrender.com/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpass123",
    "rememberMe": true
  }'
```

## 🎉 Next Steps

1. ✅ Run migrations
2. ✅ Test API endpoints
3. ✅ Update frontend configuration
4. ✅ Test authentication flow
5. ✅ Monitor logs for errors
6. ✅ Set up monitoring/alerts (optional)

## 📊 Monitoring

- **Logs**: Check Render dashboard → Logs tab
- **Metrics**: Monitor CPU, Memory, Response times
- **Health**: Set up health check endpoint (optional)

---

**Your backend is live! 🚀**

Test it and let me know if you encounter any issues!
