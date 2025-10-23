from django.contrib.auth.backends import ModelBackend
from .models import CustomUser


class EmailBackend(ModelBackend):
    def authenticate(self, request, username=None, password=None, **kwargs):
        email = kwargs.get("email", username)
        try:
            user = CustomUser.objects.get(email__iexact=email)  # Case-insensitive
            if user.check_password(password) and self.user_can_authenticate(user):
                return user
        except CustomUser.DoesNotExist:
            return None
