from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import CapsuleViewSet, AttachmentViewSet


router = DefaultRouter()

router.register(
    "",
    CapsuleViewSet,
    basename="capsule"
)

router.register(
    "attachments",
    AttachmentViewSet,
    basename="attachment"
)


urlpatterns = [
    path(
        "",
        include(router.urls)
    ),
]