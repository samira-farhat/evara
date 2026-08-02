from rest_framework import viewsets
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from .models import Reflection, ReflectionAttachment
from .serializers import (
    ReflectionSerializer,
    ReflectionAttachmentSerializer,
    ReflectionSendForwardSerializer,
)

from capsules.models import Capsule


def get_root_capsule(capsule):
    while capsule.parent_capsule:
        capsule = capsule.parent_capsule

    return capsule


class ReflectionViewSet(viewsets.ModelViewSet):

    serializer_class = ReflectionSerializer
    permission_classes = [IsAuthenticated]


    def get_queryset(self):

        return Reflection.objects.filter(
            user=self.request.user
        )


    def perform_create(self, serializer):

        serializer.save(
            user=self.request.user
        )


class ReflectionSendForwardAPIView(APIView):

    permission_classes = [IsAuthenticated]


    def post(self, request):

        serializer = ReflectionSendForwardSerializer(
            data=request.data
        )

        serializer.is_valid(
            raise_exception=True
        )


        reflection = serializer.validated_data["reflection"]

        unlock_date = serializer.validated_data["unlock_date"]


        # security check
        if reflection.user != request.user:
            return Response(
                {
                    "error": "You cannot send another user's reflection forward."
                },
                status=status.HTTP_403_FORBIDDEN
            )


        original_capsule = reflection.capsule


        root_capsule = get_root_capsule(original_capsule)


        title = serializer.validated_data.get("title")


        if not title:
            title = f"{root_capsule.title} - Reflection"


        new_capsule = Capsule.objects.create(

            user=request.user,

            title=title,

            message=reflection.content,

            capsule_type=original_capsule.capsule_type,

            unlock_date=unlock_date,

            parent_capsule=original_capsule,

            reflection_source=reflection,

        )


        return Response(
            {
                "message": "Reflection sent into the future.",
                "capsule_id": new_capsule.id,
                "unlock_date": new_capsule.unlock_date,
            },
            status=status.HTTP_201_CREATED
        )



class ReflectionAttachmentViewSet(viewsets.ModelViewSet):

    serializer_class = ReflectionAttachmentSerializer
    permission_classes = [IsAuthenticated]


    def get_queryset(self):

        return ReflectionAttachment.objects.filter(
            reflection__user=self.request.user
        )


