from django.db import models
from django.conf import settings


class Chapter(models.Model):

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="chapters"
    )

    title = models.CharField(
        max_length=100
    )

    description = models.TextField(
        blank=True,
        null=True
    )

    cover_image = models.ImageField(
        upload_to="chapter_covers/",
        null=True,
        blank=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    updated_at = models.DateTimeField(
        auto_now=True
    )


    def __str__(self):
        return self.title