import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../core/app_background.dart';
import 'auth_page_three.dart';
import '../core/app_colors.dart';

enum OtpFlowType { signupVerification, resetPassword }

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final OtpFlowType flowType;

  const OtpVerificationScreen({
    Key? key,
    required this.email,
    required this.flowType,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  final RegExp _passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d).{6,}$');

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _clearOtpBoxes() {
    for (var c in _controllers) {
      c.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    String otpCode = _controllers.map((c) => c.text).join();
    if (otpCode.length < 6) {
      setState(() {
        _successMessage = null;
        _errorMessage = "Please enter the complete 6-digit code.";
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isLoading = true;
    });

    try {
      final endpoint = widget.flowType == OtpFlowType.signupVerification
          ? ApiConfig.verifyEmail
          : ApiConfig.verifyResetOtp;

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.email, "code": otpCode}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        if (widget.flowType == OtpFlowType.signupVerification) {
          setState(() {
            _successMessage = "Email successfully verified! Please sign in.";
          });
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AuthPageThree()),
                  (route) => false,
            );
          });
        } else {
          _showNewPasswordModal();
        }
      } else {
        setState(() => _errorMessage = data["error"] ?? "Verification failed.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Unable to connect. Please check your network connection.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNewPasswordModal() {
    final newPasswordController = TextEditingController();
    bool obscureNewPass = true;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: AppColors.glassFill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppColors.glassStrong),
            ),
            title: Text(
              "Set New Password",
              style: GoogleFonts.cormorantGaramond(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w400,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Min 6 chars, includes a capital letter & a number.",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                  ),

                  SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: TextField(
                      controller: newPasswordController,
                      obscureText: obscureNewPass,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "New password",
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => setDialogState(() => obscureNewPass = !obscureNewPass),
                        ),
                      ),
                    ),
                  ),
                  if (dialogError != null) ...[

                    SizedBox(height: 10),

                    Text(
                      dialogError!,
                      style: TextStyle(color: AppColors.error, fontSize: 11.5),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final newPass = newPasswordController.text;

                  // Validate against exact new requirement specification
                  if (!_passwordRegex.hasMatch(newPass)) {
                    setDialogState(() {
                      dialogError = "Password does not meet the requirements.";
                    });
                    return;
                  }

                  try {
                    final response = await http.post(
                      Uri.parse(ApiConfig.resetPassword),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({"email": widget.email, "password": newPass}),
                    );

                    if (response.statusCode == 200) {
                      if (!mounted) return;
                      Navigator.popUntil(context, (route) => route.isFirst);
                    } else {
                      final errData = jsonDecode(response.body);
                      setDialogState(() {
                        dialogError = errData["error"] ?? "Failed to reset password.";
                      });
                    }
                  } catch (e) {
                    setDialogState(() {
                      dialogError = "Network error during password reset.";
                    });
                  }
                },
                child: Text(
                  "Save Password",
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resendCode() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    _clearOtpBoxes();

    try {
      final purpose = widget.flowType == OtpFlowType.signupVerification ? "verification" : "password_reset";
      final response = await http.post(
        Uri.parse(ApiConfig.resendOtp),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.email, "purpose": purpose}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _successMessage = "A new verification code has been sent.";
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _errorMessage = data["error"] ?? "Failed to resend code.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network error while resending code.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.textSecondary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Verification Code",
                  style: GoogleFonts.cormorantGaramond(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  "Enter the 6-digit code sent to\n${widget.email}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13.5, height: 1.4),
                ),

                SizedBox(height: 30),

                // 6-Digit Pin Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 44,
                      height: 52,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.glassFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassStrong),
                      ),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle( color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(counterText: "", border: InputBorder.none),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),

                if (_errorMessage != null) ...[
                  SizedBox(height: 14),
                  Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.error, fontSize: 12)),
                ],

                if (_successMessage != null) ...[
                  SizedBox(height: 14),
                  Text(_successMessage!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.success, fontSize: 12)),
                ],

                SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.glassStrong,
                      foregroundColor:  AppColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.3)),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2,  color: AppColors.textPrimary))
                        : Text("Verify Code", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: _resendCode,
                  child: Text(
                    "Resend Code",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}