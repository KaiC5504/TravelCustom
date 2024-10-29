// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:developer' as devtools show log;

class UserProfileMethods {
  // Retrieve cached image if it exists
  static Future<File?> getCachedImage(String imageName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, imageName);
    final file = File(path);
    return await file.exists() ? file : null;
  }

  // Save image to local storage
  static Future<File> saveImageLocally(
      Uint8List imageBytes, String imageName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, imageName);
    final file = File(path);
    return file.writeAsBytes(imageBytes);
  }

  // Update `getAvatarForProfile` to check the cache first
  static Future<Uint8List?> getAvatarForProfile(String userId) async {
    File? cachedImage = await getCachedImage('$userId.png');
    if (cachedImage != null) {
      return await cachedImage.readAsBytes();
    } else {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_pictures/$userId.png');
        Uint8List? imageBytes = await ref.getData(100000000);
        if (imageBytes != null) {
          await saveImageLocally(
              imageBytes, '$userId.png'); // Cache downloaded image
        }
        return imageBytes;
      } catch (e) {
        devtools.log('Error fetching image: $e');
        return null;
      }
    }
  }

  static Future<void> loadUserData({
    required String? userId,
    required Function(String, String, String, String, String, Uint8List?)
        onDataLoaded,
  }) async {
    if (userId == null) {
      devtools.log('User ID is null. The user might not be logged in.');
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String name = userData['name'] ?? '';
        String username = userData['username'] ?? '';
        String email = userData['email'] ?? '';
        String password = userData['password'] ?? '';
        String phone = userData['phone'] ?? '';

        Uint8List? avatarBytes = await getAvatarForProfile(userId);

        onDataLoaded(name, username, email, password, phone, avatarBytes);
      }
    } catch (e) {
      devtools.log('Error fetching user data: $e');
    }
  }

  static Future<void> saveUserData({
    required String? userId,
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required String name,
    required String username,
    required String email,
    required String password,
    required String phone,
    String? currentPassword,
    String? currentEmail,
    File? imageFile,
  }) async {
    if (!(formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please correct the errors in the form.')),
      );
      return;
    }

    if (userId == null) {
      devtools.log('User ID is null. The user might not be logged in.');
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && user.email != email && email != currentEmail) {
        try {
          await user.updateEmail(email);
          devtools
              .log('Verification email sent to update email in Firebase Auth');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please reauthenticate to change email.')),
            );
            return;
          } else {
            devtools.log('Error updating email: ${e.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update email.')),
            );
            return;
          }
        }
      }

      if (user != null && password != currentPassword) {
        try {
          await user.updatePassword(password);
          devtools.log('Password updated successfully');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Please reauthenticate to change password.')),
            );
          } else {
            devtools.log('Error updating password: ${e.message}');
          }
          return; // Exit if password update fails
        }
      }

      if (imageFile != null) {
        String uniqueFileName = '$userId.png';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures/$uniqueFileName');
        await storageRef.putFile(imageFile);

        final imageBytes = await imageFile.readAsBytes();
        await UserProfileMethods.saveImageLocally(imageBytes, uniqueFileName);
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'email': email,
        'phone': phone,
        'name': name,
        'username': username,
        'password': password,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
      }
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      devtools.log('Error updating profile: $e');
      if (e is FirebaseAuthException && e.code == "requires-recent-login") {
        rethrow;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to update profile. Please try again.')),
          );
        }
      }
    }
  }
}
