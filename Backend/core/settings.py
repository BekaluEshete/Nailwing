import os
from pathlib import Path
import dj_database_url
from dotenv import load_dotenv
from datetime import timedelta

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(os.path.join(BASE_DIR, ".env"))

# =========================
# SECURITY
# =========================
SECRET_KEY = os.getenv("SECRET_KEY", "unsafe-secret")

DEBUG = os.getenv("DEBUG", "False") == "True"

ALLOWED_HOSTS = os.getenv("ALLOWED_HOSTS", "*").split(",")

CSRF_TRUSTED_ORIGINS = [
    "http://164.68.109.145",
]

CSRF_COOKIE_SECURE = False
SESSION_COOKIE_SECURE = False

# =========================
# APPLICATIONS
# =========================
INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "rest_framework_simplejwt",
    "corsheaders",
    "authentication",
    "channels",
    "chat",
    "flights",
    "matching",
    "recommendations",
]

# =========================
# MIDDLEWARE
# =========================
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    # CSRF middleware kept but safe for JWT APIs
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "core.urls"

# =========================
# TEMPLATES
# =========================
TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

# =========================
# WSGI / ASGI
# =========================
WSGI_APPLICATION = "core.wsgi.application"
ASGI_APPLICATION = "core.asgi.application"

# =========================
# DATABASE
# =========================
DATABASES = {"default": dj_database_url.config(default=os.getenv("DATABASE_URL"))}

# =========================
# AUTH / USER
# =========================
AUTH_USER_MODEL = "authentication.CustomUser"
AUTHENTICATION_BACKENDS = ["authentication.backends.EmailBackend"]

# =========================
# REST FRAMEWORK / JWT
# =========================
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.AllowAny",),
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(days=1),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
}

# =========================
# CORS (SAFE FOR MOBILE)
# =========================
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True

CORS_ALLOW_HEADERS = [
    "accept",
    "accept-encoding",
    "authorization",
    "content-type",
    "dnt",
    "origin",
    "user-agent",
    "x-csrftoken",
    "x-requested-with",
]

CORS_ALLOW_METHODS = [
    "DELETE",
    "GET",
    "OPTIONS",
    "PATCH",
    "POST",
    "PUT",
]

# =========================
# CHANNELS (REDIS FOR PRODUCTION)
# =========================
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")


# Parse Redis URL for channels-redis
# Format: redis://host:port/db or redis://:password@host:port/db
def parse_redis_url(url):
    """Parse Redis URL into (host, port, db) tuple"""
    try:
        # Remove redis:// prefix
        url = url.replace("redis://", "").replace("rediss://", "")

        # Handle password
        if "@" in url:
            auth, rest = url.split("@", 1)
            url = rest

        # Split host:port/db
        if "/" in url:
            host_port, db = url.split("/", 1)
        else:
            host_port, db = url, "0"

        # Split host:port
        if ":" in host_port:
            host, port = host_port.split(":", 1)
            port = int(port)
        else:
            host, port = host_port, 6379

        return (host, port), int(db)
    except Exception:
        return ("localhost", 6379), 0


# Try to use Redis channel layer, fallback to InMemory for local dev
try:
    import redis

    # Test Redis connection
    redis_client_test = redis.from_url(REDIS_URL)
    # redis_client_test.ping()
    # redis_client_test.close()

    redis_host_port, redis_db = parse_redis_url(REDIS_URL)

    CHANNEL_LAYERS = {
        "default": {
            "BACKEND": "channels_redis.core.RedisChannelLayer",
            "CONFIG": {
                "hosts": [redis_host_port],
                "capacity": 1500,  # Maximum number of messages to queue per channel
                "expiry": 10,  # Message expiry in seconds
            },
        },
    }
    # print(f"SUCCESS: Using Redis Channel Layer at {redis_host_port}")
except (redis.ConnectionError, ValueError, AttributeError, Exception) as e:
    print(f"WARNING: Redis not available, using InMemoryChannelLayer: {e}")
    CHANNEL_LAYERS = {
        "default": {
            "BACKEND": "channels.layers.InMemoryChannelLayer",
        }
    }

# =========================
# CACHE (REDIS FOR PRODUCTION)
# =========================
try:
    import redis

    redis_client_test = redis.from_url(REDIS_URL)
    # redis_client_test.ping()
    # redis_client_test.close()

    CACHES = {
        "default": {
            "BACKEND": "django_redis.cache.RedisCache",
            "LOCATION": REDIS_URL,
            "OPTIONS": {
                "CLIENT_CLASS": "django_redis.client.DefaultClient",
            },
        }
    }
    # print(f"SUCCESS: Using Redis Cache at {REDIS_URL}")
except (redis.ConnectionError, ValueError, AttributeError, Exception) as e:
    print(f"WARNING: Redis not available, using LocMemCache: {e}")
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        }
    }

# =========================
# PASSWORD VALIDATION
# =========================
AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"
    },
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

# =========================
# INTERNATIONALIZATION
# =========================
LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

# =========================
# STATIC FILES
# =========================
STATIC_URL = "/static/"
STATIC_ROOT = os.path.join(BASE_DIR, "staticfiles")
os.makedirs(STATIC_ROOT, exist_ok=True)

STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"

# =========================
# MEDIA FILES
# =========================
MEDIA_URL = "/media/"
MEDIA_ROOT = os.path.join(BASE_DIR, "media")

# =========================
# UPLOAD LIMITS
# =========================
FILE_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024 * 1024
DATA_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024 * 1024

# =========================
# DEFAULT PK
# =========================
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
