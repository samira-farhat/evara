import 'dart:convert';
import 'package:evara_mobile/core/app_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../core/app_colors.dart';
import 'forgot_password_screen.dart';
import 'otp_verification_screen.dart';

class AuthPageThree extends StatefulWidget {
  const AuthPageThree({Key? key}) : super(key: key);

  @override
  State<AuthPageThree> createState() => _AuthPageThreeState();
}

class _AuthPageThreeState extends State<AuthPageThree> {
  bool _isLoginMode = true;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();
  bool _isPasswordFocused = false;

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final RegExp _passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d).{6,}$');

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {});
    });
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final password = _passwordController.text;
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();

    if (username.isEmpty) {
      setState(() => _errorMessage = "Please enter your username.");
      return;
    }

    if (password.isEmpty) {
      setState(() => _errorMessage = "Please enter your password.");
      return;
    }

    if (!_isLoginMode) {
      // Email Regex to block poorly formed or generic fake domains
      final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

      if (email.isEmpty || !emailRegex.hasMatch(email)) {
        setState(() => _errorMessage = "Please enter a valid, real email address.");
        return;
      }

      // Password requirements checked ONLY on registration
      if (!_passwordRegex.hasMatch(password)) {
        setState(() => _errorMessage = "Password does not meet requirements.");
        return;
      }
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      if (_isLoginMode) {
        final response = await http.post(
          Uri.parse(ApiConfig.login),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"username": username, "password": password}),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          if (!mounted) return;
          // TODO: Successfully logged in (Add your home navigation here)
          debugPrint("Login Success");
        } else {
          setState(() => _errorMessage = data["detail"] ?? data["error"] ?? "Invalid credentials.");
        }
      } else {
        final response = await http.post(
          Uri.parse(ApiConfig.register),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "username": username,
            "email": email,
            "password": password,
          }),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                email: email,
                flowType: OtpFlowType.signupVerification,
              ),
            ),
          );
        } else {
          final data = jsonDecode(response.body);
          String errStr = "Registration failed.";
          if (data is Map) {
            errStr = data.values.map((v) => v is List ? v.join(' ') : v.toString()).join('\n');
          }
          setState(() => _errorMessage = errStr);
        }
      }
    } catch (e) {
      setState(() => _errorMessage = "Unable to connect. Please check your network connection.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passwordText = _passwordController.text;
    final hasMinLength = passwordText.length >= 6;
    final hasCapital = passwordText.contains(RegExp(r'[A-Z]'));
    final hasNumber = passwordText.contains(RegExp(r'[0-9]'));

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 10),

                        Text(
                          _isLoginMode ? "Welcome" : "Create Account",
                          style: GoogleFonts.cormorantGaramond(
                            color: AppColors.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        SizedBox(height: 6),

                        Text(
                          _isLoginMode
                              ? "Sign in to unlock your time capsules."
                              : "Start your continuous conversation with yourself.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),

                        SizedBox(height: 25),
        
                        _buildTextField(
                          controller: _usernameController,
                          hintText: "Username",
                          icon: Icons.person_outline_rounded,
                        ),

                        SizedBox(height: 14),
        
                        if (!_isLoginMode) ...[
                          _buildTextField(
                            controller: _emailController,
                            hintText: "Email address",
                            icon: Icons.email_outlined,
                          ),

                          SizedBox(height: 14),
                        ],
        
                        // Password Field
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.glassFill,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: TextField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 20),
                              hintText: "Password",
                              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                          ),
                        ),
        
                        // REQUIREMENTS SHOW ONLY IN REGISTER MODE WHEN FOCUSED (NEVER IN LOGIN)
                        if (!_isLoginMode && _isPasswordFocused) ...[

                          SizedBox(height: 8),

                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRequirementRow("At least 6 characters", hasMinLength),

                                SizedBox(height: 2),

                                _buildRequirementRow("Includes a capital letter", hasCapital),

                                SizedBox(height: 2),

                                _buildRequirementRow("Includes a number", hasNumber),
                              ],
                            ),
                          ),
                        ],
        
                        if (_errorMessage != null) ...[

                          SizedBox(height: 12),

                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.error, fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
        
                        if (_isLoginMode)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                                );
                              },
                              child: Text(
                                "Forgot password?",
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ),
                          )
                        else

                          SizedBox(height: 14),
        
                        SizedBox(height: 6),
        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.glassBorder,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.3)),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary,))
                                : Text(
                              _isLoginMode ? "Sign In to Evara" : "Create My Account",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
        
                        SizedBox(height: 16),
        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLoginMode ? "Don't have an account? " : "Already have an account? ",
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isLoginMode = !_isLoginMode;
                                  _errorMessage = null;
                                });
                              },
                              child: Text(
                                _isLoginMode ? "Sign up" : "Sign in",
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isMet ? AppColors.success : AppColors.textMuted,
          size: 13,
        ),

        SizedBox(width: 6),

        Text(
          text,
          style: TextStyle(
            color: isMet ? AppColors.textSecondary : AppColors.textMuted,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          hintText: hintText,
          hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}