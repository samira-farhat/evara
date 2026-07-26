import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class ChaptersTab extends StatelessWidget {
  const ChaptersTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Text(
          "Chapters Screen",
          style: TextStyle(
            color: AppColors.twilightPurple,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}