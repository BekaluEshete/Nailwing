from rest_framework import generics, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.db.models import Q, Count, Max
from .models import ChatRoom, Message, UserProfile, ReadReceipt
from .serializers import ChatRoomSerializer, MessageSerializer, ReadReceiptSerializer


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
    
    def get_serializer_context(self):
        """Add request to serializer context for unread_count calculation"""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_queryset(self):
        from matching.models import Match
        from django.db.models import Case, When, F, IntegerField

        user = self.request.user

        # Single annotated query extracts the other user's ID at DB level,
        # replacing the previous Python loop over Match objects.
        matched_user_ids = (
            Match.objects.filter(
                Q(user1=user) | Q(user2=user),
                status="matched",
            )
            .annotate(
                other_id=Case(
                    When(user1=user, then=F("user2_id")),
                    default=F("user1_id"),
                    output_field=IntegerField(),
                )
            )
            .values_list("other_id", flat=True)
            .distinct()
        )

        # Build room names directly in a list comprehension at DB level
        # Room name format: personal_{min_id}_{max_id}
        user_id = user.id
        personal_room_names = [
            f"personal_{min(user_id, other_id)}_{max(user_id, other_id)}"
            for other_id in matched_user_ids
        ]

        return (
            ChatRoom.objects.filter(
                is_active=True,
                room_type="personal",
                name__in=personal_room_names,
            )
            .select_related("created_by")
            .order_by("-created_at")
        )

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)


class ChatRoomDetail(generics.RetrieveAPIView):
    serializer_class = ChatRoomSerializer
    permission_classes = [permissions.IsAuthenticated]
    queryset = ChatRoom.objects.filter(is_active=True)


class MessageList(generics.ListCreateAPIView):
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        room_id = self.kwargs["room_id"]
        # Optimize with select_related and order by timestamp descending
        # Add pagination support
        limit = int(self.request.query_params.get('limit', 50))
        offset = int(self.request.query_params.get('offset', 0))
        
        # Return messages in ascending order (oldest first) for proper chat display
        return Message.objects.filter(
            room_id=room_id
        ).select_related("user", "room").prefetch_related("read_receipts").order_by('timestamp')[offset:offset + limit]
    
    def get_serializer_context(self):
        """Add request to serializer context for is_read field"""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def perform_create(self, serializer):
        """
        Create a message via HTTP (fallback when WebSocket fails).
        Idempotent: if client_msg_id already exists, return the existing message
        instead of creating a duplicate.
        """
        room_id = self.kwargs["room_id"]
        try:
            room = ChatRoom.objects.get(id=room_id, is_active=True)
            if room.room_type == "personal":
                room_name_parts = room.name.split("_")
                if len(room_name_parts) == 3:
                    user1_id, user2_id = int(room_name_parts[1]), int(room_name_parts[2])
                    if self.request.user.id not in [user1_id, user2_id]:
                        from rest_framework.exceptions import PermissionDenied
                        raise PermissionDenied("You don't have access to this chat room")

            client_msg_id = serializer.validated_data.get("client_msg_id")

            if client_msg_id:
                # Idempotent path — return existing message if already delivered
                message, created = Message.objects.get_or_create(
                    client_msg_id=client_msg_id,
                    defaults={
                        "room": room,
                        "user": self.request.user,
                        "content": serializer.validated_data["content"],
                        "message_type": serializer.validated_data.get("message_type", "text"),
                    },
                )
                if not created:
                    # Raise so DRF returns the existing instance — view will
                    # detect the saved instance via serializer.instance
                    serializer.instance = message
                    return
                serializer.instance = message
            else:
                serializer.save(room=room, user=self.request.user)

        except ChatRoom.DoesNotExist:
            from rest_framework.exceptions import NotFound
            raise NotFound("Chat room not found")


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


