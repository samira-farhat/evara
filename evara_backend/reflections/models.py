from django.db import models
from django.conf import settings
from capsules.models import Capsule


class Reflection(models.Model):

    capsule = models.OneToOneField(
        Capsule,
        on_delete=models.CASCADE,
        related_name="reflection"
    )


    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="reflections"
    )


    content = models.TextField()


    created_at = models.DateTimeField(
        auto_now_add=True
    )


    updated_at = models.DateTimeField(
        auto_now=True
    )


    def __str__(self):
        return f"Reflection for {self.capsule.title}"



class ReflectionAttachment(models.Model):

    ATTACHMENT_TYPES = [
        ("image", "Image"),
        ("video", "Video"),
        ("audio", "Audio"),
    ]


    reflection = models.ForeignKey(
        Reflection,
        on_delete=models.CASCADE,
        related_name="attachments"
    )


    file = models.FileField(
        upload_to="reflection_attachments/"
    )


    attachment_type = models.CharField(
        max_length=20,
        choices=ATTACHMENT_TYPES
    )


    uploaded_at = models.DateTimeField(
        auto_now_add=True
    )


    def __str__(self):
        return f"{self.reflection.capsule.title} attachment"