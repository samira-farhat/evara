from django.urls import path

from .views import (
    ChapterListCreateView,
    ChapterDetailView
)



urlpatterns = [

    path(
        "",
        ChapterListCreateView.as_view(),
        name="chapters"
    ),

    path(
        "<int:pk>/",
        ChapterDetailView.as_view(),
        name="chapter-detail"
    ),

]