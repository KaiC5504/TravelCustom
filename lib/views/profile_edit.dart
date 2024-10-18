// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as devtools show log;

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  //User profile forms
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _obscurePassword = false;
  String? _currentPassword;

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        _nameController.text = userData['name'] ?? '';
        _usernameController.text = userData['username'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _passwordController.text = userData['password'] ?? '';
        _phoneController.text = userData['phone'] ?? '';

        _currentPassword = _passwordController.text;
      }
    } catch (e) {
      devtools.log('Error fetching user data: $e');
    }
  }

  // Save updated user data back to Firestore
  Future<void> _saveUserData() async {
    // Check if form validation passes
    if (_formKey.currentState?.validate() ?? false) {
      try {
        if (userId != null) {
          //Update user profile
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'email': _emailController.text,
            'phone': _phoneController.text,
            'name': _nameController.text,
            'username': _usernameController.text,
            'password': _passwordController.text,
          });

          //Update password if changed
          if (_passwordController.text != _currentPassword) {
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await user.updatePassword(_passwordController.text);
              devtools.log('Password updated successfully');
            }
          } else {
            devtools.log('Password not updated');
          }

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception("User ID is null. The user might not be logged in.");
        }
      } catch (e) {
        devtools.log('Error updating profile: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update profile. Please try again.')),
        );
      }
    } else {
      // If validation fails, display a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please correct the errors in the form.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    // Circular profile picture
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.black,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildProfileField("NAME", _nameController, false),

              const SizedBox(height: 16),

              _buildProfileField("USERNAME", _usernameController, false),
              const SizedBox(height: 16),

              _buildProfileField("YOUR EMAIL", _emailController, false),

              const SizedBox(height: 16),

              _buildPasswordField(),

              const SizedBox(height: 16),

              _buildProfileField("YOUR PHONE", _phoneController, false),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveUserData,
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build profile text field with a label
  Widget _buildProfileField(
      String label, TextEditingController controller, bool isPassword,
      {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          readOnly: readOnly,
          decoration: InputDecoration(
            border: UnderlineInputBorder(),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
          style: TextStyle(fontSize: 18),
          // Adjust validation rules
          validator: (value) {
            if (label == "YOUR EMAIL") {
              // Email validation
              if (value == null || value.isEmpty) {
                return 'Email cannot be empty';
              }
              // Check if the email format is valid
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(value)) {
                return 'Please enter a valid email';
              }
            } else if (label == "YOUR PASSWORD") {
              if (!readOnly && (value == null || value.isEmpty)) {
                return 'Password cannot be empty';
              }
            } else if (label == "YOUR USERNAME") {
              if (value != null && value.isNotEmpty && value.length < 10) {
                return 'Please enter a username';
              }
            } else if (label == "NAME" || label == "COUNTRY") {
              return null;
            }
            return null;
          },
        ),
      ],
    );
  }

  // Helper method to build password field with a toggle button
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "YOUR PASSWORD",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText:
              _obscurePassword, // Control visibility with _obscurePassword
          decoration: InputDecoration(
            border: UnderlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword; // Toggle visibility
                });
              },
            ),
          ),
          style: TextStyle(fontSize: 18),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password cannot be empty';
            }
            return null;
          },
        ),
      ],
    );
  }
}
