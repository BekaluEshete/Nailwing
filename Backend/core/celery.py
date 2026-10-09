"""
Celery application instance for Nailwing.

Workers are started with:
    celery -A core worker --loglevel=info --concurrency=4

Beat scheduler (for periodic tasks) is started with:
    celery -A core beat --loglevel=info
"""
import os
from celery import Celery

# Tell Celery which Django settings module to use
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")

app = Celery("nailwing")

# Read config from Django settings, namespace CELERY_* keys
app.config_from_object("django.conf:settings", namespace="CELERY")

# Auto-discover tasks in all installed apps (looks for tasks.py in each app)
app.autodiscover_tasks()


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    """Sanity-check task — verifies the worker is running correctly."""
    print(f"Request: {self.request!r}")
