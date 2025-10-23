from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser


@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    model = CustomUser
    list_display = (
        "email",
        "username",
        "first_name",
        "last_name",
        "is_staff",
        "is_active",
    )
    list_filter = ("is_staff", "is_active", "gender", "nationality")
    search_fields = ("email", "username", "first_name", "last_name")
    ordering = ("email",)

    fieldsets = UserAdmin.fieldsets + (
        (
            "Additional Information",
            {
                "fields": (
                    "age",
                    "gender",
                    "nationality",
                    "language",
                    "profile_image",
                    "remember_me",
                )
            },
        ),
    )

    add_fieldsets = UserAdmin.add_fieldsets + (
        (
            "Additional Information",
            {
                "fields": (
                    "email",
                    "age",
                    "gender",
                    "nationality",
                    "language",
                    "profile_image",
                    "remember_me",
                )
            },
        ),
    )


# Optional: Customize admin site header
admin.site.site_header = "Nailwing Administration"
admin.site.site_title = "Nailwing Admin Portal"
admin.site.index_title = "Welcome to Nailwing Admin Portal"
