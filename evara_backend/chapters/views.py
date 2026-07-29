from rest_framework import generics, permissions

from .models import Chapter
from .serializers import ChapterSerializer, ChapterDetailSerializer

from django.db.models import Q



class ChapterListCreateView(generics.ListCreateAPIView):

    serializer_class = ChapterSerializer

    permission_classes = [
        permissions.IsAuthenticated
    ]


    def get_queryset(self):

        chapters = Chapter.objects.filter(
            user=self.request.user
        )


        # -------------------------
        # Search
        # -------------------------

        search = self.request.query_params.get("search")

        if search:

            chapters = chapters.filter(
                Q(title__icontains=search)
            )


        # -------------------------
        # Sorting
        # -------------------------

        sort = self.request.query_params.get("sort")


        if sort == "oldest":

            chapters = chapters.order_by(
                "created_at"
            )


        elif sort == "updated":

            chapters = chapters.order_by(
                "-updated_at"
            )


        elif sort == "title":

            chapters = chapters.order_by(
                "title"
            )


        else:

            chapters = chapters.order_by(
                "-created_at"
            )


        return chapters


    def perform_create(self, serializer):

        serializer.save(
            user=self.request.user
        )



class ChapterDetailView(generics.RetrieveUpdateDestroyAPIView):

    serializer_class = ChapterDetailSerializer

    permission_classes = [
        permissions.IsAuthenticated
    ]

    def get_queryset(self):
    
        chapters = Chapter.objects.filter(
            user=self.request.user
        )
    
    
        # -------------------------
        # Search
        # -------------------------
    
        search = self.request.query_params.get("search")
    
        if search:
    
            chapters = chapters.filter(
                Q(title__icontains=search)
            )
    
    
        # -------------------------
        # Sorting
        # -------------------------
    
        sort = self.request.query_params.get("sort")
    
    
        if sort == "oldest":
    
            chapters = chapters.order_by(
                "created_at"
            )
    
    
        elif sort == "updated":
    
            chapters = chapters.order_by(
                "-updated_at"
            )
    
    
        elif sort == "title":
    
            chapters = chapters.order_by(
                "title"
            )
    
    
        else:
    
            chapters = chapters.order_by(
                "-created_at"
            )
    
    
        return chapters
    