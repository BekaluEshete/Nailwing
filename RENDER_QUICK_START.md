# 🚀 Render Deployment - Quick Start

## Quick Checklist

### 1. Create Services on Render

1. **PostgreSQL Database**
   - Name: `nilewing-db`
   - Copy Internal Database URL

2. **Redis Instance**
   - Name: `nilewing-redis`
   - Copy Internal Redis URL

3. **Web Service**
   - Repository: Your GitHub repo
   - Root Directory: `Backend`
   - Build Command: `pip install --upgrade pip && pip install -r requirements.txt && python manage.py collectstatic --noinput`
   - Start Command: `daphne -b 0.0.0.0:$PORT core.asgi:application`

### 2. Environment Variables

```
SECRET_KEY=<generate-random-key>
DEBUG=False
ALLOWED_HOSTS=your-app.onrender.com,localhost
DATABASE_URL=<internal-postgres-url>
REDIS_URL=<internal-redis-url>
PYTHON_VERSION=3.13
```

### 3. Run Migrations

In Render Shell:
```bash
python manage.py migrate
python manage.py createsuperuser
```

### 4. Update Frontend

In `app_constants.dart`:
```dart
static const String baseUrl = 'https://your-app.onrender.com';
```

---

**Full guide**: See `RENDER_DEPLOYMENT_GUIDE.md`

