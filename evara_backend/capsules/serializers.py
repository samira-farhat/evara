from rest_framework import serializers

from .models import Capsule, Attachment



class AttachmentSerializer(serializers.ModelSerializer):

    class Meta:

        model = Attachment

        fields = [
            "id",
            "file",
            "attachment_type",
            "uploaded_at",
        ]




class CapsuleSerializer(serializers.ModelSerializer):

    attachments = AttachmentSerializer(
        many=True,
        read_only=True
    )


    class Meta:

        model = Capsule

        fields = [
            "id",
            "title",
            "message",
            "capsule_type",
            "unlock_date",
            "chapter",

            "prediction_text",
            "prediction_result",

            "goal_description",
            "goal_completed",
            "goal_completed_date",

            "attachments",

            "created_at",
            "updated_at",
        ]