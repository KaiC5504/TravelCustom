import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travelcustom/utilities/content_filter.dart';
import 'dart:developer' as devtools show log;

class DetailsPage extends StatefulWidget {
  final String destinationId;

  const DetailsPage({super.key, required this.destinationId});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  bool _interactionRecorded = false;

  @override
  void initState() {
    super.initState();
  }

  // Method to fetch destination details from Firestore by document ID
  Future<DocumentSnapshot> _getDestinationDetails() async {
    return FirebaseFirestore.instance
        .collection('destinations')
        .doc(widget.destinationId)
        .get();
  }

  // Function to track user interaction
  void trackUserViewInteraction(Map<String, dynamic> destinationData) {
    // Get the user ID from Firebase Auth
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      String destinationId = widget.destinationId;

      // Check if 'tags' exists and is not null
      if (destinationData['tags'] != null && destinationData['tags'] is List) {
        List<String> destinationTypes =
            List<String>.from(destinationData['tags']);

        // Call the trackUserInteraction function
        trackUserInteraction(userId, destinationId, destinationTypes, 'view');
      } else {
        // Handle the case where 'tags' is missing or not a list
        devtools.log('tags is missing or not a valid list.');
      }
    } else {
      // User not logged in
      devtools.log('User is not logged in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Destination Details'),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _getDestinationDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(), // Loading indicator in the center
            );
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading details'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Destination not found'));
          }

          final destinationData = snapshot.data!.data() as Map<String, dynamic>;

          // Record interaction if not already recorded
          if (!_interactionRecorded) {
            trackUserViewInteraction(destinationData);
            _interactionRecorded = true;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image of the location
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: destinationData['images'] != null &&
                            (destinationData['images'] as List).isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(destinationData['images'][0]),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Align(
                    alignment:
                        Alignment.topLeft, // Align the text to the top left
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        destinationData['destination'] ?? 'Location in KL',
                        style: const TextStyle(
                          color: Colors.white,
                          backgroundColor: Colors.transparent,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Details about the location
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    const Text(
                      'Description:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      destinationData['description'] ?? '-',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Best Time to Visit
                    const Text(
                      'Best Time to Visit:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      destinationData['best_time_to_visit'] ?? '-',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Average Rating
                    const Text(
                      'Average Rating:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      destinationData['average_rating']?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Popular Attractions
                    const Text(
                      'Popular Attractions:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (destinationData['popular_attractions']
                                  as List<dynamic>?)
                              ?.map((attraction) => Text(
                                    attraction,
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ))
                              .toList() ??
                          [const Text('-')],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
