from django.core.mail import EmailMultiAlternatives
from django.conf import settings


def send_otp_email(user, otp, purpose):

    if purpose == "verification":
        subject = "Verify your Evara account"
        title = "Welcome to Evara"
        subtitle = "Verify your email address"
        description = (
            "Thanks for creating your account. "
            "Use the verification code below to activate your account."
        )

    else:
        subject = "Reset your Evara password"
        title = "Password Reset"
        subtitle = "Reset your password"
        description = (
            "We received a request to reset your password. "
            "Use the code below to continue."
        )

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
                        {title}
                    </h2>

                    <p style="
                        color:#6F6783;
                        line-height:1.7;
                    ">
                        {description}
                    </p>

                </td>
            </tr>

            <tr>
                <td align="center">

                    <table align="center" cellpadding="0" cellspacing="0">
                        <tr>
                            <td style="
                                margin:35px 0;
                                padding:20px 35px;
                                border-radius:16px;
                                background:#8B6FC0;
                                font-size:34px;
                                font-weight:bold;
                                letter-spacing:8px;
                                color:#FFFFFF;
                                text-align:center;
                                font-family:Arial, Helvetica, sans-serif;
                            ">
                                {otp}
                            </td>
                        </tr>
                    </table>

                </td>
            </tr>

            <tr>
                <td>

                    <p style="
                        color:#756A8C;
                        text-align:center;
                    ">
                        This code expires in
                        <strong>5 minutes</strong>.
                    </p>

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
                        If you didn't request this email,
                        you can safely ignore it.
                    </p>

                </td>
            </tr>

        </table>

    </body>
    </html>
    """

    text_message = f"""
{subtitle}

Your code is:

{otp}

This code expires in 5 minutes.
"""

    email = EmailMultiAlternatives(
        subject,
        text_message,
        settings.EMAIL_HOST_USER,
        [user.email],
    )

    email.attach_alternative(html_message, "text/html")
    email.send()