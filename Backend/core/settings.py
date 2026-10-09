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
    "drf_spectacular",
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
    # ---------------------------------------------------------------------------
    # Rate Limiting
    # Throttle counters are stored in the Django cache (Redis in production).
    # Scopes:
    #   anon     — unauthenticated requests (20/min default)
    #   user     — authenticated requests (200/min default)
    #   auth     — login & register endpoints (5/min — brute-force protection)
    #   matching — find_matches endpoint (10/min — expensive multi-query operation)
    # ---------------------------------------------------------------------------
    "DEFAULT_THROTTLE_CLASSES": [
        "rest_framework.throttling.AnonRateThrottle",
        "rest_framework.throttling.UserRateThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "anon": "20/minute",
        "user": "200/minute",
        "auth": "5/minute",
        "matching": "10/minute",
    },
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
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
    import logging as _logging
    _logging.getLogger("core").warning("Redis not available, using InMemoryChannelLayer: %s", e)
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
            # Namespace all keys to avoid collisions with other apps on the same Redis
            "KEY_PREFIX": "nailwing",
            # Default TTL: 5 minutes — individual views override as needed
            "TIMEOUT": 300,
        }
    }
    # print(f"SUCCESS: Using Redis Cache at {REDIS_URL}")
except (redis.ConnectionError, ValueError, AttributeError, Exception) as e:
    import logging as _logging
    _logging.getLogger("core").warning("Redis not available, using LocMemCache: %s", e)
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

# =========================
# CELERY
# =========================
# Broker: reuse the existing Redis instance (db 2 to avoid collisions with
# channel layers on db 0 and cache on db 1)
CELERY_BROKER_URL = os.getenv("CELERY_BROKER_URL", REDIS_URL.replace("/1", "/2").replace("/0", "/2"))
CELERY_RESULT_BACKEND = os.getenv("CELERY_RESULT_BACKEND", REDIS_URL.replace("/1", "/2").replace("/0", "/2"))

# Serialization — JSON only (safe, human-readable)
CELERY_TASK_SERIALIZER = "json"
CELERY_RESULT_SERIALIZER = "json"
CELERY_ACCEPT_CONTENT = ["json"]

# Timezone — must match Django's TIME_ZONE
CELERY_TIMEZONE = "UTC"
CELERY_ENABLE_UTC = True

# Task time limits — prevent runaway tasks from stalling workers
CELERY_TASK_SOFT_TIME_LIMIT = 30   # raises SoftTimeLimitExceeded after 30s
CELERY_TASK_TIME_LIMIT = 60        # hard kill after 60s

# Retry policy defaults
CELERY_TASK_MAX_RETRIES = 3
CELERY_TASK_DEFAULT_RETRY_DELAY = 5  # seconds

# Result expiry — keep results for 1 hour then discard
CELERY_RESULT_EXPIRES = 3600

# Prevent tasks from running synchronously in tests unless explicitly enabled
CELERY_TASK_ALWAYS_EAGER = False

# =========================
# API DOCUMENTATION (drf-spectacular)
# =========================
SPECTACULAR_SETTINGS = {
    "TITLE": "Nailwing API",
    "DESCRIPTION": "Real-time travel companion matching platform API",
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
}

# =========================
# SENTRY — Error Monitoring
# =========================
# Set SENTRY_DSN in your .env to enable error tracking.
# Leave it empty to disable Sentry (e.g. local development).
# Get your DSN from https://sentry.io → Project Settings → Client Keys.
SENTRY_DSN = os.getenv("SENTRY_DSN", "")

if SENTRY_DSN:
    import sentry_sdk
    from sentry_sdk.integrations.django import DjangoIntegration
    from sentry_sdk.integrations.celery import CeleryIntegration
    from sentry_sdk.integrations.redis import RedisIntegration
    from sentry_sdk.integrations.logging import LoggingIntegration
    import logging as _logging

    sentry_sdk.init(
        dsn=SENTRY_DSN,
        # Capture environment tag — matches Docker / server environment
        environment=os.getenv("SENTRY_ENVIRONMENT", "production" if not DEBUG else "development"),
        # Tag releases by git commit SHA or a version string
        release=os.getenv("SENTRY_RELEASE", "nailwing@1.0.0"),
        integrations=[
            DjangoIntegration(
                # Capture request body in error reports (safe — Sentry scrubs passwords)
                transaction_style="url",
            ),
            # Capture Celery task failures with full stack traces
            CeleryIntegration(monitor_beat_tasks=False),
            # Capture Redis errors
            RedisIntegration(),
            # Forward Python logging WARNING+ to Sentry as breadcrumbs
            LoggingIntegration(
                level=_logging.WARNING,
                event_level=_logging.ERROR,
            ),
        ],
        # Performance tracing — capture 5% of requests for latency analysis
        # Increase to 1.0 in staging, decrease to 0.01 in high-traffic production
        traces_sample_rate=float(os.getenv("SENTRY_TRACES_SAMPLE_RATE", "0.05")),
        # Don't send PII (email, IP) by default
        send_default_pii=False,
        # Ignore common non-actionable exceptions
        ignore_errors=[
            KeyboardInterrupt,
            SystemExit,
        ],
    )

# =========================
# LOGGING
# =========================
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "[{asctime}] [{levelname}] [{name}] {message}",
            "style": "{",
            "datefmt": "%Y-%m-%d %H:%M:%S",
        },
        "simple": {
            "format": "[{levelname}] {message}",
            "style": "{",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "verbose",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "WARNING",
    },
    "loggers": {
        # Django internals — only warnings and above in production
        "django": {
            "handlers": ["console"],
            "level": "WARNING",
            "propagate": False,
        },
        # Show SQL queries only in DEBUG mode
        "django.db.backends": {
            "handlers": ["console"],
            "level": "DEBUG" if DEBUG else "WARNING",
            "propagate": False,
        },
        # App-level loggers — INFO in production, DEBUG when DEBUG=True
        "authentication": {
            "handlers": ["console"],
            "level": "DEBUG" if DEBUG else "INFO",
            "propagate": False,
        },
        "chat": {
            "handlers": ["console"],
            "level": "DEBUG" if DEBUG else "INFO",
            "propagate": False,
        },
        "flights": {
            "handlers": ["console"],
            "level": "DEBUG" if DEBUG else "INFO",
            "propagate": False,
        },
        "matching": {
            "handlers": ["console"],
            "level": "DEBUG" if DEBUG else "INFO",
            "propagate": False,
        },
        "recommendations": {
            "handlers": ["console"],
            "level": "DEBUG" if DEBUG else "INFO",
            "propagate": False,
        },
        "core": {
            "handlers": ["console"],
            "level": "DEBUG" if DEBUG else "INFO",
            "propagate": False,
        },
    },
}
