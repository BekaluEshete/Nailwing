"""
Chat App Tests
Covers: ChatRoom model, Message model, ReadReceipt model,
        ChatRoomList (only matched users), MessageList, CreatePersonalChat,
        MarkMessagesAsRead, MarkRoomAsRead, UnreadCountView, user_search
"""
from datetime import timedelta
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APITestCase
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken

from authentication.models import CustomUser
from chat.models import ChatRoom, Message, UserProfile, ReadReceipt
from flights.models import Flight
from matching.models import Match


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def make_user(email="chat@example.com", password="Pass123!", **kwargs):
    username = kwargs.pop("username", email.split("@")[0])
    return CustomUser.objects.create_user(
        username=username, email=email, password=password,
        first_name="Test", last_name="User", **kwargs,
    )


def make_flight(user, **overrides):
    now = timezone.now()
    defaults = dict(
        flight_number="ET101",
        airline="Ethiopian Airlines",
        departure_airport="ADD",
        departure_city="Addis Ababa",
        arrival_airport="DXB",
        arrival_city="Dubai",
        departure_datetime=now + timedelta(days=3),
        arrival_datetime=now + timedelta(days=3, hours=5),
        is_visible=True,
        open_to_meeting=True,
    )
    defaults.update(overrides)
    return Flight.objects.create(user=user, **defaults)


def make_matched_pair(u1, u2):
    """Create two flights and a matched Match between u1 and u2."""
    f1 = make_flight(u1, flight_number=f"F{u1.id}")
    f2 = make_flight(u2, flight_number=f"F{u2.id}")
    now = timezone.now()
    # Enforce user1 = smaller id
    if u1.id > u2.id:
        u1, u2 = u2, u1
        f1, f2 = f2, f1
    return Match.objects.create(
        user1=u1, user2=u2, flight1=f1, flight2=f2,
        match_type="same_route",
        matching_airport="ADD", matching_city="Addis",
        overlap_start=now + timedelta(hours=1),
        overlap_end=now + timedelta(hours=3),
        overlap_duration_hours=2.0,
        status="matched",
    )


def personal_room_name(u1, u2):
    return f"personal_{min(u1.id, u2.id)}_{max(u1.id, u2.id)}"


def make_personal_room(u1, u2):
    name = personal_room_name(u1, u2)
    return ChatRoom.objects.create(
        name=name,
        description="Test personal chat",
        created_by=u1,
        room_type="personal",
        is_active=True,
    )


def bearer(user):
    return f"Bearer {RefreshToken.for_user(user).access_token}"


# ---------------------------------------------------------------------------
# Unit Tests – ChatRoom Model
# ---------------------------------------------------------------------------

class ChatRoomModelTest(TestCase):

    def setUp(self):
        self.user = make_user()

    def test_str_returns_name(self):
        room = ChatRoom.objects.create(name="general", created_by=self.user)
        self.assertEqual(str(room), "general")

    def test_personal_room_type_auto_set_on_save(self):
        """Rooms named personal_X_Y should auto-set room_type='personal'."""
        u2 = make_user(email="u2@example.com", username="u2")
        name = personal_room_name(self.user, u2)
        room = ChatRoom.objects.create(
            name=name, created_by=self.user, room_type="group"
        )
        room.refresh_from_db()
        self.assertEqual(room.room_type, "personal")

    def test_group_room_type_unchanged(self):
        room = ChatRoom.objects.create(
            name="travelers", created_by=self.user, room_type="group"
        )
        self.assertEqual(room.room_type, "group")

    def test_room_name_is_unique(self):
        ChatRoom.objects.create(name="unique_room", created_by=self.user)
        with self.assertRaises(Exception):
            ChatRoom.objects.create(name="unique_room", created_by=self.user)

    def test_is_active_default_true(self):
        room = ChatRoom.objects.create(name="active_room", created_by=self.user)
        self.assertTrue(room.is_active)


# ---------------------------------------------------------------------------
# Unit Tests – Message Model
# ---------------------------------------------------------------------------

class MessageModelTest(TestCase):

    def setUp(self):
        self.user = make_user()
        self.room = ChatRoom.objects.create(name="msg_room", created_by=self.user)

    def test_create_message(self):
        msg = Message.objects.create(
            room=self.room, user=self.user, content="Hello world"
        )
        self.assertIn("Hello world", str(msg))
        self.assertIn(self.user.username, str(msg))

    def test_message_default_type_is_text(self):
        msg = Message.objects.create(
            room=self.room, user=self.user, content="Hi"
        )
        self.assertEqual(msg.message_type, "text")

    def test_messages_ordered_by_timestamp(self):
        msg1 = Message.objects.create(room=self.room, user=self.user, content="First")
        msg2 = Message.objects.create(room=self.room, user=self.user, content="Second")
        messages = list(Message.objects.filter(room=self.room))
        self.assertEqual(messages[0].id, msg1.id)
        self.assertEqual(messages[1].id, msg2.id)


