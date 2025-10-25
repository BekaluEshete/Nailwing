from django.urls import path
from . import views

urlpatterns = [
    path("api/rooms/", views.ChatRoomList.as_view(), name="room-list"),
    path("api/rooms/<uuid:pk>/", views.ChatRoomDetail.as_view(), name="room-detail"),
    path(
        "api/rooms/<uuid:room_id>/messages/",
        views.MessageList.as_view(),
        name="message-list",
    ),
    path("api/users/search/", views.user_search, name="user-search"),
    path(
        "api/chats/personal/",
        views.CreatePersonalChat.as_view(),
        name="create-personal-chat",
    ),
]
