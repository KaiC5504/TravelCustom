// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travelcustom/views/detail_view.dart';
import 'package:travelcustom/views/search_view.dart';
import 'dart:developer' as devtools show log;

class TravelView extends StatefulWidget {
  const TravelView({super.key});

  @override
  State<TravelView> createState() => _TravelViewState();
}

class _TravelViewState extends State<TravelView> {
  List<Map<String, dynamic>> recommendedDestinations = [];
  late Future<List<Map<String, dynamic>>> _recommendedDestinationsFuture;
  Map<String, Uint8List?> destinationImages = {};

  @override
  void initState() {
    super.initState();
    _recommendedDestinationsFuture = fetchAndDisplayRecommendations();
  }

  Future<List<Map<String, dynamic>>> fetchAndDisplayRecommendations() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isEmpty) {
      devtools.log("User not logged in");
      return [];
    }

    // Step 2: Fetch the preferred tags from the interaction collection
    List<String> preferredTags =
        await fetchUserPreferredTagsFromInteractions(userId);

    if (preferredTags.isEmpty) {
      devtools.log("No preferred tags found in interactions");
      return [];
    }

    List<Map<String, dynamic>> fetchedRecommendations =
        await fetchRecommendedDestinations(userId);

    for (var recommendation in fetchedRecommendations) {
      String destinationId = recommendation['id'];

      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('destination_images/$destinationId.png');
        Uint8List? destinationImageBytes = await ref.getData(100000000);
        destinationImages[destinationId] = destinationImageBytes;
      } catch (e) {
        if (e is FirebaseException && e.code == 'object-not-found') {
          devtools.log(
              'No destination image found for destination $destinationId, using default image.');
        } else {
          devtools
              .log('Error fetching image for destination $destinationId: $e');
        }
        destinationImages[destinationId] = null;
      }
    }

    setState(() {
      recommendedDestinations = fetchedRecommendations;
    });

    return fetchedRecommendations;
  }

  // Function to fetch user preferred tags from the interaction collection
  Future<List<String>> fetchUserPreferredTagsFromInteractions(
      String userId) async {
    List<String> preferredTags = [];

    // Query the 'interaction' collection where the 'user_id' matches the current user
    QuerySnapshot interactionSnapshot = await FirebaseFirestore.instance
        .collection('interaction')
        .where('user_id', isEqualTo: userId)
        .get();

    // Loop through the documents in the query result
    for (var doc in interactionSnapshot.docs) {
      var interactionData = doc.data() as Map<String, dynamic>;

      // Extract the tags from the interaction data
      List<String> interactionTags =
          List<String>.from(interactionData['tags'] ?? []);

      // Add the tags to the preferredTags list, avoiding duplicates
      for (String tag in interactionTags) {
        if (!preferredTags.contains(tag)) {
          preferredTags.add(tag); // Only add unique tags
        }
      }
    }

    return preferredTags; // Return the user's preferred tags
  }

  // Fetch the destinations from Firestore
  Stream<QuerySnapshot> _getDestinations() {
    return FirebaseFirestore.instance.collection('destinations').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        toolbarHeight: 0, // Remove default AppBar
      ),
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header: Travel Recommendation
              Center(
                child: Text(
                  'Travel Recommendation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              Text(
                'Malaysia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 10),

              // Fetch and display images from Firestore in horizontal scroll
              StreamBuilder<QuerySnapshot>(
                stream: _getDestinations(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error loading destinations'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No destinations available'));
                  }

                  final destinations = snapshot.data!.docs;

                  return SizedBox(
                    height: 120, // Height for the horizontal list
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: destinations.length,
                      itemBuilder: (context, index) {
                        var destinationDoc = destinations[index];
                        var destinationData =
                            destinations[index].data() as Map<String, dynamic>;
                        String destinationId = destinationDoc.id;

                        if (destinationImages[destinationId] == null) {
                          FirebaseStorage.instance
                              .ref()
                              .child('destination_images/$destinationId.png')
                              .getData(100000000)
                              .then((imageBytes) {
                            if (mounted) {
                              setState(() {
                                destinationImages[destinationId] = imageBytes;
                              });
                            }
                          }).catchError((e) {
                            if (e is FirebaseException &&
                                e.code == 'object-not-found') {
                              devtools.log(
                                  'No destination image found for $destinationId, using default image.');
                            } else {
                              devtools.log(
                                  'Error fetching image for $destinationId: $e');
                            }
                          });
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DetailsPage(
                                  destinationId:
                                      destinationId, // Pass the ID or name
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.grey[200],
                              image:
                                  destinationImages[destinations[index].id] !=
                                          null
                                      ? DecorationImage(
                                          image: MemoryImage(destinationImages[
                                              destinations[index].id]!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                            ),
                            child: Stack(
                              // Use Stack to overlay the text at the bottom center
                              children: [
                                Align(
                                  alignment: Alignment
                                      .bottomCenter, // Align text at the bottom center
                                  child: Container(
                                    width: 150,
                                    padding: const EdgeInsets.all(7.0),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(34, 0, 0, 0),
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(15),
                                        bottomRight: Radius.circular(15),
                                      ),
                                    ),
                                    child: Text(
                                      destinationData['destination'] ??
                                          'No Destination',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              //Search Bar
              GestureDetector(
                onTap: () {
                  // Navigate to Search Page when search bar is tapped
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                },
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 10),
                      Text(
                        'Search for Location',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Recommendation Location
              Text(
                'Recommended Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 10),

              //Fetch Recommended Locations
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _recommendedDestinationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    devtools.log(
                        "Error loading recommendations: ${snapshot.error}");
                    return const Center(
                      child: Text('Error loading recommendations'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No recommended destinations available'),
                    );
                  }

                  final recommendedDestinations = snapshot.data!;

                  return Column(
                    children: recommendedDestinations.map((destinationData) {
                      // Ensure every required field is available
                      if (!destinationData.containsKey('id') ||
                          destinationData['id'] == null) {
                        devtools.log(
                            "Missing or null 'id' for destination data: $destinationData");
                        return SizedBox
                            .shrink(); // Skip rendering this item if ID is missing or null
                      }
                      if (!destinationData.containsKey('destination') ||
                          destinationData['destination'] == null) {
                        devtools.log(
                            "Missing or null 'destination' for destination data: $destinationData");
                        return SizedBox
                            .shrink(); // Skip rendering this item if 'destination' is missing or null
                      }

                      String destinationId = destinationData['id'];
                      String destinationName = destinationData['destination'];

                      // Fetch the image if not already cached
                      if (destinationImages[destinationId] == null) {
                        FirebaseStorage.instance
                            .ref()
                            .child('destination_images/$destinationId.png')
                            .getData(100000000)
                            .then((imageBytes) {
                          if (mounted) {
                            setState(() {
                              destinationImages[destinationId] = imageBytes;
                            });
                          }
                        }).catchError((e) {
                          if (e is FirebaseException &&
                              e.code == 'object-not-found') {
                            devtools.log(
                                'No destination image found for $destinationId, using default image.');
                          } else {
                            devtools.log(
                                'Error fetching image for $destinationId: $e');
                          }
                        });
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DetailsPage(
                                destinationId: destinationId,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 150,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[200],
                            image: destinationImages[destinationId] != null
                                ? DecorationImage(
                                    image: MemoryImage(
                                        destinationImages[destinationId]!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: destinationImages[destinationId] == null
                              ? Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 30,
                                  ),
                                )
                              : Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        padding: const EdgeInsets.all(8.0),
                                        color: Colors.black.withOpacity(0.6),
                                        child: Text(
                                          destinationName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    }).toList(),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Function to fetch recommended destinations based on user interactions
// Function to fetch recommended destinations based on highest preference score and matching tags
Future<List<Map<String, dynamic>>> fetchRecommendedDestinations(
    String userId) async {
  List<Map<String, dynamic>> recommendedDestinations = [];

  // Step 1: Query the interaction collection for the user, ordered by preference_score
  QuerySnapshot interactionSnapshot = await FirebaseFirestore.instance
      .collection('interaction')
      .where('user_id', isEqualTo: userId)
      .orderBy('preference_score', descending: true) // Order by highest score
      .limit(1) // Only get the document with the highest preference_score
      .get();

  if (interactionSnapshot.docs.isEmpty) {
    // No interactions found for the user
    devtools.log("No interactions found for the user");
    return [];
  }

  // Step 2: Get the highest preference_score document
  var highestPreferenceInteraction = interactionSnapshot.docs.first;
  var interactionData =
      highestPreferenceInteraction.data() as Map<String, dynamic>;

  // Extract the tags from the document
  List<String> highestScoreTags =
      List<String>.from(interactionData['tags'] ?? []);

  if (highestScoreTags.isEmpty) {
    // No tags found in the highest score interaction
    devtools.log("No tags found in the highest score interaction");
    return [];
  }

  // Step 3: Search the destinations collection where the tags match the interaction tags
  QuerySnapshot destinationSnapshot = await FirebaseFirestore.instance
      .collection('destinations')
      .where('tags',
          arrayContainsAny:
              highestScoreTags) // Find destinations that match any of the tags
      .get();

  // Step 4: Add matching destinations to the recommendation list
  for (var doc in destinationSnapshot.docs) {
    var destinationData = doc.data() as Map<String, dynamic>;

    // Validate required fields before adding to recommendations
    if (!destinationData.containsKey('destination') ||
        destinationData['destination'] == null) {
      continue; // Skip if "destination" is missing or null
    } else if (!destinationData.containsKey('tags') ||
        destinationData['tags'] == null) {
      continue; // Skip if "tags" is missing or null
    } else {
      // If all fields are valid, add to recommendations
      destinationData['id'] = doc.id;
      recommendedDestinations.add(destinationData);
    }
  }

  return recommendedDestinations; // Return the matching destinations
}
