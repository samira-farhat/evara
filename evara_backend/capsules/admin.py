from django.contrib import admin

from .models import Capsule, Attachment


class AttachmentInline(admin.TabularInline):
    model = Attachment
    extra = 0


@admin.register(Capsule)
class CapsuleAdmin(admin.ModelAdmin):

    list_display = (
        "title",
        "user",
        "capsule_type",
        "unlock_date",
        "recipient_email",
        "is_delivered",
    )

    list_filter = (
        "capsule_type",
        "is_delivered",
    )

    search_fields = (
        "title",
        "recipient_name",
        "recipient_email",
    )

    inlines = [
        AttachmentInline,
    ]


@admin.register(Attachment)
class AttachmentAdmin(admin.ModelAdmin):

    list_display = (
        "id",
        "capsule",
        "attachment_type",
        "uploaded_at",
    )