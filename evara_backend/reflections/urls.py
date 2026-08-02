from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import (
    ReflectionViewSet,
    ReflectionAttachmentViewSet,
    ReflectionSendForwardAPIView,
)


router = DefaultRouter()


router.register(
    "",
    ReflectionViewSet,
    basename="reflection"
)


router.register(
    "attachments",
    ReflectionAttachmentViewSet,
    basename="reflection-attachment"
)



urlpatterns = [

    path(
        "send-forward/",
        ReflectionSendForwardAPIView.as_view(),
        name="reflection-send-forward"
    ),


    path(
        "",
        include(router.urls)
    ),
]