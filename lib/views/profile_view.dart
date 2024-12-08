// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travelcustom/constants/routes.dart';
import 'dart:developer' as devtools show log;
import 'package:travelcustom/views/favourite_view.dart';
import 'package:travelcustom/views/profile_edit.dart';
import 'package:path/path.dart' as p;
import 'package:travelcustom/views/statistic.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? name;
  String? role;
  Uint8List? avatarBytes;
  bool isLoading = true;

  Future<File?> getCachedImage(String imageName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, imageName);
    final file = File(path);
    if (await file.exists()) {
      return file;
    } else {
      return null;
    }
  }

  Future<File> saveImageLocally(Uint8List imageBytes, String imageName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, imageName);
    final file = File(path);
    return file.writeAsBytes(imageBytes);
  }

  // Fetch user data from Firestore and save locally
  Future<void> fetchUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;

      // Fetch user document from Firestore
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (mounted) {
        setState(() {
          name = userDoc['name'];
          role = userDoc['role']; // Fetch role from Firestore
        });
      }

      await fetchProfileImage(uid);
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Check cache first, then fetch and cache profile image if not available
  Future<void> fetchProfileImage(String uid,
      {bool forceRefresh = false}) async {
    try {
      final ref =
          FirebaseStorage.instance.ref().child('profile_pictures/$uid.webp');
      Uint8List? imageBytes = await ref.getData(100000000);

      if (imageBytes != null) {
        avatarBytes = imageBytes; // Update in-memory image
        await saveImageLocally(imageBytes, '$uid.webp'); // Save to local cache
      }
    } catch (e) {
      devtools.log('Error fetching image: $e');
    }
  }

  // Load user data from local storage
  Future<void> loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('user_name'); // Load name from local storage
      isLoading = false; // Data loaded
    });
  }

  Future<void> refreshProfileData() async {
    await fetchUserData(); // Save name to local storage
  }

  @override
  void initState() {
    super.initState();
    loadUserData(); // Load data from local storage first
    fetchUserData(); // Fetch latest data from Firestore if needed
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (isLoading) {
      // Show a loading indicator while data is being loaded
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (user == null) {
      devtools.log('User is not logged in');
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.grey[200],
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
        backgroundColor: Colors.grey[200],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                'You are not logged in',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    loginRoute,
                    (route) => false,
                  );
                },
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.grey[200],
          elevation: 0,
          centerTitle: true,
        ),
        backgroundColor: Colors.grey[200],
        body: RefreshIndicator(
          onRefresh: refreshProfileData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),

                // Profile Image
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        avatarBytes != null ? MemoryImage(avatarBytes!) : null,
                    child: avatarBytes == null
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.black,
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 20),

                // Display local name instantly if available
                Center(
                  child: Column(
                    children: [
                      Text(
                        name ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (role != null)
                        Text(
                          role!,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(255, 117, 117, 117),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Edit Profile Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor:
                        const Color.fromARGB(255, 114, 114, 114), // Text color
                    side: const BorderSide(
                        color: Color.fromARGB(255, 77, 77, 77), // Border color
                        width: 2.0), // Increased border width
                  ),
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const ProfileEditPage()),
                    );

                    if (result == true) {
                      await refreshProfileData(); // Refresh data after editing
                    }
                  },
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 30),

                // Menu Options
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.map),
                  title: const Text('My Travelling Plan'),
                  onTap: () {}, // Placeholder for future function
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_outline),
                  title: const Text('Favourites'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const FavouritePage()),
                    );
                  },
                ),
                if (role == 'Travel Agency')
                  ListTile(
                    leading: const Icon(Icons.bar_chart),
                    title: const Text('Statistics'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const StatisticPage()),
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    bool confirmLogout = await showLogoutDialog(context);
                    if (confirmLogout) {
                      await FirebaseAuth.instance.signOut();

                      final SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.remove('user_name');

                      Navigator.of(context).pushNamedAndRemoveUntil(
                        naviRoute,
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<bool> showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }
}
