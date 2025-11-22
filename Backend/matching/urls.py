from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import MatchViewSet, MatchFilterViewSet

router = DefaultRouter()
router.register(r'matches', MatchViewSet, basename='match')
router.register(r'filters', MatchFilterViewSet, basename='matchfilter')

urlpatterns = [
    path('', include(router.urls)),
]

