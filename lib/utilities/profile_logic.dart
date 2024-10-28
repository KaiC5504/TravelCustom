// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:developer' as devtools show log;

class UserProfileMethods {
  static Future<void> loadUserData({
    required String? userId,
    required Function(
            String, String, String, String, String, String?, Uint8List?)
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
        String? profileImageUrl = userData['profileImageUrl'];
        Uint8List? avatarBytes;

        if (profileImageUrl != null) {
          avatarBytes = await getAvatarUrlForProfile(profileImageUrl);
        }

        onDataLoaded(name, username, email, password, phone, profileImageUrl,
            avatarBytes);
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
      String? profileImageUrl;
      if (imageFile != null) {
        String uniqueFileName = '$userId.png';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures/$uniqueFileName');
        await storageRef.putFile(imageFile);
        profileImageUrl = uniqueFileName;
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'email': email,
        'phone': phone,
        'name': name,
        'username': username,
        'password': password,
        'profileImageUrl': profileImageUrl,
      });

      if (password != currentPassword) {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updatePassword(password);
          devtools.log('Password updated successfully');
        }
      }

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

  static Future<Uint8List> getAvatarUrlForProfile(String imageFileName) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/$imageFileName');
      Uint8List? imageBytes = await ref.getData(100000000);
      if (imageBytes == null) {
        throw Exception('Failed to load image');
      }
      return imageBytes;
    } catch (e) {
      devtools.log('Error fetching image: $e');
      rethrow;
    }
  }
}
