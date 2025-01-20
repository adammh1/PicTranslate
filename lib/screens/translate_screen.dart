import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
    String? _sourceLanguage;

  String? _selectedLanguage;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  final List<String> _languages = [
    "English", "French", "Spanish", "Arabic", "German", "Chinese", "Russian","Japanese","Portuguese","Italian"
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadPreferredLanguage();
  }

  Future<void> _loadPreferredLanguage() async {
    setState(() => _isLoading = true);
    try {
      final token = await _currentUser!.getIdToken();
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/users/${_currentUser!.uid}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _selectedLanguage = data['preferredLanguage'] ;
        });
      } else {
        _showError('Failed to load user data');
      }
    } catch (e) {
      _showError('Error loading user data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

 Future<void> _uploadImage() async {
  if (_sourceLanguage == null || _selectedLanguage == null) {
    _showError('Please select source and target languages');
    return;
  }

  if (_currentUser == null) {
    _showError('User is not authenticated');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final token = await _currentUser!.getIdToken();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:3000/api/translate'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('image', _imageFile!.path),
    );
    request.fields['sourceLanguage'] = _sourceLanguage!;
    request.fields['targetLanguage'] = _selectedLanguage!;
    request.fields['uid'] = _currentUser!.uid;

    request.headers['Authorization'] = 'Bearer $token';

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);
      _showTranslationResult(data['translatedText']);
    } else {
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);
      _showError(data['error'] ?? 'Failed to translate image');
    }
  } catch (e) {
    _showError('Error uploading image: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}




  void _showTranslationResult(String translatedText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Translation Result'),
        content: Text(translatedText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

void _showError(String error) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translate', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black.withOpacity(0.8),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())  
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   DropdownButtonFormField<String>(
                    value: _sourceLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Select Source Language',
                      border: OutlineInputBorder(),
                    ),
                    items: _languages.map((lang) {
                      return DropdownMenuItem(
                        value: lang,
                        child: Text(lang),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _sourceLanguage = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Select Target Language',
                      border: OutlineInputBorder(),
                    ),
                    items: _languages.map((lang) {
                      return DropdownMenuItem(
                        value: lang,
                        child: Text(lang),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload Image'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_imageFile != null)
                    Column(
                      children: [
                        const Text(
                          'Selected Image:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Image.file(_imageFile!, height: 200),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
