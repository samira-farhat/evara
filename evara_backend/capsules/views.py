from django.utils import timezone
from rest_framework import viewsets, mixins
from rest_framework.permissions import IsAuthenticated

from .models import Capsule, Attachment
from .serializers import (
    CapsuleSerializer,
    LockedCapsuleSerializer,
    AttachmentSerializer,
    CapsuleLibrarySerializer
)

from rest_framework.views import APIView
from rest_framework.response import Response

from django.db.models import Q

from rest_framework.exceptions import PermissionDenied


class CapsuleViewSet(viewsets.ModelViewSet):

    serializer_class = CapsuleSerializer
    permission_classes = [IsAuthenticated]


    def get_queryset(self):

        return Capsule.objects.filter(
            user=self.request.user
        )


    def perform_create(self, serializer):

        serializer.save(
            user=self.request.user
        )


    def retrieve(self, request, *args, **kwargs):

        capsule = self.get_object()

        if capsule.unlock_date > timezone.now():

            serializer = LockedCapsuleSerializer(capsule)

            return Response(serializer.data)

        if not capsule.has_been_opened:
            capsule.has_been_opened = True
            capsule.opened_at = timezone.now()
            capsule.save(
                update_fields=[
                    "has_been_opened",
                    "opened_at",
                ]
            )

        serializer = self.get_serializer(capsule)

        return Response(serializer.data)



class AttachmentViewSet(
    mixins.CreateModelMixin,
    mixins.ListModelMixin,
    mixins.DestroyModelMixin,
    viewsets.GenericViewSet
):

    serializer_class = AttachmentSerializer
    permission_classes = [IsAuthenticated]


    def get_queryset(self):

        return Attachment.objects.filter(
            capsule__user=self.request.user
        )


class CapsuleLibraryAPIView(APIView):

    permission_classes = [IsAuthenticated]


    def get(self, request):

        capsules = Capsule.objects.filter(
            user=request.user
        )


        # -----------------
        # Search
        # -----------------

        search = request.query_params.get("search")

        if search:

            capsules = capsules.filter(
                Q(title__icontains=search)
                |
                Q(chapter__title__icontains=search)
            )


        # -----------------
        # Type filter
        # -----------------

        capsule_type = request.query_params.get("type")

        if capsule_type:

            capsules = capsules.filter(
                capsule_type=capsule_type
            )


        # -----------------
        # Status filter
        # -----------------

        status = request.query_params.get("status")

        if status == "locked":

            capsules = capsules.filter(
                unlock_date__gt=timezone.now()
            )


        elif status == "unlocked":

            capsules = capsules.filter(
                unlock_date__lte=timezone.now()
            )


        # -----------------
        # Sorting
        # -----------------

        sort = request.query_params.get("sort")


        if sort == "newest":

            capsules = capsules.order_by(
                "-created_at"
            )


        elif sort == "oldest":

            capsules = capsules.order_by(
                "created_at"
            )


        elif sort == "unlock_soonest":

            capsules = capsules.order_by(
                "unlock_date"
            )


        elif sort == "unlock_latest":

            capsules = capsules.order_by(
                "-unlock_date"
            )


        else:

            capsules = capsules.order_by(
                "-created_at"
            )


        serializer = CapsuleLibrarySerializer(
            capsules,
            many=True
        )


        return Response({
            "count": capsules.count(),
            "capsules": serializer.data
        })


class CapsuleReflectionAPIView(APIView):

    permission_classes = [IsAuthenticated]


    def get(self, request, capsule_id):

        from reflections.serializers import ReflectionSerializer

        capsule = Capsule.objects.filter(
            id=capsule_id,
            user=request.user
        ).first()


        if not capsule:
            return Response(
                {
                    "detail": "Capsule not found."
                },
                status=404
            )


        if capsule.capsule_type == "letter":
            return Response(
                {
                    "detail": "Letter capsules do not have reflections."
                },
                status=400
            )


        if not hasattr(capsule, "reflection"):
            return Response(
                {
                    "reflection": None
                }
            )


        serializer = ReflectionSerializer(
            capsule.reflection
        )


        return Response(
            serializer.data
        )