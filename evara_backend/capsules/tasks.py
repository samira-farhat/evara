from celery import shared_task
from django.utils import timezone

from .models import Capsule
from .emails import (
    send_capsule_delivery_email,
    send_letter_to_recipient,
    send_letter_delivery_confirmation,
)


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

            if capsule.capsule_type == "letter":

                # Send letter to the recipient
                send_letter_to_recipient(capsule)

                # Notify sender that it was delivered
                send_letter_delivery_confirmation(capsule)

            else:

                # Send normal capsule arrival email
                send_capsule_delivery_email(capsule)


            # Only mark delivered after emails succeed
            capsule.is_delivered = True
            capsule.delivered_at = now
            capsule.save()


            count += 1


        except Exception as e:

            # Capsule stays undelivered so celery can retry later
            print(
                f"Failed delivering capsule {capsule.id}: {e}"
            )


    return f"{count} capsules delivered"