import 'dart:math';
import 'package:flutter/material.dart';

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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF8B6FC0), // Soft luminous lavender top
                  Color(0xFF6B4E9E), // Mid twilight purple
                  Color(0xFF946294), // Smooth intermediate mauve bridge
                  Color(0xFFC77D98), // Soft rosy pink blend
                  Color(0xFFE89BAE), // Gentle sunset peach-pink bottom
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
                  center: const Alignment(0.0, -0.35),
                  radius: 0.95,
                  colors: [
                    Colors.white.withValues(alpha: 0.25), // Soft luminous highlight core
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
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

      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}