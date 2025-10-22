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

    # No restrictions on nationality and language - free text input
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

        # Convert age to integer if provided and not empty
        if attrs.get("age"):
            try:
                int(attrs["age"])
            except ValueError:
                raise serializers.ValidationError(
                    {"age": "Age must be a valid number."}
                )

        # Allow any value for nationality and language - no validation needed

        return attrs

    def create(self, validated_data):
        # Split fullName into first_name and last_name
        full_name = validated_data.pop("fullName")
        name_parts = full_name.split(" ", 1)
        first_name = name_parts[0]
        last_name = name_parts[1] if len(name_parts) > 1 else ""

        # Remove password2 and rename profileImage
        validated_data.pop("password2")
        profile_image = validated_data.pop("profileImage", None)

        # Convert age to integer if provided
        age = validated_data.pop("age", None)
        if age and age != "":
            validated_data["age"] = int(age)
        else:
            validated_data["age"] = None

        # Nationality and language are stored as provided - no changes needed

        # Create user
        user = CustomUser.objects.create_user(
            first_name=first_name, last_name=last_name, **validated_data
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
            # Since we're using email as username, we need to find the user by email
            try:
                user = CustomUser.objects.get(email=email)
                user = authenticate(username=user.username, password=password)
            except CustomUser.DoesNotExist:
                user = None

            if not user:
                raise serializers.ValidationError("Invalid email or password")
            if not user.is_active:
                raise serializers.ValidationError("User account is disabled")

            # Update remember_me field
            user.remember_me = remember_me
            user.save(update_fields=["remember_me"])

            attrs["user"] = user
            return attrs
        raise serializers.ValidationError('Must include "email" and "password"')


class UserProfileSerializer(serializers.ModelSerializer):
    fullName = serializers.SerializerMethodField()
    profileImage = serializers.ImageField(
        source="profile_image", required=False, allow_null=True
    )
    rememberMe = serializers.BooleanField(source="remember_me")

    # No restrictions - allow any text input
    nationality = serializers.CharField(
        required=False, allow_blank=True, allow_null=True
    )
    language = serializers.CharField(required=False, allow_blank=True, allow_null=True)

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
            "rememberMe",
            "date_joined",
        )
        extra_kwargs = {
            "nationality": {"required": False, "allow_blank": True},
            "language": {"required": False, "allow_blank": True},
        }

    def get_fullName(self, obj):
        return obj.full_name

    def update(self, instance, validated_data):
        # Handle profile image separately if needed
        profile_image = validated_data.pop("profile_image", None)

        # Update all other fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)

        if profile_image is not None:
            instance.profile_image = profile_image

        instance.save()
        return instance
