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
        detail=True,
        methods=["get"],
        permission_classes=[IsAuthenticated],
    )
    def user_profile(self, request, pk=None):
        """Get user profile by ID"""
        try:
            user = CustomUser.objects.get(id=pk)
            serializer = UserProfileSerializer(user, context={"request": request})
            return Response({"success": True, "data": serializer.data})
        except CustomUser.DoesNotExist:
            return Response(
                {"success": False, "error": "User not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

    @action(
        detail=True,
        methods=["get"],
        permission_classes=[IsAuthenticated],
        url_path="user_profile",
    )
    def user_profile(self, request, pk=None):
        """Get user profile by ID"""
        try:
            user = CustomUser.objects.get(id=pk)
            serializer = UserProfileSerializer(user, context={"request": request})
            return Response({"success": True, "data": serializer.data})
        except CustomUser.DoesNotExist:
            return Response(
                {"success": False, "error": "User not found"},
                status=status.HTTP_404_NOT_FOUND,
            )

    @action(
        detail=False,
        methods=["get", "put", "patch"],
        permission_classes=[IsAuthenticated],
    )
    def profile(self, request):
        user = request.user

        if request.method == "GET":
            serializer = UserProfileSerializer(user, context={"request": request})
            return Response({"success": True, "data": serializer.data})

        elif request.method in ["PUT", "PATCH"]:
            from .cloudinary_service import upload_profile_image, delete_profile_image

            partial = request.method == "PATCH"

            # Handle profile image upload to Cloudinary
            profile_image = request.FILES.get("profileImage")
            if profile_image:
                # Delete old image from Cloudinary if exists
                if user.cloudinary_public_id:
                    delete_profile_image(user.cloudinary_public_id)

                # Upload new image to Cloudinary
                upload_result = upload_profile_image(profile_image, user.id)

                if upload_result["success"]:
                    # Store Cloudinary URL instead of local file
                    user.profile_image_url = upload_result["url"]
                    user.cloudinary_public_id = upload_result["public_id"]
                    user.save(
                        update_fields=["profile_image_url", "cloudinary_public_id"]
                    )
                else:
                    return Response(
                        {
                            "success": False,
                            "message": "Failed to upload image",
                            "error": upload_result.get("error", "Unknown error"),
                        },
                        status=status.HTTP_400_BAD_REQUEST,
                    )

            # Prepare data for serializer - convert fullName to fullNameInput
            # Handle both form data (QueryDict) and regular dict
            if hasattr(request.data, "dict"):
                serializer_data = request.data.dict()
            else:
                serializer_data = dict(request.data)

            # Remove file field from serializer data (handled separately)
            serializer_data.pop("profileImage", None)

            # Convert fullName to fullNameInput for serializer
            if "fullName" in serializer_data:
                serializer_data["fullNameInput"] = serializer_data.pop("fullName")

            # Update other profile fields
            serializer = UserProfileSerializer(
                user,
                data=serializer_data,
                partial=partial,
                context={"request": request},
            )
            if serializer.is_valid():
                serializer.save()
                # Refresh user to get updated data
                user.refresh_from_db()
                updated_serializer = UserProfileSerializer(
                    user, context={"request": request}
                )
                return Response(
                    {
                        "success": True,
                        "message": "Profile updated successfully",
                        "data": updated_serializer.data,
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
