from rest_framework import serializers
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from .models import CustomUser


class UserRegistrationSerializer(serializers.ModelSerializer):
    fullName = serializers.CharField(write_only=True)
    password = serializers.CharField(write_only=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True)
    age = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    profileImage = serializers.ImageField(required=False, allow_null=True)

    nationality = serializers.CharField(
        required=False, allow_blank=True, allow_null=True
    )
    language = serializers.CharField(required=False, allow_blank=True, allow_null=True)

    class Meta:
        model = CustomUser
        fields = (
            "fullName",
            "age",
            "gender",
            "email",
            "password",
            "password2",
            "nationality",
            "language",
            "profileImage",
        )

    def validate(self, attrs):
        if attrs["password"] != attrs["password2"]:
            raise serializers.ValidationError(
                {"password": "Password fields didn't match."}
            )

        if attrs.get("age"):
            try:
                int(attrs["age"])
            except ValueError:
                raise serializers.ValidationError(
                    {"age": "Age must be a valid number."}
                )

        return attrs

    def create(self, validated_data):
        full_name = validated_data.pop("fullName")
        name_parts = full_name.split(" ", 1)
        first_name = name_parts[0]
        last_name = name_parts[1] if len(name_parts) > 1 else ""

        validated_data.pop("password2")
        profile_image = validated_data.pop("profileImage", None)
        password = validated_data.pop("password")
        email = validated_data.pop("email")

        # ✅ Auto-generate username from email (e.g. "user@example.com" -> "user")
        username = email.split("@")[0]

        age = validated_data.pop("age", None)
        if age and age != "":
            validated_data["age"] = int(age)
        else:
            validated_data["age"] = None

        # ✅ Pass username explicitly
        user = CustomUser.objects.create_user(
            username=username,
            first_name=first_name,
            last_name=last_name,
            email=email,
            password=password,
            **validated_data,
        )

        if profile_image:
            user.profile_image = profile_image
            user.save()

        return user


class UserLoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField()
    rememberMe = serializers.BooleanField(default=False)

    def validate(self, attrs):
        email = attrs.get("email")
        password = attrs.get("password")
        remember_me = attrs.get("rememberMe", False)

        if email and password:
            user = authenticate(
                request=self.context.get("request"), email=email, password=password
            )
            if not user:
                raise serializers.ValidationError("Invalid email or password")
            if not user.is_active:
                raise serializers.ValidationError("User account is disabled")

            user.remember_me = remember_me
            user.save(update_fields=["remember_me"])

            attrs["user"] = user
            return attrs

        raise serializers.ValidationError('Must include "email" and "password"')


class UserProfileSerializer(serializers.ModelSerializer):
    fullName = serializers.SerializerMethodField()
    profileImage = serializers.SerializerMethodField()
    profileImageUrl = serializers.URLField(
        source="profile_image_url", read_only=True
    )
    rememberMe = serializers.BooleanField(source="remember_me")

    class Meta:
        model = CustomUser
        fields = (
            "id",
            "fullName",
            "email",
            "age",
            "gender",
            "nationality",
            "language",
            "profileImage",
            "profileImageUrl",
            "rememberMe",
            "date_joined",
        )
        extra_kwargs = {
            "nationality": {"required": False, "allow_blank": True},
            "language": {"required": False, "allow_blank": True},
        }

    def get_fullName(self, obj):
        return obj.full_name

    def get_profileImage(self, obj):
        # Return Cloudinary URL if available, otherwise local image URL
        if obj.profile_image_url:
            return obj.profile_image_url
        if obj.profile_image:
            request = self.context.get("request")
            if request:
                return request.build_absolute_uri(obj.profile_image.url)
        return None

    def update(self, instance, validated_data):
        # profile_image is handled separately in views.py for Cloudinary upload
        profile_image = validated_data.pop("profile_image", None)

        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        # Only update local profile_image if Cloudinary URL is not set
        if profile_image is not None and not instance.profile_image_url:
            instance.profile_image = profile_image

        instance.save()
        return instance
