import 'package:flutter/material.dart';
import '../core/app_background.dart';
import '../core/app_colors.dart';
import 'intro_page_one.dart';
import 'intro_page_two.dart';
import 'auth_page_three.dart';

class OnboardingContainer extends StatefulWidget {
  const OnboardingContainer({Key? key}) : super(key: key);

  @override
  State<OnboardingContainer> createState() => _OnboardingContainerState();
}

class _OnboardingContainerState extends State<OnboardingContainer> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                IntroPageOne(),
                IntroPageTwo(),
                AuthPageThree(),
              ],
            ),

            if (_currentIndex == 0)
              Positioned(
                bottom: 45,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "Swipe to begin",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  bool isActive = _currentIndex == index;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 4.0),
                    width: isActive ? 24.0 : 6.0,
                    height: 6.0,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textPrimary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}