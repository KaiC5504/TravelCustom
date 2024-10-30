// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:travelcustom/utilities/profile_logic.dart';

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
  File? _imageFile;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    UserProfileMethods.loadUserData(
      userId: userId,
      onDataLoaded: (name, username, email, password, phone, avatarBytes) {
        setState(() {
          _nameController.text = name;
          _usernameController.text = username;
          _emailController.text = email;
          _passwordController.text = password;
          _phoneController.text = phone;
          _avatarBytes = avatarBytes;
          _currentPassword = password;
        });
      },
    );
  }

  Future<void> _pickImage() async {
    // Attempt to pick an image from the gallery
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Attempt to crop the selected image
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            cropStyle: CropStyle.circle,
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            hideBottomControls: true,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            cropStyle: CropStyle.circle,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _imageFile = File(croppedFile.path); // Save the cropped image
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.grey[200],
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[200],
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
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_avatarBytes != null
                              ? MemoryImage(_avatarBytes!)
                              : null) as ImageProvider?,
                      child: _imageFile == null && _avatarBytes == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.black,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.grey[700],
                          ),
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
                onPressed: () async {
                  await UserProfileMethods.saveUserData(
                    userId: userId,
                    context: context,
                    formKey: _formKey,
                    name: _nameController.text,
                    username: _usernameController.text,
                    email: _emailController.text,
                    password: _passwordController.text,
                    phone: _phoneController.text,
                    currentPassword: _currentPassword,
                    imageFile: _imageFile,
                  );
                },
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
