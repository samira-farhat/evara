from rest_framework import generics
from rest_framework.permissions import AllowAny

from .serializers import RegisterSerializer, LoginSerializer
from rest_framework_simplejwt.views import TokenObtainPairView
from django.contrib.auth import get_user_model

from rest_framework.views import APIView
from rest_framework.response import Response

from .models import OTP
from .utils import create_otp
from .emails import send_otp_email



class RegisterView(generics.CreateAPIView):

    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]


class LoginView(TokenObtainPairView):

    serializer_class = LoginSerializer


User = get_user_model()


class VerifyEmailView(APIView):

    permission_classes = [AllowAny]


    def post(self, request):

        email = request.data.get("email")
        code = request.data.get("code")


        try:

            user = User.objects.get(
                email=email
            )

            otp = OTP.objects.filter(
                user=user,
                code=code
            ).last()


            if not otp:
                return Response(
                    {
                    "error":"Invalid code"
                    },
                    status=400
                )


            if otp.is_expired():

                return Response(
                    {
                    "error":"Code expired"
                    },
                    status=400
                )


            user.is_email_verified=True

            user.save()


            otp.delete()


            return Response(
                {
                "message":"Email verified"
                }
            )


        except User.DoesNotExist:

            return Response(
                {
                "error":"User not found"
                },
                status=404
            )


class ForgotPasswordView(APIView):

    permission_classes = [AllowAny]


    def post(self, request):

        email = request.data.get("email")


        try:

            user = User.objects.get(
                email=email
            )


            otp = create_otp(
                user,
                "password_reset"
            )


            send_otp_email(
                user,
                otp.code,
                "password_reset"
            )


            return Response(
                {
                    "message":
                    "Password reset code sent."
                }
            )


        except User.DoesNotExist:

            return Response(
                {
                    "error":
                    "No account with this email."
                },
                status=404
            )



class VerifyResetOTPView(APIView):

    permission_classes = [AllowAny]


    def post(self, request):

        email = request.data.get("email")
        code = request.data.get("code")


        try:

            user = User.objects.get(
                email=email
            )


            otp = OTP.objects.filter(
                user=user,
                code=code,
                otp_type="password_reset"
            ).last()


            if not otp:

                return Response(
                    {
                    "error":
                    "Invalid code"
                    },
                    status=400
                )


            if otp.is_expired():

                return Response(
                    {
                    "error":
                    "Code expired"
                    },
                    status=400
                )

            otp.verified = True
            otp.save()

            return Response(
                {
                "message":
                "OTP verified"
                }
            )


        except User.DoesNotExist:

            return Response(
                {
                "error":
                "User not found"
                },
                status=404
            )



class ResetPasswordView(APIView):

    permission_classes = [AllowAny]

    def post(self, request):

        email = request.data.get("email")
        new_password = request.data.get("password")

        try:

            user = User.objects.get(email=email)

            otp = OTP.objects.filter(
                user=user,
                otp_type="password_reset",
                verified=True
            ).last()

            if not otp:

                return Response(
                    {
                        "error": "OTP verification required."
                    },
                    status=400
                )

            if otp.is_expired():

                otp.delete()

                return Response(
                    {
                        "error": "OTP has expired."
                    },
                    status=400
                )

            user.set_password(new_password)
            user.save()

            # OTP can only be used once
            otp.delete()

            return Response(
                {
                    "message": "Password updated successfully."
                },
                status=200
            )

        except User.DoesNotExist:

            return Response(
                {
                    "error": "User not found."
                },
                status=404
            )


class ResendOTPView(APIView):

    permission_classes = [AllowAny]

    def post(self, request):

        email = request.data.get("email")
        purpose = request.data.get("purpose")

        if purpose not in ["verification", "password_reset"]:
            return Response(
                {
                    "error": "Invalid OTP purpose."
                },
                status=400
            )

        try:

            user = User.objects.get(email=email)

            # Don't resend verification codes if already verified
            if purpose == "verification" and user.is_email_verified:
                return Response(
                    {
                        "error": "Email is already verified."
                    },
                    status=400
                )

            otp = create_otp(
                user=user,
                otp_type=purpose
            )

            send_otp_email(
                user=user,
                otp=otp.code,
                purpose=purpose
            )

            return Response(
                {
                    "message": "OTP sent successfully."
                },
                status=200
            )

        except User.DoesNotExist:

            return Response(
                {
                    "error": "User not found."
                },
                status=404
            )