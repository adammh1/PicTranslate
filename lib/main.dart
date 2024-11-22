import 'screens/onboarding_screen.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/onboarding', // Default route
      routes: {
        '/onboarding': (context) => const OnboardingScreen(), // Use OnboardingScreen widget
        '/login': (context) => LoginScreen(),
        // '/home': (context) => HomeScreen(),
      },
    );
  }
}
