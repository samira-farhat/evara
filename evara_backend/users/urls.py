from django.urls import path

from .views import (
    RegisterView,
    VerifyEmailView,
    LoginView,
    ForgotPasswordView,
    VerifyResetOTPView,
    ResetPasswordView,
    ResendOTPView,
)

from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [

    path(
        "register/",
        RegisterView.as_view(),
        name="register"
    ),

    path(
        "login/",
        LoginView.as_view(),
        name="login"
    ),

    path(
        "verify-email/",
        VerifyEmailView.as_view()
    ),

    path(
        "forgot-password/",
        ForgotPasswordView.as_view()
    ),

    path(
        "verify-reset-otp/",
        VerifyResetOTPView.as_view()
    ),

    path(
        "reset-password/",
        ResetPasswordView.as_view()
    ),

    path(
        "resend-otp/",
        ResendOTPView.as_view(),
        name="resend-otp",
    ),

    path(
        "token/refresh/",
        TokenRefreshView.as_view(),
        name="token-refresh"
    ),

]