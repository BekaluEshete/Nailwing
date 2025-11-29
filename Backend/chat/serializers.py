from rest_framework import serializers
from authentication.models import CustomUser
from .models import ChatRoom, Message, UserProfile


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
        )

    def get_member_count(self, obj):
        # Implement based on your room membership logic
        return 1


class MessageSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    room = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = Message
        fields = ("id", "room", "user", "content", "timestamp", "message_type")