# ---------------------------------------------------------------------------
# Unit Tests – ReadReceipt Model
# ---------------------------------------------------------------------------

class ReadReceiptModelTest(TestCase):

    def setUp(self):
        self.u1 = make_user(email="rr1@example.com", username="rr1")
        self.u2 = make_user(email="rr2@example.com", username="rr2")
        self.room = ChatRoom.objects.create(name="rr_room", created_by=self.u1)
        self.message = Message.objects.create(
            room=self.room, user=self.u1, content="Did you read this?"
        )

    def test_create_read_receipt(self):
        receipt = ReadReceipt.objects.create(message=self.message, user=self.u2)
        self.assertIn(self.u2.username, str(receipt))

    def test_unique_together_message_user(self):
        ReadReceipt.objects.create(message=self.message, user=self.u2)
        with self.assertRaises(Exception):
            ReadReceipt.objects.create(message=self.message, user=self.u2)


# ---------------------------------------------------------------------------
# Unit Tests – UserProfile Model
# ---------------------------------------------------------------------------

class UserProfileModelTest(TestCase):

    def setUp(self):
        self.user = make_user()

    def test_create_user_profile(self):
        profile = UserProfile.objects.create(user=self.user, online=True)
        self.assertIn(self.user.username, str(profile))
        self.assertTrue(profile.online)

    def test_offline_by_default(self):
        profile = UserProfile.objects.create(user=self.user)
        self.assertFalse(profile.online)


# ---------------------------------------------------------------------------
# Integration Tests – ChatRoom List API
# ---------------------------------------------------------------------------

class ChatRoomListAPITest(APITestCase):

    url = "/chat/api/rooms/"

    def setUp(self):
        self.u1 = make_user(email="crl1@example.com", username="crl1")
        self.u2 = make_user(email="crl2@example.com", username="crl2")
        self.u3 = make_user(email="crl3@example.com", username="crl3")
        self.client.credentials(HTTP_AUTHORIZATION=bearer(self.u1))

    def test_list_rooms_empty_when_no_matches(self):
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 0)

    def test_list_rooms_shows_matched_personal_room(self):
        make_matched_pair(self.u1, self.u2)
        make_personal_room(self.u1, self.u2)
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 1)

    def test_list_rooms_excludes_unmatched_personal_room(self):
        # Room exists but no Match with status='matched'
        make_personal_room(self.u1, self.u3)
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 0)

    def test_list_rooms_unauthenticated_denied(self):
        self.client.credentials()
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)


# ---------------------------------------------------------------------------
# Integration Tests – CreatePersonalChat API
# ---------------------------------------------------------------------------

