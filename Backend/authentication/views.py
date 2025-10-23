from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from .models import CustomUser
from .serializers import (
    UserRegistrationSerializer,
    UserLoginSerializer,
    UserProfileSerializer,
)


class AuthViewSet(viewsets.GenericViewSet):
    permission_classes = [AllowAny]

    # ADD THIS ONE LINE - Required by DRF ViewSet
    serializer_class = UserRegistrationSerializer

    def list(self, request):
        return Response(
            {
                "message": "Welcome to the Authentication API",
                "available_endpoints": {
                    "register": "/api/auth/register/",
                    "login": "/api/auth/login/",
                    "logout": "/api/auth/logout/",
                    "profile": "/api/auth/profile/",
                    "change_password": "/api/auth/change_password/",
                    "token_refresh": "/api/token/refresh/",
                },
            },
            status=status.HTTP_200_OK,
        )

    @action(detail=False, methods=["post"], permission_classes=[AllowAny])
    def register(self, request):
        serializer = UserRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            refresh = RefreshToken.for_user(user)

            return Response(
                {
                    "success": True,
                    "message": "User registered successfully",
                    "data": {
                        "user": {
                            "id": user.id,
                            "fullName": user.full_name,
                            "email": user.email,
                            "age": user.age,
                            "gender": user.gender,
                            "nationality": user.nationality,
                            "language": user.language,
                        },
                        "tokens": {
                            "refresh": str(refresh),
                            "access": str(refresh.access_token),
                        },
                    },
                },
                status=status.HTTP_201_CREATED,
            )

        return Response(
            {
                "success": False,
                "message": "Registration failed",
                "errors": serializer.errors,
            },
            status=status.HTTP_400_BAD_REQUEST,
        )

    @action(detail=False, methods=["post"], permission_classes=[AllowAny])
    def login(self, request):
        serializer = UserLoginSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.validated_data["user"]
            refresh = RefreshToken.for_user(user)

            return Response(
                {
                    "success": True,
                    "message": "Login successful",
                    "data": {
                        "user": {
                            "id": user.id,
                            "fullName": user.full_name,
                            "email": user.email,
                            "age": user.age,
                            "gender": user.gender,
                            "nationality": user.nationality,
                            "language": user.language,
                            "rememberMe": user.remember_me,
                        },
                        "tokens": {
                            "refresh": str(refresh),
                            "access": str(refresh.access_token),
                        },
                    },
                },
                status=status.HTTP_200_OK,
            )

        return Response(
            {"success": False, "message": "Login failed", "errors": serializer.errors},
            status=status.HTTP_400_BAD_REQUEST,
        )

    @action(detail=False, methods=["post"], permission_classes=[IsAuthenticated])
    def logout(self, request):
        try:
            refresh_token = request.data.get("refresh_token")
            if refresh_token:
                token = RefreshToken(refresh_token)
                token.blacklist()
            return Response(
                {"success": True, "message": "Successfully logged out"},
                status=status.HTTP_205_RESET_CONTENT,
            )
        except Exception as e:
            return Response(
                {"success": False, "message": "Logout failed", "error": str(e)},
                status=status.HTTP_400_BAD_REQUEST,
            )

    @action(
        detail=False,
        methods=["get", "put", "patch"],
        permission_classes=[IsAuthenticated],
    )
    def profile(self, request):
        user = request.user

        if request.method == "GET":
            serializer = UserProfileSerializer(user)
            return Response({"success": True, "data": serializer.data})

        elif request.method in ["PUT", "PATCH"]:
            partial = request.method == "PATCH"
            serializer = UserProfileSerializer(user, data=request.data, partial=partial)
            if serializer.is_valid():
                serializer.save()
                return Response(
                    {
                        "success": True,
                        "message": "Profile updated successfully",
                        "data": serializer.data,
                    }
                )
            return Response(
                {
                    "success": False,
                    "message": "Profile update failed",
                    "errors": serializer.errors,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

    @action(detail=False, methods=["post"], permission_classes=[IsAuthenticated])
    def change_password(self, request):
        user = request.user
        old_password = request.data.get("old_password")
        new_password = request.data.get("new_password")

        if not old_password or not new_password:
            return Response(
                {
                    "success": False,
                    "message": "Both old password and new password are required",
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not user.check_password(old_password):
            return Response(
                {"success": False, "message": "Old password is incorrect"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user.set_password(new_password)
        user.save()

        return Response({"success": True, "message": "Password changed successfully"})
