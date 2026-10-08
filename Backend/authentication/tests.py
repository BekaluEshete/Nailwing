"""
Authentication App Tests
Covers: registration, login, logout, profile CRUD, change_password, email backend
"""
from django.test import TestCase, override_settings
from django.urls import reverse
from rest_framework.test import APITestCase, APIClient
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from authentication.models import CustomUser
from authentication.backends import EmailBackend
from authentication.serializers import (
    UserRegistrationSerializer,
    UserLoginSerializer,
    UserProfileSerializer,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def make_user(email="test@example.com", password="StrongPass123!", **kwargs):
    """Create a test user with sensible defaults."""
    username = kwargs.pop("username", email.split("@")[0])
    return CustomUser.objects.create_user(
        username=username,
        email=email,
        password=password,
        first_name=kwargs.pop("first_name", "Test"),
        last_name=kwargs.pop("last_name", "User"),
        **kwargs,
    )


def auth_header(user):
    """Return Authorization header dict for a user."""
    refresh = RefreshToken.for_user(user)
    return {"HTTP_AUTHORIZATION": f"Bearer {refresh.access_token}"}


# ---------------------------------------------------------------------------
# Unit Tests – Model
# ---------------------------------------------------------------------------

class CustomUserModelTest(TestCase):

    def test_full_name_property(self):
        user = make_user(first_name="John", last_name="Doe")
        self.assertEqual(user.full_name, "John Doe")

    def test_full_name_no_last_name(self):
        user = make_user(first_name="Solo", last_name="")
        self.assertEqual(user.full_name, "Solo")

    def test_str_returns_email(self):
        user = make_user(email="jane@example.com")
        self.assertEqual(str(user), "jane@example.com")

    def test_email_is_unique(self):
        make_user(email="dup@example.com", username="dup1")
        with self.assertRaises(Exception):
            make_user(email="dup@example.com", username="dup2")

    def test_default_fields(self):
        user = make_user()
        self.assertIsNone(user.age)
        self.assertIsNone(user.gender)
        self.assertIsNone(user.nationality)
        self.assertFalse(user.remember_me)


# ---------------------------------------------------------------------------
# Unit Tests – Email Backend
# ---------------------------------------------------------------------------

class EmailBackendTest(TestCase):

    def setUp(self):
        self.user = make_user(email="backend@example.com", password="Pass123!")
        self.backend = EmailBackend()

    def test_authenticate_valid_credentials(self):
        user = self.backend.authenticate(None, email="backend@example.com", password="Pass123!")
        self.assertIsNotNone(user)
        self.assertEqual(user.email, "backend@example.com")

    def test_authenticate_case_insensitive_email(self):
        user = self.backend.authenticate(None, email="BACKEND@EXAMPLE.COM", password="Pass123!")
        self.assertIsNotNone(user)

    def test_authenticate_wrong_password(self):
        user = self.backend.authenticate(None, email="backend@example.com", password="wrong")
        self.assertIsNone(user)

    def test_authenticate_nonexistent_email(self):
        user = self.backend.authenticate(None, email="nobody@example.com", password="Pass123!")
        self.assertIsNone(user)

    def test_authenticate_inactive_user(self):
        self.user.is_active = False
        self.user.save()
        user = self.backend.authenticate(None, email="backend@example.com", password="Pass123!")
        self.assertIsNone(user)


# ---------------------------------------------------------------------------
# Unit Tests – Serializers
# ---------------------------------------------------------------------------

class UserRegistrationSerializerTest(TestCase):

    def _valid_data(self, **overrides):
        data = {
            "fullName": "Alice Smith",
            "email": "alice@example.com",
            "password": "StrongPass123!",
            "password2": "StrongPass123!",
            "age": "25",
            "gender": "female",
            "nationality": "Ethiopian",
            "language": "Amharic",
        }
        data.update(overrides)
        return data

    def test_valid_registration(self):
        s = UserRegistrationSerializer(data=self._valid_data())
        self.assertTrue(s.is_valid(), s.errors)
        user = s.save()
        self.assertEqual(user.email, "alice@example.com")
        self.assertEqual(user.first_name, "Alice")
        self.assertEqual(user.last_name, "Smith")
        self.assertEqual(user.age, 25)

    def test_password_mismatch(self):
        s = UserRegistrationSerializer(data=self._valid_data(password2="Different1!"))
        self.assertFalse(s.is_valid())
        self.assertIn("password", s.errors)

    def test_invalid_age(self):
        s = UserRegistrationSerializer(data=self._valid_data(age="notanumber"))
        self.assertFalse(s.is_valid())
        self.assertIn("age", s.errors)

    def test_username_auto_generated_from_email(self):
        s = UserRegistrationSerializer(data=self._valid_data())
        s.is_valid()
        user = s.save()
        self.assertEqual(user.username, "alice")

    def test_missing_email_fails(self):
        data = self._valid_data()
        del data["email"]
        s = UserRegistrationSerializer(data=data)
        self.assertFalse(s.is_valid())


class UserLoginSerializerTest(TestCase):

    def setUp(self):
        self.user = make_user(email="login@example.com", password="Pass123!")

    def test_valid_login(self):
        s = UserLoginSerializer(data={"email": "login@example.com", "password": "Pass123!"})
        self.assertTrue(s.is_valid(), s.errors)
        self.assertEqual(s.validated_data["user"], self.user)

    def test_wrong_password(self):
        s = UserLoginSerializer(data={"email": "login@example.com", "password": "wrong"})
        self.assertFalse(s.is_valid())

    def test_remember_me_saved(self):
        s = UserLoginSerializer(
            data={"email": "login@example.com", "password": "Pass123!", "rememberMe": True}
        )
        s.is_valid()
        s.validated_data["user"].refresh_from_db()
        self.assertTrue(s.validated_data["user"].remember_me)


# ---------------------------------------------------------------------------
# Integration Tests – Registration API
# ---------------------------------------------------------------------------

class RegistrationAPITest(APITestCase):

    url = "/api/auth/register/"

    def _valid_payload(self, **overrides):
        data = {
            "fullName": "Bob Jones",
            "email": "bob@example.com",
            "password": "StrongPass123!",
            "password2": "StrongPass123!",
        }
        data.update(overrides)
        return data

    def test_register_success(self):
        res = self.client.post(self.url, self._valid_payload(), format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertTrue(res.data["success"])
        self.assertIn("access", res.data["data"]["tokens"])
        self.assertIn("refresh", res.data["data"]["tokens"])

    def test_register_creates_user_in_db(self):
        self.client.post(self.url, self._valid_payload(), format="json")
        self.assertTrue(CustomUser.objects.filter(email="bob@example.com").exists())

    def test_register_duplicate_email(self):
        self.client.post(self.url, self._valid_payload(), format="json")
        res = self.client.post(self.url, self._valid_payload(), format="json")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(res.data["success"])

    def test_register_password_mismatch(self):
        res = self.client.post(
            self.url,
            self._valid_payload(password2="DoesNotMatch1!"),
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_register_missing_required_fields(self):
        res = self.client.post(self.url, {"email": "incomplete@example.com"}, format="json")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_register_returns_user_data(self):
        res = self.client.post(self.url, self._valid_payload(), format="json")
        user_data = res.data["data"]["user"]
        self.assertEqual(user_data["email"], "bob@example.com")
        self.assertIn("fullName", user_data)


# ---------------------------------------------------------------------------
# Integration Tests – Login API
# ---------------------------------------------------------------------------

class LoginAPITest(APITestCase):

    url = "/api/auth/login/"

    def setUp(self):
        self.user = make_user(email="loginapi@example.com", password="Pass123!")

    def test_login_success(self):
        res = self.client.post(
            self.url,
            {"email": "loginapi@example.com", "password": "Pass123!"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data["success"])
        self.assertIn("access", res.data["data"]["tokens"])

    def test_login_wrong_password(self):
        res = self.client.post(
            self.url,
            {"email": "loginapi@example.com", "password": "wrong"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(res.data["success"])

    def test_login_nonexistent_email(self):
        res = self.client.post(
            self.url,
            {"email": "nobody@example.com", "password": "Pass123!"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_login_case_insensitive_email(self):
        res = self.client.post(
            self.url,
            {"email": "LOGINAPI@EXAMPLE.COM", "password": "Pass123!"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)

    def test_login_remember_me(self):
        res = self.client.post(
            self.url,
            {"email": "loginapi@example.com", "password": "Pass123!", "rememberMe": True},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertTrue(self.user.remember_me)

    def test_login_inactive_user(self):
        self.user.is_active = False
        self.user.save()
        res = self.client.post(
            self.url,
            {"email": "loginapi@example.com", "password": "Pass123!"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)


# ---------------------------------------------------------------------------
# Integration Tests – Profile API
# ---------------------------------------------------------------------------

class ProfileAPITest(APITestCase):

    url = "/api/auth/profile/"

    def setUp(self):
        self.user = make_user(
            email="profile@example.com",
            password="Pass123!",
            first_name="John",
            last_name="Doe",
        )
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {RefreshToken.for_user(self.user).access_token}"
        )

    def test_get_profile(self):
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data["success"])
        self.assertEqual(res.data["data"]["email"], "profile@example.com")

    def test_get_profile_unauthenticated(self):
        self.client.credentials()
        res = self.client.get(self.url)
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_patch_profile_name(self):
        res = self.client.patch(self.url, {"fullName": "Jane Smith"}, format="json")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertEqual(self.user.first_name, "Jane")
        self.assertEqual(self.user.last_name, "Smith")

    def test_patch_profile_nationality(self):
        res = self.client.patch(self.url, {"nationality": "Ethiopian"}, format="json")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertEqual(self.user.nationality, "Ethiopian")

    def test_patch_profile_empty_nationality_sets_none(self):
        self.user.nationality = "Ethiopian"
        self.user.save()
        res = self.client.patch(self.url, {"nationality": ""}, format="json")
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertIsNone(self.user.nationality)


# ---------------------------------------------------------------------------
# Integration Tests – Change Password API
# ---------------------------------------------------------------------------

class ChangePasswordAPITest(APITestCase):

    url = "/api/auth/change_password/"

    def setUp(self):
        self.user = make_user(email="changepw@example.com", password="OldPass123!")
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {RefreshToken.for_user(self.user).access_token}"
        )

    def test_change_password_success(self):
        res = self.client.post(
            self.url,
            {"old_password": "OldPass123!", "new_password": "NewPass456!"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password("NewPass456!"))

    def test_change_password_wrong_old(self):
        res = self.client.post(
            self.url,
            {"old_password": "WrongOld!", "new_password": "NewPass456!"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_change_password_missing_fields(self):
        res = self.client.post(self.url, {"old_password": "OldPass123!"}, format="json")
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)

    def test_change_password_unauthenticated(self):
        self.client.credentials()
        res = self.client.post(
            self.url,
            {"old_password": "OldPass123!", "new_password": "NewPass456!"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)


# ---------------------------------------------------------------------------
# Integration Tests – Rate Limiting (Throttling)
# ---------------------------------------------------------------------------

class AuthThrottleTest(APITestCase):
    """
    Verify that throttle classes are correctly wired for login and register.
    We test the wiring (correct throttle returned) rather than the rate limit
    itself, since DRF throttle rates are set at class-load time and cannot be
    reliably overridden mid-test in all environments.
    """

    def setUp(self):
        from django.core.cache import cache
        cache.clear()

    def test_register_action_uses_scoped_throttle_when_configured(self):
        """When the auth scope is configured, register returns ScopedRateThrottle."""
        from rest_framework.throttling import ScopedRateThrottle
        from authentication.views import AuthViewSet
        from unittest.mock import MagicMock

        view = AuthViewSet()
        view.action = "register"
        view.request = MagicMock()

        with self.settings(REST_FRAMEWORK={
            "DEFAULT_AUTHENTICATION_CLASSES": (
                "rest_framework_simplejwt.authentication.JWTAuthentication",
            ),
            "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.AllowAny",),
            "DEFAULT_THROTTLE_CLASSES": [
                "rest_framework.throttling.AnonRateThrottle",
            ],
            "DEFAULT_THROTTLE_RATES": {
                "anon": "20/minute",
                "user": "200/minute",
                "auth": "5/minute",
                "matching": "10/minute",
            },
        }):
            throttles = view.get_throttles()

        self.assertTrue(any(isinstance(t, ScopedRateThrottle) for t in throttles))

    def test_login_action_uses_scoped_throttle_when_configured(self):
        """When the auth scope is configured, login returns ScopedRateThrottle."""
        from rest_framework.throttling import ScopedRateThrottle
        from authentication.views import AuthViewSet
        from unittest.mock import MagicMock

        view = AuthViewSet()
        view.action = "login"
        view.request = MagicMock()

        with self.settings(REST_FRAMEWORK={
            "DEFAULT_AUTHENTICATION_CLASSES": (
                "rest_framework_simplejwt.authentication.JWTAuthentication",
            ),
            "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.AllowAny",),
            "DEFAULT_THROTTLE_CLASSES": [],
            "DEFAULT_THROTTLE_RATES": {
                "auth": "5/minute",
            },
        }):
            throttles = view.get_throttles()

        self.assertTrue(any(isinstance(t, ScopedRateThrottle) for t in throttles))

    def test_profile_action_does_not_use_scoped_throttle(self):
        """Non-auth actions should not get the auth scoped throttle."""
        from rest_framework.throttling import ScopedRateThrottle
        from authentication.views import AuthViewSet
        from unittest.mock import MagicMock

        view = AuthViewSet()
        view.action = "profile"
        view.request = MagicMock()

        throttles = view.get_throttles()
        self.assertFalse(any(isinstance(t, ScopedRateThrottle) for t in throttles))

    def test_normal_login_under_limit_succeeds(self):
        """A single login attempt is never throttled (throttling disabled in test_settings)."""
        make_user(email="normal_login@example.com", password="Pass123!")
        res = self.client.post(
            "/api/auth/login/",
            {"email": "normal_login@example.com", "password": "Pass123!"},
            format="json",
        )
        self.assertNotEqual(res.status_code, 429)
        self.assertEqual(res.status_code, 200)