class MarkMessagesAsRead(generics.CreateAPIView):
    """Mark messages in a room as read for the current user"""
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ReadReceiptSerializer

    def create(self, request, *args, **kwargs):
        room_id = self.kwargs["room_id"]
        message_ids = request.data.get("message_ids", [])
        
        try:
            room = ChatRoom.objects.get(id=room_id, is_active=True)
            
            # Verify user has access to this room
            if room.room_type == "personal":
                room_name_parts = room.name.split("_")
                if len(room_name_parts) == 3:
                    user1_id, user2_id = int(room_name_parts[1]), int(room_name_parts[2])
                    if request.user.id not in [user1_id, user2_id]:
                        from rest_framework.exceptions import PermissionDenied
                        raise PermissionDenied("You don't have access to this chat room")
            
            # Get messages that belong to this room and are not from the current user
            messages = Message.objects.filter(
                room=room,
                id__in=message_ids
            ).exclude(user=request.user)  # Don't mark own messages as read
            
            # Create read receipts (bulk create for efficiency)
            read_receipts = []
            for message in messages:
                receipt, created = ReadReceipt.objects.get_or_create(
                    message=message,
                    user=request.user
                )
                if created:
                    read_receipts.append(receipt)
            
            return Response({
                "marked_count": len(read_receipts),
                "total_messages": len(message_ids)
            }, status=status.HTTP_201_CREATED)
            
        except ChatRoom.DoesNotExist:
            from rest_framework.exceptions import NotFound
            raise NotFound("Chat room not found")


class MarkRoomAsRead(generics.CreateAPIView):
    """Mark all messages in a room as read for the current user"""
    permission_classes = [permissions.IsAuthenticated]

    def create(self, request, *args, **kwargs):
        room_id = self.kwargs["room_id"]
        
        try:
            room = ChatRoom.objects.get(id=room_id, is_active=True)
            
            # Verify user has access to this room
            if room.room_type == "personal":
                room_name_parts = room.name.split("_")
                if len(room_name_parts) == 3:
                    user1_id, user2_id = int(room_name_parts[1]), int(room_name_parts[2])
                    if request.user.id not in [user1_id, user2_id]:
                        from rest_framework.exceptions import PermissionDenied
                        raise PermissionDenied("You don't have access to this chat room")
            
            # Get all unread messages in this room (not from current user)
            unread_messages = Message.objects.filter(
                room=room
            ).exclude(
                user=request.user
            ).exclude(
                read_receipts__user=request.user
            )
            
            # Bulk create read receipts
            read_receipts = [
                ReadReceipt(message=msg, user=request.user)
                for msg in unread_messages
            ]
            ReadReceipt.objects.bulk_create(read_receipts, ignore_conflicts=True)
            
            return Response({
                "marked_count": len(read_receipts)
            }, status=status.HTTP_201_CREATED)
            
        except ChatRoom.DoesNotExist:
            from rest_framework.exceptions import NotFound
            raise NotFound("Chat room not found")


class UnreadCountView(generics.RetrieveAPIView):
    """Get unread message count for a room"""
    permission_classes = [permissions.IsAuthenticated]

    def retrieve(self, request, *args, **kwargs):
        room_id = self.kwargs["room_id"]
        
        try:
            room = ChatRoom.objects.get(id=room_id, is_active=True)
            
            # Verify user has access to this room
            if room.room_type == "personal":
                room_name_parts = room.name.split("_")
                if len(room_name_parts) == 3:
                    user1_id, user2_id = int(room_name_parts[1]), int(room_name_parts[2])
                    if request.user.id not in [user1_id, user2_id]:
                        from rest_framework.exceptions import PermissionDenied
                        raise PermissionDenied("You don't have access to this chat room")
            
            # Count unread messages (not from current user, not read by current user)
            unread_count = Message.objects.filter(
                room=room
            ).exclude(
                user=request.user
            ).exclude(
                read_receipts__user=request.user
            ).count()
            
            return Response({
                "room_id": str(room_id),
                "unread_count": unread_count
            })
            
        except ChatRoom.DoesNotExist:
            from rest_framework.exceptions import NotFound
            raise NotFound("Chat room not found")
