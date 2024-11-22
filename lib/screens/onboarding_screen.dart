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
      title: "Bienvenue à PicTranslate",
      description: "Traduisez instantanément du texte à partir d'images en un seul clic.",
      image: "assets/images/T5.png", // Replace with actual assets
      bgColor: Colors.blue,
      textColor: Colors.white,
    ),
    OnboardingPageModel(
      title: "Simple et rapide",
      description: "Capturez une image, extrayez le texte et traduisez-le immédiatement.",
      image: "assets/images/T4.png",
      bgColor: Colors.green,
      textColor: Colors.white,
    ),
    OnboardingPageModel(
      title: "Multilingue",
      description: "Supporte plusieurs langues pour vous aider partout dans le monde.",
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
                    SizedBox(height: 20),
                    Text(
                      onboardingPages[index].title,
                      style: TextStyle(
                        color: onboardingPages[index].textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
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
                Navigator.pushReplacementNamed(context, '/login'); // Redirect to Login
              },
              child: Text(
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
                  Navigator.pushReplacementNamed(context, '/login'); // Redirect to Login
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
                style: TextStyle(color: Colors.white),
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
    home: OnboardingScreen(),
    routes: {
      '/login': (context) => LoginScreen(), // Define your LoginScreen widget
    },
  ));
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Login Screen"),
      ),
    );
  }
}
