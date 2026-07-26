from rest_framework import serializers


class UpcomingCapsuleSerializer(serializers.Serializer):

    id = serializers.IntegerField()

    title = serializers.CharField()

    capsule_type = serializers.CharField()

    unlock_date = serializers.DateField()

    days_remaining = serializers.IntegerField()

    is_locked = serializers.BooleanField()



class ActiveChapterSerializer(serializers.Serializer):

    id = serializers.IntegerField()

    title = serializers.CharField()

    cover_image = serializers.ImageField(
        allow_null=True
    )

    capsule_count = serializers.IntegerField()