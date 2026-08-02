from django.db import models
from django.conf import settings
from chapters.models import Chapter


class Capsule(models.Model):

    CAPSULE_TYPES = [
        ("memory", "Memory"),
        ("prediction", "Prediction"),
        ("accountability", "Accountability"),
        ("letter", "Letter"),
    ]


    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="capsules"
    )


    chapter = models.ForeignKey(
        Chapter,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="capsules"
    )

    parent_capsule = models.ForeignKey(
        "self",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="follow_up_capsules"
    )

    reflection_source = models.ForeignKey(
        "reflections.Reflection",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="future_capsules"
    )


    title = models.CharField(
        max_length=255
    )


    message = models.TextField(
        blank=True,
        null=True
    )


    capsule_type = models.CharField(
        max_length=20,
        choices=CAPSULE_TYPES,
        default="memory"
    )


    unlock_date = models.DateTimeField()

    opened_at = models.DateTimeField(
        null=True,
        blank=True
    )

    has_been_opened = models.BooleanField(
        default=False
    )

    recipient_name = models.CharField(
        max_length=100,
        blank=True,
        null=True
    )

    recipient_email = models.EmailField(
        blank=True,
        null=True
    )


    prediction_text = models.TextField(
        blank=True,
        null=True
    )


    prediction_result = models.TextField(
        blank=True,
        null=True
    )


    goal_description = models.TextField(
        blank=True,
        null=True
    )


    goal_completed = models.BooleanField(
        default=False
    )


    goal_completed_date = models.DateTimeField(
        blank=True,
        null=True
    )

    is_delivered = models.BooleanField(
        default=False
    )

    delivered_at = models.DateTimeField(
        blank=True,
        null=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )


    updated_at = models.DateTimeField(
        auto_now=True
    )

    def __str__(self):
        return self.title



class Attachment(models.Model):

    ATTACHMENT_TYPES = [
        ("image", "Image"),
        ("video", "Video"),
        ("audio", "Audio"),
    ]


    capsule = models.ForeignKey(
        Capsule,
        on_delete=models.CASCADE,
        related_name="attachments"
    )


    file = models.FileField(
        upload_to="capsule_attachments/"
    )


    attachment_type = models.CharField(
        max_length=20,
        choices=ATTACHMENT_TYPES
    )


    uploaded_at = models.DateTimeField(
        auto_now_add=True
    )


    def __str__(self):
        return f"{self.capsule.title} attachment"