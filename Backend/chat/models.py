from django.db import models
from authentication.models import CustomUser
import uuid


class ChatRoom(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True, null=True)
    created_by = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)

    # ✅ CORRECT INDENTATION - class field, not inside method
    room_type = models.CharField(
        max_length=20,
        default="group",
        choices=[
            ("group", "Group Chat"),
            ("personal", "Personal Chat"),
        ],
    )

    def __str__(self):
        return self.name

    # Update the save method to auto-detect room type
    def save(self, *args, **kwargs):
        if self.name.startswith("personal_"):
            self.room_type = "personal"
        super().save(*args, **kwargs)


class Message(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    room = models.ForeignKey(
        ChatRoom, on_delete=models.CASCADE, related_name="messages"
    )
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    message_type = models.CharField(
        max_length=20,
        default="text",
        choices=[
            ("text", "Text"),
            ("image", "Image"),
            ("file", "File"),
            ("flight", "Flight Information"),
            ("location", "Location"),
        ],
    )
    # Idempotency key sent by the client.
    # The Flutter app assigns a UUID before sending; on retry the same UUID is
    # sent again. The backend uses get_or_create on this field so duplicate
    # sends never produce duplicate messages.
    client_msg_id = models.UUIDField(
        null=True,
        blank=True,
        unique=True,
        db_index=True,
        help_text="Client-generated UUID for idempotent message delivery.",
    )

    class Meta:
        ordering = ["timestamp"]

    def __str__(self):
        return f"{self.user.username}: {self.content[:20]}"


class UserProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE)
    online = models.BooleanField(default=False)
    last_seen = models.DateTimeField(auto_now=True)
    avatar = models.ImageField(upload_to="avatars/", null=True, blank=True)

    def __str__(self):
        return f"{self.user.username} Profile"


class ReadReceipt(models.Model):
    """Track which messages have been read by which users"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    message = models.ForeignKey(Message, on_delete=models.CASCADE, related_name="read_receipts")
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    read_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [["message", "user"]]  # A user can only read a message once
        ordering = ["-read_at"]

    def __str__(self):
        return f"{self.user.username} read message {self.message.id}"
