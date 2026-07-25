import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthPageThree extends StatefulWidget {
  const AuthPageThree({Key? key}) : super(key: key);

  @override
  State<AuthPageThree> createState() => _AuthPageThreeState();
}

class _AuthPageThreeState extends State<AuthPageThree> {
  bool _isLoginMode = true; // Switches between Login and Register views
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      // LayoutBuilder ensures the scroll view takes up full available screen height
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Centers everything vertically middle
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      _isLoginMode ? "Welcome" : "Create Account",
                      style: GoogleFonts.cormorantGaramond(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLoginMode
                          ? "Sign in to unlock your time capsules."
                          : "Start your continuous conversation with yourself.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Name Field (Only shown during Register)
                    if (!_isLoginMode) ...[
                      _buildTextField(
                        controller: _nameController,
                        hintText: "What should we call you?",
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Email Field
                    _buildTextField(
                      controller: _emailController,
                      hintText: "Email address",
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 14),

                    // Password Field
                    _buildTextField(
                      controller: _passwordController,
                      hintText: "Password",
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                    ),

                    // Forgot Password (Only in Login Mode)
                    if (_isLoginMode)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Trigger forgot password logic
                          },
                          child: const Text(
                            "Forgot password?",
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Primary Action Button (Connects to Django later)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Hook up to Django Backend API authentication endpoints
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        child: Text(
                          _isLoginMode ? "Sign In to Evara" : "Create My Account",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Switch between Login and Register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLoginMode ? "Don't have an account? " : "Already have an account? ",
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isLoginMode = !_isLoginMode;
                            });
                          },
                          child: Text(
                            _isLoginMode ? "Sign up" : "Sign in",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30), // Padding buffer for bottom dots overlay
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white60, size: 20),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}