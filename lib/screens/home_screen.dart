import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
              backgroundColor: Colors.grey[300],

        title: const Text("PicTranslate"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Navigate to the profile screen
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Padding(
        
        padding: const EdgeInsets.all(16.0),
        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Introduction or app description
            const Text(
              "Welcome to PicTranslate!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "Translate text from images instantly!",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

            // Main Action: Translate Image
            GestureDetector(
              onTap: () {
                // Navigate to the image capture screen
                Navigator.pushNamed(context, '/translate_image');
              },
              child: Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Start Translating",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Recent Translations Section
            const SizedBox(height: 30),
            const Text(
              "Recent Translations",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 5,  // You can replace this with dynamic data
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.image, color: Colors.blue),
                    title: Text("Translation #${index + 1}"),
                    subtitle: const Text("Translated Text Here..."),
                    onTap: () {
                      // Navigate to detailed translation view
                      Navigator.pushNamed(context, '/translation_details');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open the camera or gallery for image translation
          Navigator.pushNamed(context, '/translate_image');
        },
        tooltip: "Translate Image",
        child: const Icon(Icons.camera_alt),
      ),
      bottomNavigationBar: BottomNavigationBar(
              backgroundColor: Colors.grey[300],

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Profile',
            backgroundColor: Colors.blue,
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Navigate to home
              Navigator.pushNamed(context, '/home');
              break;
            case 1:
              // Navigate to history
              Navigator.pushNamed(context, '/history');
              break;
            case 2:
              // Navigate to profile
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
}
