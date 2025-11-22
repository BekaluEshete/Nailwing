# 🚀 Deploy Django Backend to Render - Step by Step Guide

This guide will help you deploy your NileWing Django backend to Render with PostgreSQL, Redis, and WebSocket support.

---

## 📋 Prerequisites

1. **Render Account**: Sign up at [render.com](https://render.com) (free tier available)
2. **GitHub Account**: Your code should be in a GitHub repository
3. **Backend Code**: Ensure all files are committed to your repository

---

## 🔧 Step 1: Prepare Your Code

### 1.1 Update Settings for Production

The settings have been updated with:

- ✅ WhiteNoise for static files
- ✅ CORS middleware
- ✅ Static files configuration
- ✅ Production-ready settings

### 1.2 Create/Update Required Files

✅ **Procfile** - Created (tells Render how to run your app)
✅ **requirements.txt** - Updated with WhiteNoise

### 1.3 Commit Your Changes

```bash
git add .
git commit -m "Prepare for Render deployment"
git push origin main
```

---

## 🗄️ Step 2: Create PostgreSQL Database on Render

1. **Go to Render Dashboard**: https://dashboard.render.com
2. **Click "New +"** → Select **"PostgreSQL"**
3. **Configure Database**:
   - **Name**: `nilewing-db` (or your preferred name)
   - **Database**: `nilewing_db`
   - **User**: (auto-generated)
   - **Region**: Choose closest to your users
   - **PostgreSQL Version**: 15 or 16
   - **Plan**: Free tier (or paid for production)
4. **Click "Create Database"**
5. **Wait for database to be created** (takes 1-2 minutes)
6. **Copy the Internal Database URL** (you'll need this later)

---

## 🔴 Step 3: Create Redis Instance on Render

1. **In Render Dashboard**, click **"New +"** → Select **"Redis"**
2. **Configure Redis**:
   - **Name**: `nilewing-redis`
   - **Region**: Same as PostgreSQL
   - **Plan**: Free tier (or paid for production)
   - **Maxmemory Policy**: `allkeys-lru`
3. **Click "Create Redis"**
4. **Wait for Redis to be created**
5. **Copy the Internal Redis URL** (format: `redis://red-xxxxx:6379`)

---

## 🌐 Step 4: Create Web Service on Render

1. **In Render Dashboard**, click **"New +"** → Select **"Web Service"**
2. **Connect Your Repository**:

   - Connect your GitHub account if not already connected
   - Select your repository
   - Select the branch (usually `main` or `master`)

3. **Configure Web Service**:

   - **Name**: `nilewing-backend`
   - **Region**: Same as database and Redis
   - **Branch**: `main` (or your default branch)
   - **Root Directory**: `Backend` (important!)
   - **Runtime**: `Python 3`
   - **Build Command**:
     ```bash
     pip install --upgrade pip && pip install -r requirements.txt && python manage.py collectstatic --noinput
     ```
   - **Start Command**:
     ```bash
     daphne -b 0.0.0.0:$PORT core.asgi:application
     ```

4. **Environment Variables** - Click "Advanced" and add:

   ```
   SECRET_KEY=your-super-secret-key-here-generate-a-random-string
   DEBUG=False
   ALLOWED_HOSTS=your-app-name.onrender.com,localhost,127.0.0.1
   DATABASE_URL=<Internal Database URL from Step 2>
   REDIS_URL=<Internal Redis URL from Step 3>
   PYTHON_VERSION=3.13
   ```

   **Important Notes**:

   - Generate a strong `SECRET_KEY`:
     ```python
     python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
     ```
   - Replace `your-app-name.onrender.com` with your actual Render service URL
   - Use **Internal Database URL** (not external) for better performance
   - Use **Internal Redis URL** (not external) for better performance

5. **Click "Create Web Service"**

---

## 🔄 Step 5: Run Database Migrations

After your web service is deployed:

1. **Go to your Web Service** in Render Dashboard
2. **Click on "Shell"** tab (or use "Manual Deploy" → "Run Command")
3. **Run migrations**:
   ```bash
   python manage.py migrate
   ```
4. **Create superuser** (optional):
   ```bash
   python manage.py createsuperuser
   ```

---

## 🔗 Step 6: Link Services (Optional but Recommended)

1. **Go to your Web Service** → **Settings** → **Environment**
2. **Add Service Links**:

   - Link your PostgreSQL database
   - Link your Redis instance

   This allows Render to automatically inject connection URLs.

---

## ✅ Step 7: Verify Deployment

1. **Check Service Status**: Should show "Live" in green
2. **Test API Endpoints**:
   - Health check: `https://your-app-name.onrender.com/api/auth/`
   - Admin panel: `https://your-app-name.onrender.com/admin/`
3. **Check Logs**: Click "Logs" tab to see real-time logs

---

## 🔐 Step 8: Update Frontend Configuration

Update your Flutter app's `app_constants.dart`:

```dart
class AppConstants {
  // Production Backend URL
  static const String baseUrl = 'https://your-app-name.onrender.com';

  // API Endpoints
  static const String apiBaseUrl = '$baseUrl/api';
  static const String authBaseUrl = '$apiBaseUrl/auth';

  // ... rest of the code
}
```

---

## 📝 Step 9: Additional Configuration

### CORS Settings (if needed)

If you need to allow specific origins, add to `settings.py`:

```python
CORS_ALLOWED_ORIGINS = [
    "https://your-frontend-domain.com",
    "http://localhost:3000",  # For local development
]

CORS_ALLOW_CREDENTIALS = True
```

### Static Files

Static files are automatically served by WhiteNoise. If you need to serve media files:

1. **Use a CDN** (recommended for production)
2. **Or configure S3** for media storage
3. **Or use Render's disk storage** (limited, not recommended for production)

---

## 🐛 Troubleshooting

### Issue: "ModuleNotFoundError"

- **Solution**: Ensure `requirements.txt` includes all dependencies
- Check build logs for missing packages

### Issue: "Database connection failed"

- **Solution**:
  - Verify `DATABASE_URL` is correct
  - Use Internal Database URL (not external)
  - Check database is running

### Issue: "Redis connection failed"

- **Solution**:
  - Verify `REDIS_URL` is correct
  - Use Internal Redis URL (not external)
  - Check Redis is running

### Issue: "Static files not found"

- **Solution**:
  - Ensure `collectstatic` runs in build command
  - Check WhiteNoise is in requirements.txt
  - Verify STATIC_ROOT is set correctly

### Issue: "WebSocket not working"

- **Solution**:
  - Verify Redis is connected
  - Check CHANNEL_LAYERS configuration
  - Ensure WebSocket URL uses `wss://` (secure) not `ws://`

### Issue: "502 Bad Gateway"

- **Solution**:
  - Check service logs
  - Verify start command is correct
  - Check if service is using correct port ($PORT)

### Issue: "Application Error"

- **Solution**:
  - Check logs in Render dashboard
  - Verify all environment variables are set
  - Check if migrations ran successfully

---

## 📊 Monitoring

### View Logs

- **Real-time**: Click "Logs" tab in Render dashboard
- **Historical**: Logs are kept for 7 days (free tier)

### Metrics

- **CPU Usage**: Monitor in dashboard
- **Memory Usage**: Monitor in dashboard
- **Response Times**: Available in metrics tab

---

## 💰 Cost Estimation

### Free Tier:

- **PostgreSQL**: 90 days free, then $7/month
- **Redis**: 30 days free, then $10/month
- **Web Service**: Free (with limitations)
  - Spins down after 15 minutes of inactivity
  - 750 hours/month free

### Paid Tier (Recommended for Production):

- **PostgreSQL**: $7/month (starter plan)
- **Redis**: $10/month (starter plan)
- **Web Service**: $7/month (starter plan)
- **Total**: ~$24/month

---

## 🔄 Updating Your Deployment

1. **Make changes** to your code
2. **Commit and push** to GitHub:
   ```bash
   git add .
   git commit -m "Your commit message"
   git push origin main
   ```
3. **Render automatically deploys** (if auto-deploy is enabled)
4. **Or manually deploy** from Render dashboard

---

## 🎯 Production Checklist

- [ ] Set `DEBUG=False` in environment variables
- [ ] Use strong `SECRET_KEY`
- [ ] Configure `ALLOWED_HOSTS` correctly
- [ ] Set up proper CORS origins
- [ ] Run database migrations
- [ ] Create superuser account
- [ ] Test all API endpoints
- [ ] Test WebSocket connections
- [ ] Set up monitoring/alerts
- [ ] Configure backup for database
- [ ] Update frontend with production URL
- [ ] Test authentication flow
- [ ] Verify static files are served
- [ ] Check logs for errors

---

## 📚 Additional Resources

- [Render Documentation](https://render.com/docs)
- [Django on Render](https://render.com/docs/deploy-django)
- [PostgreSQL on Render](https://render.com/docs/databases)
- [Redis on Render](https://render.com/docs/redis)

---

## 🆘 Support

If you encounter issues:

1. Check Render logs
2. Check Django logs
3. Verify environment variables
4. Test locally first
5. Check Render status page: https://status.render.com

---

**Your backend should now be live on Render! 🎉**

After deployment, update your Flutter app's `app_constants.dart` with the production URL.
