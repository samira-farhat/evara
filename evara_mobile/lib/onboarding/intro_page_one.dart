import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';

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
      duration: Duration(milliseconds: 1600),
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
                    gradient: RadialGradient(
                      center: Alignment(0.0, 0.0),
                      radius: 0.85,
                      colors: [
                        AppColors.softLavender,
                        AppColors.mediumLavender,
                        AppColors.deepPurple,
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                    // Fine double ring border
                    border: Border.all(
                      color: AppColors.textPrimary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.amethystGlow.withValues(alpha: 0.35),
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
                            color: AppColors.textPrimary.withValues(alpha: 0.25),
                            width: 1.0,
                          ),
                        ),
                      ),
                      // The Beating Sparkle Icon in the center
                      Transform.scale(
                        scale: _sparkleScaleAnimation.value,
                        child: Icon(
                          Icons.auto_awesome,
                          color: AppColors.textPrimary,
                          size: 46,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 70),

            // App Title
            Text(
              "Evara",
              style: GoogleFonts.cormorantGaramond(
                color: AppColors.textPrimary,
                fontSize: 50,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),

            SizedBox(height: 10),

            // Subtitle Description
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                "A bridge between who you were,\nwho you are, and who you intend\nto be.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 15.5,
                  height: 1.5,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ),

            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}