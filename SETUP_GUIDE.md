# 🚀 NileWing Project Setup Guide

This guide will help you set up and run both the Backend (Django) and Frontend (Flutter) of the NileWing application.

---

## 📋 Prerequisites

### For Backend:
- **Python 3.10+** (Python 3.13 recommended based on Dockerfile)
- **PostgreSQL** (or use Neon cloud database)
- **Redis** (for caching and WebSocket channel layer)
- **Docker & Docker Compose** (optional, for containerized setup)
- **pip** (Python package manager)

### For Frontend:
- **Flutter SDK 3.8.1+** (check `pubspec.yaml`)
- **Dart SDK**
- **Android Studio / Xcode** (for mobile development)
- **VS Code / Android Studio** (recommended IDE)

---

## 🔧 Backend Setup (Django)

### Option 1: Using Docker (Recommended)

1. **Navigate to Backend directory:**
   ```bash
   cd Backend
   ```

2. **Create a `.env` file** in the `Backend` directory:
   ```env
   SECRET_KEY=your-secret-key-here-generate-a-random-string
   DEBUG=True
   ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0
   DATABASE_URL=postgresql://username:password@host:port/dbname
   REDIS_URL=redis://redis:6379/0
   ```

   **For local PostgreSQL:**
   ```env
   DATABASE_URL=postgresql://postgres:password@localhost:5432/nilewing_db
   ```

   **For Neon (Cloud PostgreSQL):**
   ```env
   DATABASE_URL=postgresql://user:password@ep-xxx.region.aws.neon.tech/neondb?sslmode=require
   ```

3. **Build and run with Docker Compose:**
   ```bash
   docker-compose up --build
   ```

   This will:
   - Build the Django container
   - Start Redis container
   - Run migrations automatically
   - Start the server on `http://localhost:8000`

4. **Run migrations (if needed):**
   ```bash
   docker-compose exec web python manage.py migrate
   ```

5. **Create a superuser (optional):**
   ```bash
   docker-compose exec web python manage.py createsuperuser
   ```

### Option 2: Local Development Setup

1. **Navigate to Backend directory:**
   ```bash
   cd Backend
   ```

2. **Create a virtual environment:**
   ```bash
   # Windows
   python -m venv venv
   venv\Scripts\activate

   # macOS/Linux
   python3 -m venv venv
   source venv/bin/activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up PostgreSQL database:**
   - Install PostgreSQL locally, OR
   - Use Neon (https://neon.tech) for a free cloud database
   - Create a database named `nilewing_db` (or your preferred name)

5. **Set up Redis:**
   ```bash
   # Using Docker (easiest)
   docker run -d -p 6379:6379 redis:7-alpine

   # Or install Redis locally
   # Windows: Download from https://github.com/microsoftarchive/redis/releases
   # macOS: brew install redis && brew services start redis
   # Linux: sudo apt-get install redis-server && sudo systemctl start redis
   ```

6. **Create `.env` file** in `Backend` directory:
   ```env
   SECRET_KEY=your-secret-key-here-generate-a-random-string
   DEBUG=True
   ALLOWED_HOSTS=localhost,127.0.0.1
   DATABASE_URL=postgresql://postgres:password@localhost:5432/nilewing_db
   REDIS_URL=redis://localhost:6379/0
   ```

   **Generate a secret key:**
   ```bash
   python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
   ```

7. **Run migrations:**
   ```bash
   python manage.py migrate
   ```

8. **Create superuser (optional):**
   ```bash
   python manage.py createsuperuser
   ```

9. **Collect static files (if needed):**
   ```bash
   python manage.py collectstatic --noinput
   ```

10. **Run the development server:**
    ```bash
    # Using Daphne (ASGI server for WebSockets)
    daphne -b 0.0.0.0 -p 8000 core.asgi:application

    # OR using Django's development server (HTTP only, no WebSockets)
    python manage.py runserver
    ```

    The backend will be available at: `http://localhost:8000`

11. **Access Django Admin:**
    - URL: `http://localhost:8000/admin/`
    - Use the superuser credentials you created

---

## 📱 Frontend Setup (Flutter)

1. **Navigate to Frontend directory:**
   ```bash
   cd Frontend/nilewing
   ```

