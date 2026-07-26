class ApiConfig {

  static const String baseUrl =
      "http://127.0.0.1:8000/api";

  // Auth
  static const String auth = "$baseUrl/auth";

  static const String register =
      "$auth/register/";

  static const String login =
      "$auth/login/";

  static const String verifyEmail =
      "$auth/verify-email/";

  static const String forgotPassword =
      "$auth/forgot-password/";

  static const String verifyResetOtp =
      "$auth/verify-reset-otp/";

  static const String resetPassword =
      "$auth/reset-password/";

  static const String resendOtp =
      "$auth/resend-otp/";


  // Dashboard

  static const String home =
      "$baseUrl/home/";





}