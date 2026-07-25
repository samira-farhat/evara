import 'dart:math';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Perfectly Smooth Blended Twilight-to-Sunset Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.lavender,
                  AppColors.twilightPurple,
                  AppColors.mauve,
                  AppColors.rosePink,
                  AppColors.peachPink,
                ],
                stops: [0.0, 0.3, 0.55, 0.8, 1.0], // Evenly distributed seamless stops
              ),
            ),
          ),

          // 2. Secondary soft radial bloom to give that atmospheric center glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.35),
                  radius: 0.95,
                  colors: [
                    AppColors.textPrimary.withValues(alpha: 0.25), // Soft luminous highlight core
                    Colors.transparent,
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // 3. The Subtle Stardust / Sparkle Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: EtherealStardustPainter(),
            ),
          ),

          // 4. Page Content Wrapper
          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}

// Custom painter for dreamy, sparse stardust distribution
class EtherealStardustPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = Random(101010);

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.2 + 0.4;
      final opacity = random.nextDouble() * 0.35 + 0.05;

      paint.color = AppColors.textPrimary.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}