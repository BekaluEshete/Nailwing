from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import FlightViewSet, UserInterestViewSet, TravelPreferenceViewSet

router = DefaultRouter()
router.register(r'flights', FlightViewSet, basename='flight')
router.register(r'interests', UserInterestViewSet, basename='interest')
router.register(r'preferences', TravelPreferenceViewSet, basename='preference')

urlpatterns = [
    path('', include(router.urls)),
]

