import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:travelcustom/utilities/content_filter.dart';
import 'dart:developer' as devtools show log;

class DetailsPage extends StatefulWidget {
  final String destinationId;
  final bool isFavourited; // Add this line

  const DetailsPage(
      {super.key,
      required this.destinationId,
      this.isFavourited = false}); // Modify this line

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  bool _isFavourited = false;
  bool _interactionRecorded = false;

  @override
  void initState() {
    super.initState();
    _isFavourited = widget.isFavourited;
    _checkIfFavourited();
  }

  void _toggleFavourite() {
    setState(() {
      _isFavourited = !_isFavourited;
    });

    // Get the user ID from Firebase Auth
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      if (_isFavourited) {
        userDocRef.update({
          'favourites': FieldValue.arrayUnion([widget.destinationId])
        }).then((_) {
          devtools.log('Favourite added successfully');
        }).catchError((error) {
          devtools.log('Failed to add favourite: $error');
        });
      } else {
        userDocRef.update({
          'favourites': FieldValue.arrayRemove([widget.destinationId])
        }).then((_) {
          devtools.log('Favourite removed successfully');
        }).catchError((error) {
          devtools.log('Failed to remove favourite: $error');
        });
      }
    } else {
      devtools.log('User is not logged in');
    }
    // You can also update Firebase or the database here when the user toggles favorite status
    // For example:
    // updateFavoriteStatusInFirebase(widget.placeId, _isFavorited);
  }

  void _checkIfFavourited() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        List<dynamic> favourites = userDoc['favourites'] ?? [];
        setState(() {
          _isFavourited = favourites.contains(widget.destinationId);
        });
      }
    } else {
      devtools.log('User is not logged in');
    }
  }

  // Method to fetch destination details from Firestore by document ID
  Future<DocumentSnapshot> _getDestinationDetails() async {
    return FirebaseFirestore.instance
        .collection('destinations')
        .doc(widget.destinationId)
        .get();
  }

  // Function to track user interaction
  void trackUserViewInteraction(Map<String, dynamic> destinationData) async {
    // Get the user ID from Firebase Auth
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      String destinationId = widget.destinationId;

      // Check if 'tags' exists and is not null
      if (destinationData['tags'] != null && destinationData['tags'] is List) {
        List<String> destinationTypes =
            List<String>.from(destinationData['tags']);

        // Call the trackUserInteraction function
        await trackUserInteraction(
            userId, destinationId, destinationTypes, 'view');
        showUserPreferences(userId);
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
                  child: Stack(
                    children: [
                      Align(
                        alignment:
                            Alignment.topLeft, // Align the text to the top left
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            destinationData['destination'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              backgroundColor: Colors.transparent,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: _toggleFavourite,
                          icon: FaIcon(
                            FontAwesomeIcons.solidStar,
                            color: _isFavourited
                                ? Colors.yellow
                                : const Color.fromARGB(255, 169, 169, 169)
                                    .withOpacity(0.7),
                            size: 36.0,
                          ),
                        ),
                      ),
                    ],
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
