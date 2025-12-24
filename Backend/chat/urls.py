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
    path(
        "api/rooms/<uuid:room_id>/messages/create/",
        views.MessageList.as_view(),
        name="message-create",
    ),
    path(
        "api/rooms/<uuid:room_id>/messages/mark_read/",
        views.MarkMessagesAsRead.as_view(),
        name="mark-messages-read",
    ),
    path(
        "api/rooms/<uuid:room_id>/mark_read/",
        views.MarkRoomAsRead.as_view(),
        name="mark-room-read",
    ),
    path(
        "api/rooms/<uuid:room_id>/unread_count/",
        views.UnreadCountView.as_view(),
        name="unread-count",
    ),
    path("api/users/search/", views.user_search, name="user-search"),
    path(
        "api/chats/personal/",
        views.CreatePersonalChat.as_view(),
        name="create-personal-chat",
    ),
]
