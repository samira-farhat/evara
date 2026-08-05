from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):

    email = models.EmailField(unique=True)

    profile_picture = models.ImageField(
        upload_to="profile_pictures/",
        null=True,
        blank=True
    )

    is_email_verified = models.BooleanField(
        default=False
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )


    def __str__(self):
        return self.username


import random
from datetime import timedelta
from django.utils import timezone


class OTP(models.Model):

    OTP_TYPES = (
        ("verification", "Verification"),
        ("password_reset", "Password Reset"),
    )

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="otps"
    )

    code = models.CharField(
        max_length=6
    )

    otp_type = models.CharField(
        max_length=20,
        choices=OTP_TYPES,
        default="verification"
    )

    verified = models.BooleanField(
        default=False
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    expires_at = models.DateTimeField()


    def is_expired(self):
        return timezone.now() > self.expires_at


    @staticmethod
    def generate_code():

        return str(
            random.randint(
                100000,
                999999
            )
        )


    def __str__(self):
        return self.code


class NotificationSettings(models.Model):

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="notification_settings"
    )

    email_notifications = models.BooleanField(
        default=True
    )

    push_notifications = models.BooleanField(
        default=True
    )

    reminders = models.BooleanField(
        default=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    updated_at = models.DateTimeField(
        auto_now=True
    )


    def __str__(self):
        return f"{self.user.username} notification settings"