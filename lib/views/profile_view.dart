import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
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
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Username
            const Center(
              child: Text(
                'Name',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Menu Options
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Name'),
              onTap: () {}, // Placeholder for future function
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.map),
              title: const Text('My Travelling Plan'),
              onTap: () {}, // Placeholder for future function
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text('Favourite'),
              onTap: () {}, // Placeholder for future function
            ),
          ],
        ),
      ),
    );
  }
}
