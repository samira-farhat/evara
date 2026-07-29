from rest_framework import serializers
from .models import Chapter


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