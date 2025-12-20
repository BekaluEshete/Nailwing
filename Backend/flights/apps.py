from django.apps import AppConfig


class FlightsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'flights'
    
    def ready(self):
        """Import signals when app is ready"""
        import flights.signals  # noqa

