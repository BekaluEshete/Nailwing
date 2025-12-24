from rest_framework import serializers
from authentication.models import CustomUser
from .models import ChatRoom, Message, UserProfile, ReadReceipt


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ("id", "username", "email", "first_name", "last_name")


class UserProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = UserProfile
        fields = ("user", "online", "last_seen", "avatar")


class ChatRoomSerializer(serializers.ModelSerializer):
    created_by = UserSerializer(read_only=True)
    member_count = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()

    class Meta:
        model = ChatRoom
        fields = (
            "id",
            "name",
            "description",
            "created_by",
            "created_at",
            "member_count",
            "is_active",
            "unread_count",
        )

    def get_member_count(self, obj):
        # Implement based on your room membership logic
        return 1
    
    def get_unread_count(self, obj):
        """Calculate unread message count for current user"""
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            from .models import Message, ReadReceipt
            # Count messages in this room that:
            # 1. Are not from the current user
            # 2. Don't have a read receipt from the current user
            unread_count = Message.objects.filter(
                room=obj
            ).exclude(
                user=request.user
            ).exclude(
                read_receipts__user=request.user
            ).count()
            return unread_count
        return 0


class MessageSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    room = serializers.PrimaryKeyRelatedField(read_only=True)
    is_read = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = ("id", "room", "user", "content", "timestamp", "message_type", "is_read")
    
    def get_is_read(self, obj):
        """Check if current user has read this message"""
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            from .models import ReadReceipt
            return ReadReceipt.objects.filter(message=obj, user=request.user).exists()
        return False


class ReadReceiptSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    message = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = ReadReceipt
        fields = ("id", "message", "user", "read_at")
