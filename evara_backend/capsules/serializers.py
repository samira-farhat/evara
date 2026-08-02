from rest_framework import serializers

from .models import Capsule, Attachment



class AttachmentSerializer(serializers.ModelSerializer):

    class Meta:

        model = Attachment

        fields = [
            "id",
            "capsule",
            "file",
            "attachment_type",
            "uploaded_at",
        ]




class CapsuleSerializer(serializers.ModelSerializer):

    attachments = AttachmentSerializer(
        many=True,
        read_only=True
    )

    reflection_source = serializers.PrimaryKeyRelatedField(
        read_only=True
    )

    def validate(self, data):

        capsule_type = data.get(
            "capsule_type",
            getattr(self.instance, "capsule_type", None)
        )


        recipient_name = data.get("recipient_name")
        recipient_email = data.get("recipient_email")


        if capsule_type == "letter":

            if not recipient_name:
                raise serializers.ValidationError({
                    "recipient_name": "Recipient name is required for letter capsules."
                })

            if not recipient_email:
                raise serializers.ValidationError({
                    "recipient_email": "Recipient email is required for letter capsules."
                })


        elif capsule_type in [
            "memory",
            "prediction",
            "accountability"
        ]:

            if recipient_name or recipient_email:
                raise serializers.ValidationError({
                    "recipient": "Only letter capsules can have recipient information."
                })


        return data


    class Meta:

        model = Capsule

        fields = [
            "id",
            "title",
            "message",
            "capsule_type",
            "unlock_date",

            "recipient_name",
            "recipient_email",

            "chapter",

            "parent_capsule",
            "reflection_source",

            "prediction_text",
            "prediction_result",

            "goal_description",
            "goal_completed",
            "goal_completed_date",

            "is_delivered",
            "delivered_at",

            "has_been_opened",
            "opened_at",

            "attachments",

            "created_at",
            "updated_at",
        ]



class CapsuleLibrarySerializer(serializers.ModelSerializer):

    chapter_title = serializers.CharField(
        source="chapter.title",
        read_only=True
    )


    status = serializers.SerializerMethodField()


    def get_status(self, obj):

        from django.utils import timezone

        if obj.unlock_date <= timezone.now():
            return "unlocked"

        return "locked"



    class Meta:

        model = Capsule

        fields = [
            "id",
            "title",
            "capsule_type",
            "chapter_title",
            "unlock_date",
            "created_at",
            "status",
        ]