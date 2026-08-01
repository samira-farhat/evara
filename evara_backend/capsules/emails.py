from django.core.mail import EmailMultiAlternatives
from django.conf import settings


def send_capsule_delivery_email(capsule):

    user = capsule.user


    subject = "Your Evara capsule has arrived"


    html_message = f"""
    <!DOCTYPE html>
    <html>
    <body style="
        margin:0;
        padding:40px;
        background:#F5F2FA;
        font-family:Arial, Helvetica, sans-serif;
    ">

        <table align="center"
               width="100%"
               style="
                    max-width:560px;
                    background:white;
                    border-radius:18px;
                    padding:40px;
                    box-shadow:0 8px 30px rgba(0,0,0,.08);
               ">

            <tr>
                <td align="center">

                    <h1 style="
                        margin:0;
                        font-size:36px;
                        font-weight:500;
                        font-family:Georgia, serif;
                        color:#8B6FC0;
                    ">
                        Evara
                    </h1>

                    <p style="
                        color:#8E7AAE;
                        margin-top:8px;
                        font-size:14px;
                    ">
                        A bridge between who you were,
                        who you are,
                        and who you intend to be.
                    </p>

                </td>
            </tr>


            <tr>
                <td>

                    <h2 style="
                        margin-top:32px;
                        color:#6B4E9E;
                    ">
                        Your capsule has arrived ✨
                    </h2>


                    <p style="
                        color:#6F6783;
                        line-height:1.7;
                    ">
                        A message from your past self is now ready.
                        Open your capsule and take a moment to reflect
                        on the person you were and the person you are becoming.
                    </p>

                </td>
            </tr>


            <tr>
                <td align="center">

                    <table align="center">
                        <tr>
                            <td style="
                                padding:18px 35px;
                                border-radius:16px;
                                background:#8B6FC0;
                                color:white;
                                font-size:18px;
                                font-weight:bold;
                                text-align:center;
                            ">
                                Open Your Capsule
                            </td>
                        </tr>
                    </table>

                </td>
            </tr>


            <tr>
                <td>

                    <hr style="
                        margin:32px 0;
                        border:none;
                        border-top:1px solid #E8DFF2;
                    ">


                    <p style="
                        font-size:12px;
                        color:#9A8AB5;
                        text-align:center;
                    ">
                        You can open your capsule from the Evara app
                        and begin your reflection journey.
                    </p>


                </td>
            </tr>


        </table>

    </body>
    </html>
    """


    text_message = f"""
Your Evara capsule has arrived.

A message from your past self is ready.

Open the Evara app to view it and begin your reflection.
"""


    email = EmailMultiAlternatives(
        subject,
        text_message,
        settings.EMAIL_HOST_USER,
        [user.email],
    )


    email.attach_alternative(
        html_message,
        "text/html"
    )


    email.send()