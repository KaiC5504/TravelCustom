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
import 'package:travelcustom/utilities/display_error.dart';

class UserProfileMethods {
  
  static Future<File?> getCachedImage(String imageName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, imageName);
    final file = File(path);
    return await file.exists() ? file : null;
  }

  
  static Future<File> saveImageLocally(
      Uint8List imageBytes, String imageName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, imageName);
    final file = File(path);
    return file.writeAsBytes(imageBytes);
  }

  
  static Future<Uint8List?> getAvatarForProfile(String userId) async {
    File? cachedImage = await getCachedImage('$userId.webp');
    if (cachedImage != null) {
      return await cachedImage.readAsBytes();
    } else {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_pictures/$userId.webp');
        Uint8List? imageBytes = await ref.getData(100000000);
        if (imageBytes != null) {
          await saveImageLocally(
              imageBytes, '$userId.webp'); // Cache downloaded image
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
    required BuildContext context,  
    required Function(String, String, String, String, String, Uint8List?)
        onDataLoaded,
  }) async {
    if (userId == null) {
      devtools.log('User ID is null. The user might not be logged in.');
      displayCustomErrorMessage(
        context,
        'User not logged in. Please sign in again.',
      );
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
      displayCustomErrorMessage(
        context,
        'Failed to load user data. Please try again.',
      );
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
      displayCustomErrorMessage(
        context,
        'Please fill in all required fields correctly.',
      );
      return;
    }

    if (userId == null) {
      displayCustomErrorMessage(
        context,
        'Session expired. Please sign in again.',
      );
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;

      
      if (user != null && user.email != email && email != currentEmail) {
        try {
          await user.updateEmail(email);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            displayCustomErrorMessage(
              context,
              'Please reauthenticate to change email',
            );
            return;
          } else {
            devtools.log('Error updating email: ${e.message}');
            displayCustomErrorMessage(
              context,
              'Failed to update email',
            );
            return;
          }
        }
      }

      if (user != null && password != currentPassword) {
        try {
          await user.updatePassword(password);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            displayCustomErrorMessage(
              context,
              'Please reauthenticate to change password',
            );
            return;
          } else {
            devtools.log('Error updating password: ${e.message}');
            displayCustomErrorMessage(
              context,
              'Failed to update password',
            );
            return;
          }
        }
      }

      if (imageFile != null) {
        try {
          String uniqueFileName = '$userId.webp';
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_pictures/$uniqueFileName');
          await storageRef.putFile(imageFile);

          final imageBytes = await imageFile.readAsBytes();
          await UserProfileMethods.saveImageLocally(imageBytes, uniqueFileName);
        } catch (e) {
          devtools.log('Error uploading image: $e');
          displayCustomErrorMessage(
            context,
            'Failed to upload profile picture',
          );
          return;
        }
      }

    
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'email': email,
        'phone': phone,
        'name': name,
        'username': username,
        'password': password,
      });

      
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      devtools.log('Error updating profile: $e');
      String errorMessage = 'Failed to update profile.';
      if (e is FirebaseAuthException) {
        errorMessage = switch (e.code) {
          'email-already-in-use' => 'This email is already registered.',
          'invalid-email' => 'Please enter a valid email address.',
          'weak-password' => 'Password should be at least 6 characters.',
          'requires-recent-login' => 'Please sign in again to make these changes.',
          _ => e.message ?? errorMessage
        };
      }
      if (context.mounted) {
        displayCustomErrorMessage(context, errorMessage);
      }
    }
  }
}
