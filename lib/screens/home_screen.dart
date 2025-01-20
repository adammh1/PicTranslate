import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final User? _currentUser;

  HomeScreen({super.key}) {
    _currentUser = _auth.currentUser;
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _translationsFuture;

  @override
  void initState() {
    super.initState();
    _translationsFuture = fetchTranslations();
  }

  Future<List<dynamic>> fetchTranslations() async {
    final token = await widget._currentUser!.getIdToken();

    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/translations'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load translations');
    }
  }

  void _refreshData() {
    setState(() {
      _translationsFuture = fetchTranslations();
    });
  }

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
            onPressed: () async {
              await Navigator.pushNamed(context, '/profile');
              _refreshData(); 
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            GestureDetector(
              onTap: () async {
                await Navigator.pushNamed(context, '/translate');
                _refreshData(); 
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
            const SizedBox(height: 30),
            const Text(
              "Recent Translations",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _translationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No translations found'));
                  } else {
                    final translations = snapshot.data!;
                    return ListView.builder(
                      itemCount: translations.length,
                      itemBuilder: (context, index) {
                        final translation = translations[index];
                        return ListTile(
                          title: Text(translation['originalText']),
                          subtitle: Text(translation['translatedText']),
                          trailing: Text(
                            DateFormat('yyyy-MM-dd')
                                .format(DateTime.parse(translation['date'])),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/translate');
          _refreshData(); 
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
        onTap: (index) async {
          switch (index) {
            case 0:
              await Navigator.pushNamed(context, '/home');
              _refreshData(); 
              break;
            case 1:
              await Navigator.pushNamed(context, '/history');
              _refreshData();
              break;
            case 2:
              await Navigator.pushNamed(context, '/profile');
              _refreshData(); 
              break;
          }
        },
      ),
    );
  }
}
