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
import 'package:travelcustom/views/planning.dart';

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

  Future<void> fetchUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;

      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (mounted) {
        setState(() {
          name = userDoc['name'];
          role = userDoc['role'];
        });
      }

      await fetchProfileImage(uid);
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Check cache and fetch
  Future<void> fetchProfileImage(String uid,
      {bool forceRefresh = false}) async {
    try {
      final ref =
          FirebaseStorage.instance.ref().child('profile_pictures/$uid.webp');
      Uint8List? imageBytes = await ref.getData(100000000);

      if (imageBytes != null) {
        avatarBytes = imageBytes;
        await saveImageLocally(imageBytes, '$uid.webp');
      }
    } catch (e) {
      devtools.log('Error fetching image: $e');
    }
  }

  Future<void> loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (mounted) {
      setState(() {
        name = prefs.getString('user_name');
        isLoading = false;
      });
    }
  }

  Future<void> refreshProfileData() async {
    await fetchUserData();
  }

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await loadUserData();
      await fetchUserData();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || isLoading) {
          return Scaffold(
            backgroundColor: Colors.grey[200],
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

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
          body: !snapshot.hasData
              ? Center(
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
                )
              : RefreshIndicator(
                  onRefresh: refreshProfileData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: avatarBytes != null
                                ? MemoryImage(avatarBytes!)
                                : null,
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
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                const Color.fromARGB(255, 114, 114, 114),
                            side: const BorderSide(
                                color: Color.fromARGB(255, 77, 77, 77),
                                width: 2.0),
                          ),
                          onPressed: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ProfileEditPage()),
                            );

                            if (result == true) {
                              await refreshProfileData();
                            }
                          },
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ListTile(
                          leading: const FaIcon(FontAwesomeIcons.map),
                          title: const Text('My Travelling Plan'),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PlanningView(),
                              ),
                            );
                          },
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
                                    builder: (context) =>
                                        const StatisticPage()),
                              );
                            },
                          ),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Logout'),
                          onTap: () async {
                            bool confirmLogout =
                                await showLogoutDialog(context);
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
      },
    );
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