2. **Check Flutter installation:**
   ```bash
   flutter doctor
   ```
   Make sure all required components are installed.

3. **Get Flutter dependencies:**
   ```bash
   flutter pub get
   ```

4. **Update API base URL (if needed):**
   
   Currently, the services use mock data. To connect to the backend:
   
   - Edit `lib/features/chat/service/chat_service.dart`:
     ```dart
     static const String _baseUrl = 'http://localhost:8000/api';
     ```
   
   - Update other service files similarly to point to your backend URL
   
   **For Android emulator, use:** `http://10.0.2.2:8000/api`
   **For iOS simulator, use:** `http://localhost:8000/api`
   **For physical device, use:** `http://YOUR_COMPUTER_IP:8000/api`

5. **Run the app:**
   ```bash
   # List available devices
   flutter devices

   # Run on a specific device
   flutter run

   # Run on Android
   flutter run -d android

   # Run on iOS (macOS only)
   flutter run -d ios

   # Run on Chrome (web)
   flutter run -d chrome
   ```

---

## 🔗 Connecting Frontend to Backend

### Update API Configuration

1. **Create a constants file** or update `lib/core/utils/app_constants.dart`:
   ```dart
   class AppConstants {
     // For Android Emulator
     static const String baseUrl = 'http://10.0.2.2:8000/api';
     
     // For iOS Simulator
     // static const String baseUrl = 'http://localhost:8000/api';
     
     // For Physical Device (replace with your computer's IP)
     // static const String baseUrl = 'http://192.168.1.XXX:8000/api';
   }
   ```

2. **Update services to use real API calls:**
   - `lib/features/auth/service/login_service.dart`
   - `lib/features/auth/service/registration_service.dart`
   - `lib/features/chat/service/chat_service.dart`
   - Other service files as needed

3. **Enable CORS on Backend** (already configured with `django-cors-headers`):
   - Make sure `CORS_ALLOWED_ORIGINS` is set in `settings.py` if needed

---

## 🧪 Testing the Setup

### Backend API Endpoints:

1. **Authentication:**
   - Register: `POST http://localhost:8000/api/auth/register/`
   - Login: `POST http://localhost:8000/api/auth/login/`
   - Profile: `GET http://localhost:8000/api/auth/profile/` (requires auth)

2. **Chat:**
   - List rooms: `GET http://localhost:8000/chat/api/rooms/`
   - WebSocket: `ws://localhost:8000/ws/chat/{room_name}/?token={jwt_token}`

### Test with curl:

```bash
# Register a user
curl -X POST http://localhost:8000/api/auth/register/ \
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

# Login
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpass123"
  }'
```

---

## 🐛 Troubleshooting

### Backend Issues:

1. **Database connection error:**
   - Check PostgreSQL is running
   - Verify DATABASE_URL in `.env` is correct
   - Ensure database exists

2. **Redis connection error:**
   - Check Redis is running: `redis-cli ping` (should return PONG)
   - Verify REDIS_URL in `.env`

3. **Port already in use:**
   - Change port: `python manage.py runserver 8001`
   - Or kill the process using port 8000

4. **Migration errors:**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

### Frontend Issues:

1. **Flutter dependencies:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Build errors:**
   ```bash
   flutter doctor -v
   flutter upgrade
   ```

3. **API connection issues:**
   - Check backend is running
   - Verify base URL matches your setup
   - Check CORS settings on backend
   - For physical devices, ensure phone and computer are on same network

---

## 📝 Environment Variables Summary

### Backend `.env` file:
```env
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0
DATABASE_URL=postgresql://user:password@host:port/dbname
REDIS_URL=redis://localhost:6379/0
```

---

## 🎯 Quick Start (TL;DR)

**Backend:**
```bash
cd Backend
# Create .env file with database and Redis URLs
docker-compose up --build
# OR
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
daphne -b 0.0.0.0 -p 8000 core.asgi:application
```

**Frontend:**
```bash
cd Frontend/nilewing
flutter pub get
flutter run
```

---

## 📚 Additional Resources

- [Django Documentation](https://docs.djangoproject.com/)
- [Django Channels Documentation](https://channels.readthedocs.io/)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)

---

**Happy Coding! 🚀**



