from django.contrib.auth import get_user_model

from rest_framework import serializers

from .models import OTP,  NotificationSettings
from .utils import create_otp
from .emails import send_otp_email

from rest_framework_simplejwt.serializers import TokenObtainPairSerializer


User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):

    email = serializers.EmailField(
        validators=[]
    )

    password = serializers.CharField(
        write_only=True
    )

    class Meta:

        model = User

        fields = [
            "username",
            "email",
            "password"
        ]


    def validate_username(self, value):

        return value.strip().lower()


    def validate_email(self, value):

        return value.strip().lower()



    def create(self, validated_data):

        username = validated_data["username"]
        email = validated_data["email"]
        password = validated_data["password"]


        existing_user = User.objects.filter(
            email=email
        ).first()



        # User exists
        if existing_user:


            # Already verified
            if existing_user.is_email_verified:

                raise serializers.ValidationError(
                    {
                        "email":
                        "This email is already registered."
                    }
                )


            # Exists but NOT verified
            else:

                existing_user.username = username
                existing_user.set_password(password)
                existing_user.save()


                otp = create_otp(
                    existing_user
                )


                send_otp_email(
                    existing_user,
                    otp.code,
                    "verification"
                )


                return existing_user



        # New user

        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            is_email_verified=False
        )


        otp = create_otp(
            user
        )


        send_otp_email(
            user,
            otp.code,
            "verification"
        )


        return user




class LoginSerializer(TokenObtainPairSerializer):

    def validate(self, attrs):

        data = super().validate(attrs)


        if not self.user.is_email_verified:

            raise serializers.ValidationError(
                "Please verify your email before logging in."
            )


        return data


class ProfileSerializer(serializers.ModelSerializer):

    chapters_count = serializers.IntegerField(read_only=True)

    capsules_count = serializers.IntegerField(read_only=True)

    opened_capsules_count = serializers.IntegerField(read_only=True)

    reflections_count = serializers.IntegerField(read_only=True)


    class Meta:

        model = User

        fields = [
            "username",
            "email",
            "profile_picture",
            "created_at",
            "chapters_count",
            "capsules_count",
            "opened_capsules_count",
            "reflections_count",
        ]


        read_only_fields = [
            "email",
            "created_at",
        ]


class NotificationSettingsSerializer(serializers.ModelSerializer):

    class Meta:
        model = NotificationSettings

        fields = [
            "email_notifications",
            "push_notifications",
            "reminders",
        ]