from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),

    path(
        "api/auth/",
        include("users.urls")
    ),

    path(
        "api/chapters/",
        include("chapters.urls")
    ),

    path(
        "api/capsules/",
        include("capsules.urls")
    ),

    path(
        "api/home/",
        include("dashboard.urls")
    ),

    path(
        "api/reflections/",
        include("reflections.urls")
    ),
]

urlpatterns += static(
    settings.MEDIA_URL,
    document_root=settings.MEDIA_ROOT
)
