# Import the Celery app here so it is loaded whenever Django starts.
# This ensures that @shared_task decorators in any app use this app instance.
from .celery import app as celery_app

__all__ = ("celery_app",)
