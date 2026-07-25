from datetime import timedelta

from django.utils import timezone

from .models import OTP



def create_otp(user, otp_type="verification"):

    OTP.objects.filter(
        user=user,
        otp_type=otp_type
    ).delete()


    code = OTP.generate_code()


    otp = OTP.objects.create(
        user=user,
        code=code,
        otp_type=otp_type,
        expires_at=timezone.now() + timedelta(minutes=5)
    )


    return otp