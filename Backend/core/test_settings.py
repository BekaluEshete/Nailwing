"""
Test settings — overrides production settings for fast, isolated test runs.
Uses SQLite (in-memory), disables Redis channel layers, and skips Cloudinary.

Usage:
    python manage.py test --settings=core.test_settings
"""
from core.settings import *  # noqa: F401, F403

# ---------------------------------------------------------------------------
# Database — fast in-memory SQLite for tests
# ---------------------------------------------------------------------------
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": ":memory:",
    }
}

# ---------------------------------------------------------------------------
# Channel layers — in-memory (no Redis required)
# ---------------------------------------------------------------------------
CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels.layers.InMemoryChannelLayer",
    }
}

# ---------------------------------------------------------------------------
# Password hashing — fastest hasher for tests
# ---------------------------------------------------------------------------
PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.MD5PasswordHasher",
]

# ---------------------------------------------------------------------------
# Media / static — avoid filesystem writes during tests
# ---------------------------------------------------------------------------
DEFAULT_FILE_STORAGE = "django.core.files.storage.InMemoryStorage"

# ---------------------------------------------------------------------------
# Email — suppress outgoing emails
# ---------------------------------------------------------------------------
EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"

# ---------------------------------------------------------------------------
# Logging — silence noisy output during test runs
# ---------------------------------------------------------------------------
LOGGING = {
    "version": 1,
    "disable_existing_loggers": True,
    "handlers": {
        "null": {"class": "logging.NullHandler"},
    },
    "root": {
        "handlers": ["null"],
        "level": "CRITICAL",
    },
}

# ---------------------------------------------------------------------------
# Security — relax for tests
# ---------------------------------------------------------------------------
SECRET_KEY = "test-secret-key-not-for-production"
DEBUG = True
ALLOWED_HOSTS = ["*"]
