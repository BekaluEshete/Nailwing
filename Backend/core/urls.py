from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView
from core.health import HealthCheckView

urlpatterns = [
    # Admin
    path("admin/", admin.site.urls),

    # Prometheus metrics — scraped by Prometheus server
    # Restrict access at the network/nginx level in production
    # (do not expose this to the public internet)
    path("", include("django_prometheus.urls")),

    # Health check — used by load balancers and uptime monitors
    path("health/", HealthCheckView.as_view(), name="health-check"),

    # API schema + Swagger UI (drf-spectacular)
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),

    # Application APIs
    path("api/", include("authentication.urls")),
    path("api/flights/", include("flights.urls")),
    path("api/matching/", include("matching.urls")),
    path("api/recommendations/", include("recommendations.urls")),
    path("chat/", include("chat.urls")),
]
