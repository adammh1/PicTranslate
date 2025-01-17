import 'package:flutter/material.dart';

class OnboardingPageModel {
  final String title;
  final String description;
  final String image;
  final Color bgColor;
  final Color textColor;

  OnboardingPageModel({
    required this.title,
    required this.description,
    required this.image,
    required this.bgColor,
    required this.textColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageModel> onboardingPages = [
    OnboardingPageModel(
      title: "Welcome to PicTranslate",
      description: "Instantly translate text from images with just one click.",
      image: "assets/images/T5.png", 
      bgColor: Colors.blue,
      textColor: Colors.white,
    ),
    OnboardingPageModel(
      title: "Simple and Fast",
      description: "Capture an image, extract the text, and translate it immediately.",
      image: "assets/images/T4.png",
      bgColor: Colors.green,
      textColor: Colors.white,
    ),
    OnboardingPageModel(
      title: "Multilingual",
      description: "Supports multiple languages to help you anywhere in the world.",
      image: "assets/images/T7.png",
      bgColor: Colors.purple,
      textColor: Colors.white,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: onboardingPages.length,
            itemBuilder: (context, index) {
              return Container(
                color: onboardingPages[index].bgColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(onboardingPages[index].image),
                    const SizedBox(height: 20),
                    Text(
                      onboardingPages[index].title,
                      style: TextStyle(
                        color: onboardingPages[index].textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      onboardingPages[index].description,
                      style: TextStyle(
                        color: onboardingPages[index].textColor,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/auth'); 
              },
              child: const Text(
                "Skip",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: TextButton(
              onPressed: () {
                if (_currentPage == onboardingPages.length - 1) {
                  Navigator.pushReplacementNamed(context, '/auth'); 
                } else {
                  _pageController.animateToPage(
                    _currentPage + 1,
                    curve: Curves.easeInOutCubic,
                    duration: const Duration(milliseconds: 250),
                  );
                }
              },
              child: Text(
                _currentPage == onboardingPages.length - 1 ? "Finish" : "Next",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: const OnboardingScreen(),
    routes: {
      '/login': (context) => const LoginScreen(), 
    },
  ));
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Login Screen"),
      ),
    );
  }
}
