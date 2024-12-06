// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travelcustom/views/destination_detail.dart';
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
      // If no preferred tags are found, return empty list and print a message
      devtools.log("No preferred tags found in interactions");
      return [];
    }

    List<Map<String, dynamic>> fetchedRecommendations =
        await fetchRecommendedDestinations(userId);

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

  Future<void> refreshTravelData() async {
    _getDestinations();
    setState(() {
      _recommendedDestinationsFuture = fetchAndDisplayRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: refreshTravelData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.menu, color: Colors.black),
                    onPressed: () {
                      // Handle menu button press
                    },
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 5),
                      Text(
                        'Babarsari, YK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.black),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SearchPage()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.lightBlueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Let's Discover Around",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Find the best place to visit",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Handle button press
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blueAccent, backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text("Start now"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Categories',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip(Icons.filter, "All"),
                    _buildCategoryChip(Icons.landscape, "Hill"),
                    _buildCategoryChip(Icons.beach_access, "Beach"),
                    _buildCategoryChip(Icons.hotel, "Hotel"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Recommended Locations',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
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
                      child: Text(
                        'Error loading recommendations',
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('No recommended destinations available'));
                  }
                  final recommendedDestinations = snapshot.data!;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.9, // Adjusted aspect ratio for shorter height
                    ),
                    itemCount: recommendedDestinations.length,
                    itemBuilder: (context, index) {
                      var destinationData = recommendedDestinations[index];
                      return _buildRecommendationCard(destinationData);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> destinationData) {
    return GestureDetector(
      onTap: () {
        devtools.log(destinationData.toString());
        String destinationId = destinationData['id'];
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DestinationDetailPage(
              destinationId: destinationId,
              subdestinationId: null,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          image: destinationData['images'] != null &&
                  destinationData['images'].isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(destinationData['images'][0]),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Text(
                  destinationData['destination'] ?? 'No Destination',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Icon(Icons.bookmark, color: Colors.white),
            ),
          ],
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
    destinationData['id'] = doc.id;
    recommendedDestinations.add(destinationData);
  }

  return recommendedDestinations; // Return the matching destinations
}