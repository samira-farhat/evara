from django.utils import timezone

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

from capsules.models import Capsule
from chapters.models import Chapter



class HomeDashboardAPIView(APIView):

    permission_classes = [
        IsAuthenticated
    ]


    def get(self, request):

        user = request.user


        # -------------------------
        # Greeting
        # -------------------------

        hour = timezone.localtime().hour


        if hour < 12:
            greeting = "Good morning"

        elif hour < 18:
            greeting = "Good afternoon"

        else:
            greeting = "Good evening"



        now = timezone.now()



        # -------------------------
        # Timeline Summary
        # -------------------------

        past_capsules_count = Capsule.objects.filter(
            user=user,
            unlock_date__lte=now
        ).count()



        future_capsules_count = Capsule.objects.filter(
            user=user,
            unlock_date__gt=now
        ).count()


        # -------------------------
        # Ready Capsules
        # -------------------------

        ready_capsules_count = Capsule.objects.filter(
            user=user,
            is_delivered=True
        ).count()



        years_span = 0


        capsules = Capsule.objects.filter(
            user=user
        )


        if capsules.exists():

            first_capsule = capsules.order_by(
                "created_at"
            ).first()


            latest_capsule = capsules.order_by(
                "-unlock_date"
            ).first()


            years_span = (
                latest_capsule.unlock_date.year -
                first_capsule.created_at.year
            )



        # -------------------------
        # Upcoming Capsules
        # -------------------------

        upcoming_capsules = Capsule.objects.filter(
            user=user,
            unlock_date__gt=now
        ).order_by(
            "unlock_date"
        )[:5]


        upcoming_data = []


        for capsule in upcoming_capsules:

            upcoming_data.append({

                "id": capsule.id,

                "title": capsule.title,

                "capsule_type": capsule.capsule_type,

                "unlock_date": capsule.unlock_date,

                "days_remaining":
                    (capsule.unlock_date - now).days,

                "is_locked": True

            })



        # -------------------------
        # Active Chapters
        # -------------------------

        active_chapters = Chapter.objects.filter(
            user=user
        ).order_by(
            "-updated_at"
        )[:5]



        chapters_data = []


        for chapter in active_chapters:

            chapters_data.append({

                "id": chapter.id,

                "title": chapter.title,

                "cover_image":
                    chapter.cover_image.url
                    if chapter.cover_image
                    else None,


                "capsule_count":
                    chapter.capsules.count()

            })



        return Response({

            "greeting": greeting,

            "username": user.username,


            "timeline_summary": {

                "past_capsules_count":
                    past_capsules_count,


                "future_capsules_count":
                    future_capsules_count,


                "ready_capsules_count":
                    ready_capsules_count,


                "years_span":
                    years_span

            },


            "upcoming_capsules":
                upcoming_data,


            "active_chapters":
                chapters_data

        })