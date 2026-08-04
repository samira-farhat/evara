from django.core.mail import EmailMultiAlternatives
from django.conf import settings
from django.utils.html import escape


def _send_email(subject, text_message, html_message, recipient_email):
    """
    Shared email sender.
    """

    if not recipient_email:
        raise Exception("No recipient email found")

    email = EmailMultiAlternatives(
        subject,
        text_message,
        settings.EMAIL_HOST_USER,
        [recipient_email],
    )

    email.attach_alternative(
        html_message,
        "text/html"
    )

    email.send()


def _build_email_html(heading, body, button_text, footer):
    """
    Shared Evara email design.
    """

    return f"""
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
            font-size:36px;
            font-family:Georgia, serif;
            color:#8B6FC0;
            margin:0;
        ">
            Evara
        </h1>


        <p style="
            color:#8E7AAE;
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
            color:#6B4E9E;
            margin-top:32px;
        ">
            {heading}
        </h2>


        <div style="
            color:#6F6783;
            line-height:1.7;
        ">
            {body}
        </div>

    </td>
    </tr>




    <tr>
    <td align="center">

        <div style="
            margin-top:30px;
            padding:18px 35px;
            border-radius:16px;
            background:#8B6FC0;
            color:white;
            font-size:18px;
            font-weight:bold;
            display:inline-block;
        ">
            {button_text}
        </div>

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
            {footer}
        </p>


    </td>
    </tr>


    </table>


    </body>
    </html>
    """


def send_capsule_delivery_email(capsule):
    """
    Sends delivery email for:
    - Memory capsules
    - Prediction capsules
    - Accountability capsules
    """

    subject = "Your Evara capsule has arrived ✨"

    heading = "Your capsule has arrived"

    body = """
    A message from your past self is now ready.

    Open your capsule and take a moment to reflect
    on who you were, who you are, and who you are becoming.
    """

    button_text = "Open Your Capsule"

    footer = """
    You can open your capsule from the Evara app
    and begin your reflection journey.
    """


    html_message = _build_email_html(
        heading,
        body,
        button_text,
        footer
    )


    text_message = """
Your Evara capsule has arrived.

A message from your past self is now ready.

Open Evara to view it and begin your reflection journey.
"""


    _send_email(
        subject,
        text_message,
        html_message,
        capsule.user.email
    )



def send_letter_to_recipient(capsule):
    """
    Sends the actual letter email to the recipient.
    """

    if not capsule.recipient_email:
        raise Exception("Letter has no recipient email")


    sender = f"{capsule.user.username} ({capsule.user.email})"


    safe_message = escape(
        capsule.message
    ).replace(
        "\n",
        "<br>"
    )


    subject = "Someone sent you a message through Evara 💌"

    heading = "A message has arrived 💌"


    body = f"""
    Someone special left you a message through Evara.


    <br>

    This message was created on:
    <br>
    <strong>
    {capsule.created_at.strftime("%d %B %Y")}
    </strong>


    <br><br>


    From:
    <strong>
    {sender}
    </strong>


    <br><br>


    <div style="
        background:#F5F2FA;
        padding:20px;
        border-radius:16px;
        color:#6F6783;
        line-height:1.7;
    ">
        {safe_message}
    </div>
    """


    button_text = "Create Your Own Evara"

    footer = """
    Someone trusted Evara to deliver this message to you.
    """


    html_message = _build_email_html(
        heading,
        body,
        button_text,
        footer
    )


    text_message = f"""
A message has arrived through Evara.

From:
{sender}


Created on:
{capsule.created_at.strftime("%d %B %Y")}


Message:

{capsule.message}
"""


    _send_email(
        subject,
        text_message,
        html_message,
        capsule.recipient_email
    )



def send_letter_delivery_confirmation(capsule):
    """
    Sends confirmation to the sender that their letter was delivered.
    """

    subject = "Your Evara letter was delivered safely ✨"


    heading = "Your letter has arrived 💜"


    body = f"""
    Your letter to:

    <strong>
    {capsule.recipient_name}
    </strong>


    has been successfully delivered through Evara.


    <br><br>


    Thank you for trusting Evara with your message.
    """


    button_text = "Open Evara"


    footer = """
    You can always view your sent letters inside Evara.
    """


    html_message = _build_email_html(
        heading,
        body,
        button_text,
        footer
    )


    text_message = f"""
Your letter has been delivered safely.

Your message to {capsule.recipient_name}
has reached its destination through Evara.

Open Evara to view your sent letters.
"""


    _send_email(
        subject,
        text_message,
        html_message,
        capsule.user.email
    )