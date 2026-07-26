import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class CreateTab extends StatelessWidget {
  const CreateTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Text(
          "Create Screen",
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