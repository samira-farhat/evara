from rest_framework import serializers
from .models import Chapter

from django.utils import timezone

from capsules.models import Capsule


class ChapterSerializer(serializers.ModelSerializer):

    capsule_count = serializers.SerializerMethodField()

    class Meta:

        model = Chapter

        fields = [
            "id",
            "title",
            "description",
            "cover_image",
            "capsule_count",
            "created_at",
            "updated_at",
        ]


    def get_capsule_count(self, obj):

        return obj.capsules.count()


    def validate_title(self, value):
        request = self.context.get("request")
        if request:
            cleaned_title = value.strip()
            
            # Base query for the current user
            queryset = Chapter.objects.filter(
                user=request.user,
                title__iexact=cleaned_title
            )

            # If we are updating an existing instance, exclude it
            if self.instance:
                queryset = queryset.exclude(pk=self.instance.pk)

            if queryset.exists():
                raise serializers.ValidationError(
                    "You already have a chapter with this title."
                )

        return value


class ChapterDetailSerializer(serializers.ModelSerializer):

    capsule_count = serializers.SerializerMethodField()

    capsules = serializers.SerializerMethodField()


    class Meta:

        model = Chapter

        fields = [
            "id",
            "title",
            "description",
            "cover_image",
            "capsule_count",
            "capsules",
            "created_at",
            "updated_at",
        ]

    def validate_title(self, value):

        request = self.context.get("request")

        if request:

            cleaned_title = value.strip()

            queryset = Chapter.objects.filter(
                user=request.user,
                title__iexact=cleaned_title
            )

            # Exclude the chapter being edited
            if self.instance:
                queryset = queryset.exclude(
                    pk=self.instance.pk
                )

            if queryset.exists():
                raise serializers.ValidationError(
                    "You already have a chapter with this title."
                )

        return value
    

    def get_capsule_count(self, obj):

        return obj.capsules.count()


    def get_capsules(self, obj):

        now = timezone.now()

        capsules = obj.capsules.order_by(
            "-created_at"
        )

        data = []

        for capsule in capsules:

            status = (
                "unlocked"
                if capsule.unlock_date <= now
                else "locked"
            )

            days_remaining = max(
                0,
                (capsule.unlock_date - now).days
            )

            data.append({

                "id": capsule.id,

                "title": capsule.title,

                "capsule_type": capsule.capsule_type,

                "unlock_date": capsule.unlock_date,

                "created_at": capsule.created_at,

                "days_remaining": days_remaining,

                "status": status,

            })

        return data