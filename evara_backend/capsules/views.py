from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from .models import Capsule, Attachment
from .serializers import (
    CapsuleSerializer,
    AttachmentSerializer
)



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




class AttachmentViewSet(viewsets.ModelViewSet):

    serializer_class = AttachmentSerializer
    permission_classes = [IsAuthenticated]


    def get_queryset(self):

        return Attachment.objects.filter(
            capsule__user=self.request.user
        )