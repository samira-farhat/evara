from celery import shared_task
from django.utils import timezone

from .models import Capsule
from .emails import send_capsule_delivery_email


@shared_task
def deliver_capsules():

    now = timezone.now()

    capsules = Capsule.objects.filter(
        unlock_date__lte=now,
        is_delivered=False
    )

    count = 0

    for capsule in capsules:

        try:
            # send email first
            send_capsule_delivery_email(capsule)

            # only mark delivered after successful email
            capsule.is_delivered = True
            capsule.delivered_at = now
            capsule.save()

            # future:
            # send push notification

            count += 1

        except Exception as e:
            # so celery shows the error
            # and the capsule stays undelivered
            print(f"Failed delivering capsule {capsule.id}: {e}")

    return f"{count} capsules delivered"