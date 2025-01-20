import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:pictranslate/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _profilePhotoUrl;
  String _selectedLanguage = "English";
  bool _isLoading = false;
  bool _isPasswordChanging=false;
  String _oldPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _languages = ["English", "French", "Spanish", "Arabic", "German", "Chinese", "Russian","Japanese","Portuguese","Italian"];

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _emailController.text = _currentUser!.email ?? "";
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
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
          _nameController.text = data['name'] ?? '';
          _profilePhotoUrl = data['profilePhotoUrl'];
          _selectedLanguage = data['preferredLanguage'] ?? 'English';
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

  Future<void> _updateUserData() async {
    setState(() => _isLoading = true);
    try {
      final token = await _currentUser!.getIdToken();
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/api/users/${_currentUser!.uid}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'preferredLanguage': _selectedLanguage,
        }),
      );

      if (response.statusCode == 200) {
        _showMessage('Profile updated successfully');
      } else {
        _showError('Failed to update profile');
      }
    } catch (e) {
      _showError('Error updating profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateEmail(String newEmail) async {
    setState(() => _isLoading = true);
    try {
      await _currentUser!.verifyBeforeUpdateEmail(newEmail);
      await _currentUser!.sendEmailVerification();
      _showMessage('Email updated. Please verify your new email.');
    } catch (e) {
      _showError('Error updating email: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    setState(() => _isLoading = true);
    try {
      if (_newPassword != _confirmPassword) {
        _showError('Passwords do not match');
        return;
      }
      final user = _auth.currentUser;
      final credentials = EmailAuthProvider.credential(
        email: user!.email!,
        password: _oldPassword,
      );
      await user.reauthenticateWithCredential(credentials);
      await user.updatePassword(_newPassword);
      _showMessage('Password updated successfully.');
      setState(() {
        _isPasswordChanging = false;
        _oldPassword = '';
        _newPassword = '';
        _confirmPassword = '';
      });
    } catch (e) {
      _showError('Error updating password: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();

      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 300));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      _showError('Logout failed: $e');
    }
  }

  Future<void> _uploadProfilePhoto() async {
    if (_imageFile == null) return;
    setState(() => _isLoading = true);
    try {
      final token = await _currentUser!.getIdToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:3000/api/users/${_currentUser!.uid}'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath(
        'profilePhoto',
        _imageFile!.path,
      ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);
        setState(() {
          _profilePhotoUrl = data['profilePhotoUrl'];
        });
        _showMessage('Profile photo updated successfully');
      } else {
        _showError('Failed to upload profile photo');
      }
    } catch (e) {
      _showError('Error uploading photo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
    print("Profile Photo URL: $_profilePhotoUrl");
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadProfilePhoto();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  String getEmailPrefix(String email) {
    if (email.isNotEmpty && email.contains('@')) {
      return email.split('@')[0];
    }
    return email;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: const Text('Profile',
            style: TextStyle(
              color: Colors.white,
            )),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome ${_nameController.text.isNotEmpty ? _nameController.text : 'User'}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _profilePhotoUrl != null
                            ? _profilePhotoUrl!.contains(
                                    'data:image')
                                ? MemoryImage(
                                    base64Decode(_profilePhotoUrl!.split(
                                        ',')[1]), 
                                  )
                                : NetworkImage(
                                    _profilePhotoUrl!) 
                            : const AssetImage(
                                    'assets/Icons/default_avatar.png')
                                as ImageProvider,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name Input
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Preferred Language',
                      border: OutlineInputBorder(),
                    ),
                    items: _languages.map((lang) {
                      return DropdownMenuItem(
                        value: lang,
                        child: Text(lang),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedLanguage = value!);
                    },
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: getEmailPrefix(_emailController.text),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Change Password'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Old Password',
                                ),
                                onChanged: (value) => _oldPassword = value,
                              ),
                              TextField(
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'New Password',
                                ),
                                onChanged: (value) => _newPassword = value,
                              ),
                              TextField(
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Retype New Password',
                                ),
                                onChanged: (value) => _confirmPassword = value,
                              ),
                            ],
                          ),
                          actions: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (_newPassword != _confirmPassword) {
                                      Navigator.pop(context);
                                      _showError(
                                          'New password and confirm password do not match');
                                      return;
                                    }

                                    try {
                                      await _updatePassword();
                                      Navigator.pop(context);
                                      _showMessage(
                                          'Password changed successfully!');
                                    } catch (e) {
                                      Navigator.pop(context);
                                      _showError(e.toString());
                                    }
                                  },
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Change Password'),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      _updateEmail(_emailController.text);
                    },
                    child: const Text('Update Email'),
                  ),
                  ElevatedButton(
                    onPressed: _updateUserData,
                    child: const Text('Save Profile'),
                  ),
                ],
              )),
    );
  }
}
