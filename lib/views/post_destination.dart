// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as devtools show log;

class PostDestinationPage extends StatefulWidget {
  const PostDestinationPage({super.key});

  @override
  State<PostDestinationPage> createState() => _PostDestinationPageState();
}

class _PostDestinationPageState extends State<PostDestinationPage> {
  File? _image;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final List<String> _selectedTags = [];

  Future<void> _pickImage() async {
    // Attempt to pick an image from the gallery
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    } else {
      devtools.log('No image selected.');
    }
  }

  Future<void> _uploadDestination() async {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _image == null ||
        _selectedTags.isEmpty) {
      devtools.log('Please fill all fields and upload an image.');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        devtools.log('User not logged in');
        return;
      }

      final destinationRef =
          FirebaseFirestore.instance.collection('destinations').doc();
      final destinationId = destinationRef.id;

      final destinationData = {
        'author': user.uid,
        'average_rating': 0,
        'description': _descriptionController.text,
        'destination': _nameController.text,
        'images': [],
        'number_of_reviews': 0,
        'post_date': Timestamp.now(),
        'tags': _selectedTags,
      };

      await destinationRef.set(destinationData);
      devtools.log('Destination uploaded successfully');

      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('destination_images/$destinationId.webp');
      await storageRef.putFile(_image!);
      final imageUrl = await storageRef.getDownloadURL();

      // Update destination document with image URL
      await destinationRef.update({
        'images': [imageUrl]
      });
      devtools.log('Image uploaded successfully and URL added to Firestore');

      Navigator.of(context).pop();
    } catch (e) {
      devtools.log('Error uploading destination: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Post Destination'),
        backgroundColor: Colors.grey[200],
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.grey),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.grey),
            onPressed: () {
              _uploadDestination();
              devtools.log('Upload destination');
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                devtools.log('Pick image');
                _pickImage();
              },
              child: Container(
                height: 200.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(10.0),
                  image: _image != null
                      ? DecorationImage(
                          image: FileImage(_image!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Center(
                  child: _image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FontAwesomeIcons.image,
                              size: 50.0,
                              color: Colors.white,
                            ),
                            SizedBox(height: 10.0),
                            Text(
                              'Upload Image',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(height: 20.0),
            Text(
              'Name of Destination',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 20.0),
            Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 20.0),
            Text(
              'Location',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 20.0),
            Text(
              'Tags (Max 2)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                _buildChoiceChip('Urban'),
                _buildChoiceChip('Nightlife'),
                _buildChoiceChip('History'),
                _buildChoiceChip('Art'),
                _buildChoiceChip('Adventure'),
                _buildChoiceChip('Beach'),
                _buildChoiceChip('Nature'),
                _buildChoiceChip('Agriculture'),
                _buildChoiceChip('Island'),
                _buildChoiceChip('Family-friendly'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedTags.contains(label),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            if (_selectedTags.length < 2) {
              _selectedTags.add(label);
            }
          } else {
            _selectedTags.remove(label);
          }
        });
      },
    );
  }
}
