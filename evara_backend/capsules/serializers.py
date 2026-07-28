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

            "prediction_text",
            "prediction_result",

            "goal_description",
            "goal_completed",
            "goal_completed_date",

            "is_delivered",
            "delivered_at",

            "attachments",

            "created_at",
            "updated_at",
        ]