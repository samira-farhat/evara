from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import (
    CapsuleViewSet,
    AttachmentViewSet,
    CapsuleLibraryAPIView,
    CapsuleReflectionAPIView
)


router = DefaultRouter()


router.register(
    "attachments",
    AttachmentViewSet,
    basename="attachment"
)


router.register(
    "",
    CapsuleViewSet,
    basename="capsule"
)


urlpatterns = [

    path(
        "library/",
        CapsuleLibraryAPIView.as_view(),
        name="capsule-library"
    ),

    path(
        "<int:capsule_id>/reflection/",
        CapsuleReflectionAPIView.as_view(),
        name="capsule-reflection"
    ),
    
    path(
        "",
        include(router.urls)
    ),
]