class CreatePersonalChatAPITest(APITestCase):

    url = "/chat/api/chats/personal/"

    def setUp(self):
        self.u1 = make_user(email="cp1@example.com", username="cp1")
        self.u2 = make_user(email="cp2@example.com", username="cp2")
        self.u3 = make_user(email="cp3@example.com", username="cp3")
        self.client.credentials(HTTP_AUTHORIZATION=bearer(self.u1))

    def test_create_personal_chat_with_matched_user(self):
        make_matched_pair(self.u1, self.u2)
        res = self.client.post(self.url, {"user_id": self.u2.id}, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        room_name = personal_room_name(self.u1, self.u2)
        self.assertTrue(ChatRoom.objects.filter(name=room_name).exists())

    def test_create_personal_chat_is_idempotent(self):
        """Calling it twice returns same room, doesn't create duplicate."""
        make_matched_pair(self.u1, self.u2)
        self.client.post(self.url, {"user_id": self.u2.id}, format="json")
        res = self.client.post(self.url, {"user_id": self.u2.id}, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        room_name = personal_room_name(self.u1, self.u2)
        self.assertEqual(ChatRoom.objects.filter(name=room_name).count(), 1)

    def test_create_personal_chat_without_match_returns_400(self):
        # No Match between u1 and u3
        res = self.client.post(self.url, {"user_id": self.u3.id}, format="json")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_personal_chat_with_pending_match_returns_400(self):
        now = timezone.now()
        f1 = make_flight(self.u1, flight_number="PCF1")
        f3 = make_flight(self.u3, flight_number="PCF3")
        if self.u1.id < self.u3.id:
            u1, u2, f_a, f_b = self.u1, self.u3, f1, f3
        else:
            u1, u2, f_a, f_b = self.u3, self.u1, f3, f1
        Match.objects.create(
            user1=u1, user2=u2, flight1=f_a, flight2=f_b,
            match_type="same_route", matching_airport="ADD",
            matching_city="Addis",
            overlap_start=now + timedelta(hours=1),
            overlap_end=now + timedelta(hours=3),
            overlap_duration_hours=2.0,
            status="connection_requested",  # not 'matched'
        )
        res = self.client.post(self.url, {"user_id": self.u3.id}, format="json")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_personal_chat_nonexistent_user_returns_404(self):
        res = self.client.post(self.url, {"user_id": 99999}, format="json")
        self.assertEqual(res.status_code, status.HTTP_404_NOT_FOUND)

    def test_create_personal_chat_unauthenticated_denied(self):
        self.client.credentials()
        res = self.client.post(self.url, {"user_id": self.u2.id}, format="json")
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)


# ---------------------------------------------------------------------------
# Integration Tests – Message List API
# ---------------------------------------------------------------------------

class MessageListAPITest(APITestCase):

    def setUp(self):
        self.u1 = make_user(email="ml1@example.com", username="ml1")
        self.u2 = make_user(email="ml2@example.com", username="ml2")
        make_matched_pair(self.u1, self.u2)
        self.room = make_personal_room(self.u1, self.u2)
        self.url = f"/chat/api/rooms/{self.room.id}/messages/"
        self.client.credentials(HTTP_AUTHORIZATION=bearer(self.u1))

    def test_list_messages_empty_room(self):
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 0)

    def test_list_messages_returns_existing(self):
        Message.objects.create(room=self.room, user=self.u1, content="Hey!")
        Message.objects.create(room=self.room, user=self.u2, content="Hi!")
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 2)

    def test_create_message_via_http(self):
        res = self.client.post(self.url, {"content": "Hello via HTTP"}, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertTrue(Message.objects.filter(content="Hello via HTTP").exists())

    def test_messages_ordered_oldest_first(self):
        Message.objects.create(room=self.room, user=self.u1, content="First")
        Message.objects.create(room=self.room, user=self.u2, content="Second")
        res = self.client.get(self.url)
        self.assertEqual(res.data[0]["content"], "First")
        self.assertEqual(res.data[1]["content"], "Second")

    def test_message_pagination_limit(self):
        for i in range(10):
            Message.objects.create(room=self.room, user=self.u1, content=f"Msg {i}")
        res = self.client.get(self.url, {"limit": 5, "offset": 0})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 5)

    def test_unauthenticated_denied(self):
        self.client.credentials()
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)


# ---------------------------------------------------------------------------
# Integration Tests – Mark Messages as Read API
# ---------------------------------------------------------------------------

