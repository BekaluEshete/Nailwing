from rest_framework import generics, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.db.models import Q
from .models import ChatRoom, Message, UserProfile
from .serializers import ChatRoomSerializer, MessageSerializer


@api_view(["GET"])
@permission_classes([permissions.IsAuthenticated])
def user_search(request):
    """Search users for chat"""
    query = request.GET.get("q", "")
    if query:
        from authentication.models import CustomUser

        users = CustomUser.objects.filter(
            Q(username__icontains=query)
            | Q(email__icontains=query)
            | Q(first_name__icontains=query)
            | Q(last_name__icontains=query)
        ).exclude(id=request.user.id)[:10]

        from .serializers import UserSerializer

        serializer = UserSerializer(users, many=True)
        return Response(serializer.data)
    return Response([])


class ChatRoomList(generics.ListCreateAPIView):
    serializer_class = ChatRoomSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return ChatRoom.objects.filter(is_active=True)

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)


class ChatRoomDetail(generics.RetrieveAPIView):
    serializer_class = ChatRoomSerializer
    permission_classes = [permissions.IsAuthenticated]
    queryset = ChatRoom.objects.filter(is_active=True)


class MessageList(generics.ListAPIView):
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        room_id = self.kwargs["room_id"]
        return Message.objects.filter(room_id=room_id).select_related("user")[:50]


class CreatePersonalChat(generics.CreateAPIView):
    permission_classes = [permissions.IsAuthenticated]

    def create(self, request, *args, **kwargs):
        user_id = request.data.get("user_id")
        try:
            from authentication.models import CustomUser
            from matching.models import Match

            other_user = CustomUser.objects.get(id=user_id)

            # Check if connection is accepted (both users have liked/match status is matched)
            # Determine user1 and user2 for match lookup
            if request.user.id < other_user.id:
                user1, user2 = request.user, other_user
            else:
                user1, user2 = other_user, request.user

            # Check if there's a match with 'matched' status
            match = Match.objects.filter(
                user1=user1,
                user2=user2,
                status='matched'
            ).first()

            if not match:
                # Check if connection request exists but not accepted
                pending_match = Match.objects.filter(
                    Q(user1=user1, user2=user2) | Q(user1=user2, user2=user1),
                    status='connection_requested'
                ).first()
                
                if pending_match:
                    return Response(
                        {"error": "Connection request not yet accepted. Please wait for the other person to accept your connection request."},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                return Response(
                    {"error": "Connection not established. Please send a connection request first."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Create unique room name for personal chat
            room_name = f"personal_{min(request.user.id, other_user.id)}_{max(request.user.id, other_user.id)}"

            # Check if room already exists
            room, created = ChatRoom.objects.get_or_create(
                name=room_name,
                defaults={
                    "description": f"Personal chat between {request.user.username} and {other_user.username}",
                    "created_by": request.user,
                    "room_type": "personal",
                },
            )

            serializer = ChatRoomSerializer(room)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        except CustomUser.DoesNotExist:
            return Response(
                {"error": "User not found"}, status=status.HTTP_404_NOT_FOUND
            )
