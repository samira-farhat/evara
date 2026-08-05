from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import User


admin.site.register(User, UserAdmin)

from django.contrib import admin
from .models import NotificationSettings


@admin.register(NotificationSettings)
class NotificationSettingsAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "email_notifications",
        "push_notifications",
        "reminders",
    )