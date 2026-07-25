import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPageOne extends StatefulWidget {
  const IntroPageOne({Key? key}) : super(key: key);

  @override
  State<IntroPageOne> createState() => _IntroPageOneState();
}

class _IntroPageOneState extends State<IntroPageOne>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sparkleScaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Smooth heartbeat loop for the sparkle and aura glow
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // The sparkle inside scales up and down (beating effect)
    _sparkleScaleAnimation = Tween<double>(begin: 0.85, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // The inner aura glow pulses synchronously
    _glowAnimation = Tween<double>(begin: 15.0, end: 32.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Balanced Rose-Purple Aura Circle with Beating Sparkle
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Balanced rose-purple blend: soft pinkish core transitioning into rich purple
                    gradient: const RadialGradient(
                      center: Alignment(0.0, 0.0),
                      radius: 0.85,
                      colors: [
                        Color(0xFFE8D7F1), // Soft luminous pale rose-lavender core
                        Color(0xFFB189DF), // Mid-tone balanced rosy-purple aura
                        Color(0xFF6B3FA0), // Deep rich purple border edge
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                    // Fine double ring border
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC8A2C8).withValues(alpha: 0.35), // Soft amethyst glow shadow
                        blurRadius: _glowAnimation.value,
                        spreadRadius: 2.5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner secondary subtle ring line
                      Container(
                        width: 124,
                        height: 124,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.0,
                          ),
                        ),
                      ),
                      // The Beating Sparkle Icon in the center
                      Transform.scale(
                        scale: _sparkleScaleAnimation.value,
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 46,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 70),

            // App Title
            Text(
              "Evara",
              style: GoogleFonts.cormorantGaramond(
                color: Colors.white,
                fontSize: 50,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle Description
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                "A bridge between who you were,\nwho you are, and who you intend\nto be.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 15.5,
                  height: 1.5,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}