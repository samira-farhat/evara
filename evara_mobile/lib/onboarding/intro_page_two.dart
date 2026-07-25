import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';


class IntroPageTwo extends StatelessWidget {
  const IntroPageTwo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "How it works",
                style: GoogleFonts.cormorantGaramond(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            SizedBox(height: 8),

            Center(
              child: Text(
                "Three steps. One continuous conversation\nwith yourself.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ),

            SizedBox(height: 32),

            _buildGlassFeatureCard(
              icon: Icons.lock_clock_rounded,
              title: "Capsules",
              description: "Capture moments, thoughts, and memories for your future self. Choose when they return — months or years from now.",
            ),

            SizedBox(height: 12),

            _buildGlassFeatureCard(
              icon: Icons.nightlight_round,
              title: "Reflection",
              description: "Reconnect with who you were, reflect on how you've changed, and leave a piece of yourself for who you'll become.",
            ),

            SizedBox(height: 12),

            _buildGlassFeatureCard(
              icon: Icons.auto_stories_rounded,
              title: "Life Chapters",
              description: "Organize your memories into chapters and watch your story unfold across the different eras and moments of your life.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.glassStrong,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 22),
          ),

          SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}