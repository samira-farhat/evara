from rest_framework import serializers
from .models import Chapter



class ChapterSerializer(serializers.ModelSerializer):

    class Meta:

        model = Chapter

        fields = [
            "id",
            "title",
            "cover_image",
            "created_at",
            "updated_at",
        ]



class ChapterHomeSerializer(serializers.ModelSerializer):

    capsule_count = serializers.SerializerMethodField()


    class Meta:

        model = Chapter

        fields = [
            "id",
            "title",
            "cover_image",
            "capsule_count",
        ]


    def get_capsule_count(self, obj):

        return obj.capsules.count()