import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pictranslate/firebase_options.dart';
import 'package:pictranslate/screens/home_screen.dart';
import 'package:pictranslate/screens/onboarding_screen.dart';
import 'package:pictranslate/screens/login_or_register.dart';
import 'package:pictranslate/screens/profile_screen.dart';
import 'package:pictranslate/screens/translate_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/onboarding', 
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) =>   HomeScreen(),
        '/auth': (context) => const LoginOrRegister(),
        '/profile':(context) =>  const ProfileScreen(),
        '/login' : (context) => const LoginScreen(),
        '/translate': (context)=>  const TranslateScreen()
      },
    );
  }
}