class MarkMessagesAsReadAPITest(APITestCase):

    def setUp(self):
        self.u1 = make_user(email="mr1@example.com", username="mr1")
        self.u2 = make_user(email="mr2@example.com", username="mr2")
        make_matched_pair(self.u1, self.u2)
        self.room = make_personal_room(self.u1, self.u2)
        self.url = f"/chat/api/rooms/{self.room.id}/messages/mark_read/"
        self.client.credentials(HTTP_AUTHORIZATION=bearer(self.u2))

    def test_mark_messages_as_read(self):
        msg1 = Message.objects.create(room=self.room, user=self.u1, content="Read me")
        msg2 = Message.objects.create(room=self.room, user=self.u1, content="Me too")
        res = self.client.post(
            self.url,
            {"message_ids": [str(msg1.id), str(msg2.id)]},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["marked_count"], 2)
        self.assertTrue(ReadReceipt.objects.filter(message=msg1, user=self.u2).exists())
        self.assertTrue(ReadReceipt.objects.filter(message=msg2, user=self.u2).exists())

    def test_own_messages_not_marked_as_read_by_self(self):
        # u2 sends a message, then tries to mark it as read (should be excluded)
        msg = Message.objects.create(room=self.room, user=self.u2, content="My msg")
        res = self.client.post(
            self.url,
            {"message_ids": [str(msg.id)]},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["marked_count"], 0)

    def test_mark_read_idempotent(self):
        msg = Message.objects.create(room=self.room, user=self.u1, content="Once")
        self.client.post(self.url, {"message_ids": [str(msg.id)]}, format="json")
        res = self.client.post(self.url, {"message_ids": [str(msg.id)]}, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        # Should not create duplicate receipts
        self.assertEqual(
            ReadReceipt.objects.filter(message=msg, user=self.u2).count(), 1
        )


# ---------------------------------------------------------------------------
# Integration Tests – Mark Room as Read API
# ---------------------------------------------------------------------------

class MarkRoomAsReadAPITest(APITestCase):

    def setUp(self):
        self.u1 = make_user(email="rr_room1@example.com", username="rrroom1")
        self.u2 = make_user(email="rr_room2@example.com", username="rrroom2")
        make_matched_pair(self.u1, self.u2)
        self.room = make_personal_room(self.u1, self.u2)
        self.url = f"/chat/api/rooms/{self.room.id}/mark_read/"
        self.client.credentials(HTTP_AUTHORIZATION=bearer(self.u2))

    def test_mark_room_as_read(self):
        Message.objects.create(room=self.room, user=self.u1, content="Unread 1")
        Message.objects.create(room=self.room, user=self.u1, content="Unread 2")
        res = self.client.post(self.url)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["marked_count"], 2)

    def test_mark_room_as_read_excludes_own_messages(self):
        Message.objects.create(room=self.room, user=self.u2, content="My own")
        res = self.client.post(self.url)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data["marked_count"], 0)

    def test_nonexistent_room_returns_404(self):
        import uuid
        res = self.client.post(f"/chat/api/rooms/{uuid.uuid4()}/mark_read/")
        self.assertEqual(res.status_code, status.HTTP_404_NOT_FOUND)


# ---------------------------------------------------------------------------
# Integration Tests – Unread Count API
# ---------------------------------------------------------------------------

class UnreadCountAPITest(APITestCase):

    def setUp(self):
        self.u1 = make_user(email="uc1@example.com", username="uc1")
        self.u2 = make_user(email="uc2@example.com", username="uc2")
        make_matched_pair(self.u1, self.u2)
        self.room = make_personal_room(self.u1, self.u2)
        self.url = f"/chat/api/rooms/{self.room.id}/unread_count/"
        self.client.credentials(HTTP_AUTHORIZATION=bearer(self.u2))

    def test_unread_count_zero_initially(self):
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["unread_count"], 0)

    def test_unread_count_increases_with_messages(self):
        Message.objects.create(room=self.room, user=self.u1, content="Unread 1")
        Message.objects.create(room=self.room, user=self.u1, content="Unread 2")
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data["unread_count"], 2)

    def test_unread_count_decreases_after_read(self):
        msg = Message.objects.create(room=self.room, user=self.u1, content="Read me")
        ReadReceipt.objects.create(message=msg, user=self.u2)
        res = self.client.get(self.url)
        self.assertEqual(res.data["unread_count"], 0)


# ---------------------------------------------------------------------------
# Integration Tests – User Search API
# ---------------------------------------------------------------------------

class UserSearchAPITest(APITestCase):

    url = "/chat/api/users/search/"

    def setUp(self):
        self.user = make_user(email="searcher@example.com", username="searcher")
        make_user(email="alice@example.com", username="alice",
                  first_name="Alice", last_name="Wonder")
        make_user(email="bob@example.com", username="bob",
                  first_name="Bob", last_name="Builder")
        self.client.credentials(HTTP_AUTHORIZATION=bearer(self.user))

    def test_search_by_username(self):
        res = self.client.get(self.url, {"q": "alice"})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 1)
        self.assertEqual(res.data[0]["username"], "alice")

    def test_search_by_email(self):
        res = self.client.get(self.url, {"q": "bob@example"})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 1)

    def test_search_excludes_self(self):
        res = self.client.get(self.url, {"q": "searcher"})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        usernames = [u["username"] for u in res.data]
        self.assertNotIn("searcher", usernames)

    def test_search_empty_query_returns_empty(self):
        res = self.client.get(self.url, {"q": ""})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data, [])

    def test_search_unauthenticated_denied(self):
        self.client.credentials()
        res = self.client.get(self.url, {"q": "alice"})
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_search_max_10_results(self):
        for i in range(15):
            make_user(
                email=f"bulk{i}@example.com",
                username=f"bulk{i}",
                first_name="Bulk",
            )
        res = self.client.get(self.url, {"q": "bulk"})
        self.assertLessEqual(len(res.data), 10)
