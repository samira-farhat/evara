import 'package:flutter/foundation.dart';

class ApiConfig {

  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8000/api";
    }

    return "http://10.0.2.2:8000/api";
  }


  // for images
  static String get mediaBaseUrl {
    if (kIsWeb) {
      return "http://localhost:8000";
    }

    return "http://10.0.2.2:8000";
  }


  static String buildMediaUrl(String? path) {
    if (path == null || path.isEmpty) {
      return "";
    }

    if (path.startsWith("http")) {
      return path;
    }

    return "$mediaBaseUrl$path";
  }


  // Auth

  static String get auth => "$baseUrl/auth";

  static String get refreshToken =>
      "$auth/token/refresh/";

  static String get register =>
      "$auth/register/";

  static String get login =>
      "$auth/login/";

  static String get verifyEmail =>
      "$auth/verify-email/";

  static String get forgotPassword =>
      "$auth/forgot-password/";

  static String get verifyResetOtp =>
      "$auth/verify-reset-otp/";

  static String get resetPassword =>
      "$auth/reset-password/";

  static String get resendOtp =>
      "$auth/resend-otp/";


  // Dashboard

  static String get home =>
      "$baseUrl/home/";


  // Capsules

  static String get capsules =>
      "$baseUrl/capsules/";

  static String get capsuleLibrary =>
      "${capsules}library/";

  static String get attachments =>
      "${capsules}attachments/";


  // Chapters

  static String get chapters =>
      "$baseUrl/chapters/";

  static String chapterDetails(int id) =>
      "$chapters$id/";
}