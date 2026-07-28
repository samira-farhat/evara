from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import CapsuleViewSet, AttachmentViewSet, CapsuleLibraryAPIView


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
        "",
        include(router.urls)
    ),
]