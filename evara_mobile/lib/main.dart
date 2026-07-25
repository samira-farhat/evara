import 'package:flutter/material.dart';
import 'onboarding/onboarding_container.dart';

void main() {
  runApp(const EvaraApp());
}

class EvaraApp extends StatelessWidget {
  const EvaraApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Evara',
      debugShowCheckedModeBanner: false,
      // Global theme config matching your twilight luxury aesthetic
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF120A21),
        fontFamily: 'Roboto',
      ),
      home: const OnboardingContainer(),
    );
  }
}