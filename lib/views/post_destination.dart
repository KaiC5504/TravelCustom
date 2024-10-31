// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:developer' as devtools show log;
import 'package:path_provider/path_provider.dart';

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
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);

      // Check if the file exists to prevent errors
      if (!(await imageFile.exists())) {
        devtools.log('File does not exist: ${imageFile.path}');
        return;
      }

      const int maxSizeInBytes = 100 * 1024; // Target size 100 KB
      int fileSize = await imageFile.length();
      devtools.log('File size: ${fileSize / (1024 * 1024)} MB');

      // Only compress if the file is larger than 100 KB
      if (fileSize > maxSizeInBytes) {
        int quality;

        if (fileSize <= 0.5 * 1024 * 1024) {
          quality = 40;
        } else if (fileSize <= 1 * 1024 * 1024) {
          // 1 MB or less
          quality = 80;
        } else if (fileSize <= 2 * 1024 * 1024) {
          // 1 MB - 2 MB
          quality = 75;
        } else if (fileSize <= 3 * 1024 * 1024) {
          // 2 MB - 3 MB
          quality = 87;
        } else if (fileSize <= 4 * 1024 * 1024) {
          // 3 MB - 4 MB
          quality = 80;
        } else if (fileSize <= 18 * 1024 * 1024) {
          // 4 MB - 18 MB
          quality = 40;
        } else {
          quality = 10;
        }

        try {
          // Compress and convert to WEBP
          final Uint8List? compressedImage =
              await FlutterImageCompress.compressWithFile(
            imageFile.path,
            format: CompressFormat.webp,
            quality: quality,
          );

          if (compressedImage != null) {
            final tempDir = await getTemporaryDirectory();
            final tempFile = File(
                '${tempDir.path}/compressed_image_${DateTime.now().millisecondsSinceEpoch}.webp');
            await tempFile.writeAsBytes(compressedImage);

            imageFile = tempFile;
          } else {
            devtools.log('Compression failed.');
            return;
          }
        } catch (e) {
          devtools.log('Error accessing or compressing file: $e');
          return;
        }
      }

      // Log final file size after conditional compression
      int finalSize = await imageFile.length();
      devtools.log(
          'File size after conditional compression (if applied): ${finalSize / (1024 * 1024)} MB');

      setState(() {
        _image = imageFile;
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
        'location': _locationController.text,
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
          icon: Icon(Icons.menu, color: const Color.fromARGB(255, 42, 42, 42)),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon:
                Icon(Icons.check, color: const Color.fromARGB(255, 42, 42, 42)),
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
                key: ValueKey(_image?.path),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(10.0),
                  image: _image != null
                      ? DecorationImage(
                          image: FileImage(_image!), // No key needed here
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
