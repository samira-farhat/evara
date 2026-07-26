from django.urls import path

from .views import HomeDashboardAPIView


urlpatterns = [

    path(
        "",
        HomeDashboardAPIView.as_view(),
        name="home-dashboard"
    ),

]