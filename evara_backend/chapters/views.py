from rest_framework import generics, permissions

from .models import Chapter
from .serializers import ChapterSerializer



class ChapterListCreateView(generics.ListCreateAPIView):

    serializer_class = ChapterSerializer

    permission_classes = [
        permissions.IsAuthenticated
    ]


    def get_queryset(self):

        return Chapter.objects.filter(
            user=self.request.user
        )


    def perform_create(self, serializer):

        serializer.save(
            user=self.request.user
        )



class ChapterDetailView(generics.RetrieveUpdateDestroyAPIView):

    serializer_class = ChapterSerializer

    permission_classes = [
        permissions.IsAuthenticated
    ]


    def get_queryset(self):

        return Chapter.objects.filter(
            user=self.request.user
        )