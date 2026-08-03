from rest_framework import serializers

from .models import Reflection, ReflectionAttachment
from capsules.models import Capsule

from chapters.models import Chapter


class ReflectionAttachmentSerializer(serializers.ModelSerializer):

    class Meta:

        model = ReflectionAttachment

        fields = [
            "id",
            "reflection",
            "file",
            "attachment_type",
            "uploaded_at",
        ]



class ReflectionSerializer(serializers.ModelSerializer):

    attachments = ReflectionAttachmentSerializer(
        many=True,
        read_only=True
    )

    capsule_title = serializers.CharField(
        source="capsule.title",
        read_only=True,
    )

    capsule_chapter = serializers.IntegerField(
        source="capsule.chapter_id",
        read_only=True,
    )


    def validate(self, data):

        request = self.context["request"]

        capsule = data.get("capsule")


        # Make sure capsule belongs to user
        if capsule.user != request.user:
            raise serializers.ValidationError(
                "You cannot reflect on another user's capsule."
            )


        # Letters don't have reflections
        if capsule.capsule_type == "letter":
            raise serializers.ValidationError(
                "Letter capsules cannot have reflections."
            )


        # Capsule must be unlocked
        from django.utils import timezone

        if capsule.unlock_date > timezone.now():
            raise serializers.ValidationError(
                "This capsule is still locked."
            )


        # Only one reflection per capsule
        if Reflection.objects.filter(capsule=capsule).exists():
            raise serializers.ValidationError(
                "This capsule already has a reflection."
            )


        return data



    class Meta:

        model = Reflection

        fields = [
            "id",
            "capsule",
            "capsule_title",
            "capsule_chapter",
            "content",
            "attachments",
            "created_at",
            "updated_at",
        ]


class ReflectionSendForwardSerializer(serializers.Serializer):

    reflection = serializers.PrimaryKeyRelatedField(
        queryset=Reflection.objects.all()
    )

    unlock_date = serializers.DateTimeField()

    title = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=255
    )

    chapter = serializers.PrimaryKeyRelatedField(
        queryset=Chapter.objects.all(),
        required=False,
        allow_null=True,
    )