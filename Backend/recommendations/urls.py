from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AirportPlaceViewSet, RecommendationViewSet

router = DefaultRouter()
router.register(r'places', AirportPlaceViewSet, basename='place')
router.register(r'recommendations', RecommendationViewSet, basename='recommendation')

urlpatterns = [
    path('', include(router.urls)),
]

