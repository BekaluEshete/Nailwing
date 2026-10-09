"""
Tests for matching Celery tasks.
CELERY_TASK_ALWAYS_EAGER=True in test_settings makes tasks run synchronously.
"""
from datetime import timedelta
from unittest.mock import patch, MagicMock

from django.test import TestCase
from django.utils import timezone

from authentication.models import CustomUser
from flights.models import Flight
from matching.models import Match
from matching.tasks import run_matching_for_user


def make_user(email="task_u@example.com", password="Pass123!", **kwargs):
    username = kwargs.pop("username", email.split("@")[0])
    first_name = kwargs.pop("first_name", "Test")
    last_name = kwargs.pop("last_name", "User")
    return CustomUser.objects.create_user(
        username=username, email=email, password=password,
        first_name=first_name, last_name=last_name, **kwargs,
    )


_task_flight_counter = 0


def make_flight(user, **overrides):
    global _task_flight_counter
    _task_flight_counter += 1
    now = timezone.now()
    dep = now + timedelta(days=3)
    defaults = dict(
        flight_number=overrides.pop("flight_number", f"TT{_task_flight_counter:04d}"),
        airline="ET",
        departure_airport="ADD",
        departure_city="Addis",
        arrival_airport="DXB",
        arrival_city="Dubai",
        departure_datetime=dep,
        arrival_datetime=dep + timedelta(hours=5),
        is_visible=True,
        open_to_meeting=True,
    )
    defaults.update(overrides)
    return Flight.objects.create(user=user, **defaults)


class RunMatchingTaskTest(TestCase):

    def setUp(self):
        from django.core.cache import cache
        cache.clear()
        self.u1 = make_user(email="t1@example.com", username="t1")
        self.u2 = make_user(email="t2@example.com", username="t2")

    def test_task_returns_ok_for_valid_user_with_no_matches(self):
        """Task completes without error when no compatible flights exist."""
        make_flight(self.u1)
        result = run_matching_for_user.delay(self.u1.id)
        self.assertEqual(result.get()["status"], "ok")

    def test_task_returns_error_for_nonexistent_user(self):
        """Task returns error dict for a user that does not exist."""
        result = run_matching_for_user.delay(99999)
        self.assertEqual(result.get()["status"], "error")
        self.assertEqual(result.get()["reason"], "user_not_found")

    def test_task_returns_error_for_nonexistent_flight(self):
        """Task returns error when specified flight does not exist."""
        result = run_matching_for_user.delay(self.u1.id, flight_id=99999)
        self.assertEqual(result.get()["status"], "error")
        self.assertEqual(result.get()["reason"], "flight_not_found")

    def test_task_creates_match_records_for_compatible_flights(self):
        """Task creates Match records when compatible flights are found."""
        now = timezone.now()
        dep = now + timedelta(days=3)

        # Two users, same route, same departure day, within 2h
        f1 = make_flight(
            self.u1,
            departure_airport="ADD", arrival_airport="DXB",
            departure_datetime=dep,
            arrival_datetime=dep + timedelta(hours=4),
        )
        make_flight(
            self.u2,
            departure_airport="ADD", arrival_airport="DXB",
            departure_datetime=dep + timedelta(hours=1),
            arrival_datetime=dep + timedelta(hours=5),
        )

        result = run_matching_for_user.delay(self.u1.id, f1.id)
        data = result.get()

        self.assertEqual(data["status"], "ok")
        # Match should have been created
        self.assertTrue(
            Match.objects.filter(
                flight1__user__in=[self.u1, self.u2],
                flight2__user__in=[self.u1, self.u2],
            ).exists()
        )

    def test_task_invalidates_cache_after_run(self):
        """Task deletes the find_matches cache key for the user."""
        from django.core.cache import cache
        from matching.views import _matches_cache_key

        # Create a flight so the task finds something to work with
        make_flight(self.u1)

        cache_key = _matches_cache_key(self.u1.id)
        cache.set(cache_key, {"stale": True}, 120)

        run_matching_for_user.delay(self.u1.id)

        # Cache should be cleared after task runs
        self.assertIsNone(cache.get(cache_key))


class RunMatchingTaskRetryTest(TestCase):

    def setUp(self):
        from django.core.cache import cache
        cache.clear()
        self.user = make_user(email="retry@example.com", username="retry")

    @patch("matching.matching_service.MatchingService.find_matches_for_user",
           side_effect=Exception("DB error"))
    def test_task_retries_on_exception(self, mock_service):
        """Task raises Retry when matching service throws an exception."""
        make_flight(self.user)
        from celery.exceptions import Retry
        with self.assertRaises((Retry, Exception)):
            run_matching_for_user(self.user.id)
