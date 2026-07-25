import 'package:flutter/material.dart';
import '../core/app_background.dart';
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
    // The Scaffold needs transparent background so the gradient shows through
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground( // Background is applied once here for the whole flow
        child: Stack(
          children: [
            // 1. The PageView sliding through the 3 screens
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: const [
                IntroPageOne(), // Now perfectly centered
                IntroPageTwo(), // Now perfectly centered
                AuthPageThree(),// Now perfectly centered
              ],
            ),

            // 2. "Swipe to begin" indicator - POSITIONED PERMANENTLY AT BOTTOM
            // We only show this on the first two pages, not the login page
            if (_currentIndex == 0)
              Positioned(
                bottom: 45, // Slightly above the dots
                left: 0,
                right: 0,
                child: const Center(
                  child: Text(
                    "Swipe to begin",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            // 3. Persistent Page Indicator Dots at the bottom overlay
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  bool isActive = _currentIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: isActive ? 24.0 : 6.0,
                    height: 6.0,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
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