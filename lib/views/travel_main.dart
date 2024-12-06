// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travelcustom/views/destination_detail.dart';
import 'package:travelcustom/views/search_view.dart';
import 'dart:developer' as devtools show log;
import 'package:timeago/timeago.dart' as timeago;
import 'package:travelcustom/views/planning.dart';

class TravelView extends StatefulWidget {
  const TravelView({super.key});

  @override
  State<TravelView> createState() => _TravelViewState();
}

class _TravelViewState extends State<TravelView> {
  List<Map<String, dynamic>> recommendedDestinations = [];
  late Future<List<Map<String, dynamic>>> _recommendedDestinationsFuture;
  late Future<List<Map<String, dynamic>>> _recommendedPlansFuture;

  @override
  void initState() {
    super.initState();
    _recommendedDestinationsFuture = fetchAndDisplayRecommendations();
    _recommendedPlansFuture =
        fetchRecommendedPlans(FirebaseAuth.instance.currentUser?.uid ?? '');
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

  // Stream<QuerySnapshot> _getDestinations() {
  //   return FirebaseFirestore.instance.collection('destinations').snapshots();
  // }

  Future<void> refreshTravelData() async {
    setState(() {
      _recommendedDestinationsFuture = fetchAndDisplayRecommendations();
      _recommendedPlansFuture =
          fetchRecommendedPlans(FirebaseAuth.instance.currentUser?.uid ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: RefreshIndicator(
        onRefresh: refreshTravelData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60), // Increased top padding
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.menu,
                        color: Colors.black, size: 30), // Increased size
                    onPressed: () {
                      // Handle menu button press
                    },
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Colors.red, size: 30), // Increased size
                      const SizedBox(width: 5),
                      Text(
                        'Malaysia',
                        style: TextStyle(
                          fontSize: 18, // Increased font size
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.search,
                        color: Colors.black, size: 30), // Increased size
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const SearchPage()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Discover Malaysia",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "States in Malaysia",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text("Explore Now"),
                      ),
                    ],
                  ),
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
                    _buildCategoryChip(
                        Icons.location_city, "Urban", Colors.blue),
                    _buildCategoryChip(
                        Icons.nightlife, "Nightlife", Colors.purple),
                    _buildCategoryChip(
                        Icons.history_edu, "History", Colors.brown),
                    _buildCategoryChip(Icons.brush, "Art", Colors.pink),
                    _buildCategoryChip(
                        Icons.hiking, "Adventure", Colors.orange),
                    _buildCategoryChip(
                        Icons.beach_access, "Beach", Colors.cyan),
                    _buildCategoryChip(Icons.nature, "Nature", Colors.green),
                    _buildCategoryChip(
                        Icons.agriculture, "Agriculture", Colors.teal),
                    _buildCategoryChip(
                        Icons.landscape, "Island", Colors.lightBlue),
                    _buildCategoryChip(
                        Icons.family_restroom, "Family-friendly", Colors.red),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Recommended Locations',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

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
                      childAspectRatio:
                          0.9, // Adjusted aspect ratio for shorter height
                    ),
                    itemCount: recommendedDestinations.length,
                    itemBuilder: (context, index) {
                      var destinationData = recommendedDestinations[index];
                      return _buildRecommendationCard(destinationData);
                    },
                  );
                },
              ),
              const SizedBox(height: 30),
              Text(
                'Recommended Plans',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _recommendedPlansFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('No recommended plans available'));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var planData = snapshot.data![index];
                      return _buildPlanCard(planData);
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

  Widget _buildCategoryChip(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SearchPage(
              fromLocationButton: false,
              initialTags: [label],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(30), // Oval shape
          border: Border.all(color: color, width: 1), // Light border
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 30), // Icon at the top center
            const SizedBox(height: 5), // Spacing between icon and text
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Sans-serif', // Clean, rounded, and sans-serif font
              ),
              textAlign: TextAlign.center, // Centered text
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> destinationData) {
    return GestureDetector(
      onTap: () {
        devtools.log(destinationData.toString());
        String destinationId =
            destinationData['destinationId'] ?? ''; // Main destination ID
        String subdestinationId =
            destinationData['id'] ?? ''; // Sub-destination ID
        if (destinationId.isNotEmpty && subdestinationId.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DestinationDetailPage(
                destinationId: destinationId,
                subdestinationId: subdestinationId,
              ),
            ),
          );
        } else {
          devtools.log('Missing destinationId or subdestinationId');
        }
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
          image: destinationData['image'] != null &&
                  destinationData['image'].isNotEmpty
              ? DecorationImage(
                  image:
                      NetworkImage(destinationData['image']), // Updated field
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
                  destinationData['name'] ?? 'No Destination', // Updated field
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
              child:
                  Icon(Icons.star, color: Colors.white), // Changed to star icon
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> planData) {
    List<dynamic> days = planData['days'];
    String timeAgo =
        timeago.format((planData['postDate'] as Timestamp).toDate());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        elevation: 4.0,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PlanningView(
                  planId: planData['planId'],
                  collectionName: 'platform_plans',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      planData['planName'],
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18.0),
                    ),
                    Spacer(),
                    Text(
                      timeAgo,
                      style: TextStyle(color: Colors.grey, fontSize: 12.0),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  'By ${planData['authorName']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12.0),
                ...days.take(2).map((day) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day['dayTitle'] ?? 'No Title',
                          style: TextStyle(
                              fontSize: 16.0, fontWeight: FontWeight.w500),
                        ),
                        if ((day['sideNotes'] as List).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                            child: Text(
                              day['sideNotes'][0],
                              style: TextStyle(
                                  fontSize: 14.0, color: Colors.grey[700]),
                            ),
                          ),
                        const SizedBox(height: 8.0),
                      ],
                    )),
                if (days.length > 2)
                  Text(
                    "...",
                    style: TextStyle(fontSize: 16.0, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Function to fetch recommended destinations based on user interactions
Future<List<Map<String, dynamic>>> fetchRecommendedDestinations(
    String userId) async {
  List<Map<String, dynamic>> recommendedDestinations = [];

  // Step 1: Query the interaction collection for the user, ordered by preference_score
  QuerySnapshot interactionSnapshot = await FirebaseFirestore.instance
      .collection('interaction')
      .where('user_id', isEqualTo: userId)
      .orderBy('preference_score', descending: true)
      .limit(1)
      .get();

  if (interactionSnapshot.docs.isEmpty) {
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
    devtools.log("No tags found in the highest score interaction");
    return [];
  }

  // Step 3: Search the sub_destinations sub-collection where the tags match the interaction tags
  QuerySnapshot destinationSnapshot = await FirebaseFirestore.instance
      .collectionGroup('sub_destinations')
      .where('tags', arrayContainsAny: highestScoreTags)
      .get();

  // Step 4: Add matching sub-destinations to the recommendation list
  for (var doc in destinationSnapshot.docs) {
    var destinationData = doc.data() as Map<String, dynamic>;
    destinationData['id'] = doc.id;
    destinationData['destinationId'] = doc.reference.parent.parent?.id;
    recommendedDestinations.add(destinationData);
  }

  return recommendedDestinations;
}

// Function to fetch recommended plans based on user interactions
Future<List<Map<String, dynamic>>> fetchRecommendedPlans(String userId) async {
  devtools.log('Starting fetchRecommendedPlans for userId: $userId');

  if (userId.isEmpty) {
    devtools.log('Error: userId is empty');
    return [];
  }

  try {
    // Get user's highest scoring interaction
    QuerySnapshot interactionSnapshot = await FirebaseFirestore.instance
        .collection('interaction')
        .where('user_id', isEqualTo: userId)
        .orderBy('preference_score', descending: true)
        .limit(1)
        .get();

    if (interactionSnapshot.docs.isEmpty) {
      devtools.log('No interactions found for user');
      return [];
    }

    var interactionData =
        interactionSnapshot.docs.first.data() as Map<String, dynamic>;
    devtools.log(
        'Found interaction with score: ${interactionData['preference_score']}');

    List<String> highestScoreTags =
        List<String>.from(interactionData['tags'] ?? []);
    devtools.log('Extracted tags: $highestScoreTags');

    if (highestScoreTags.isEmpty) {
      devtools.log('No tags found in interaction');
      return [];
    }

    // Query platform_plans
    QuerySnapshot planSnapshot = await FirebaseFirestore.instance
        .collection('platform_plans')
        .where('tags', arrayContainsAny: highestScoreTags)
        .orderBy('post_date', descending: true)
        .limit(5)
        .get();

    devtools.log('Found ${planSnapshot.docs.length} matching plans');

    List<Map<String, dynamic>> recommendedPlans = [];

    for (var doc in planSnapshot.docs) {
      var planData = doc.data() as Map<String, dynamic>;
      devtools.log('Processing plan: ${planData['plan_name']}');

      try {
        var authorDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(planData['userId'])
            .get();

        if (!authorDoc.exists) {
          devtools.log(
              'Author document not found for userId: ${planData['userId']}');
          continue;
        }

        List<Map<String, dynamic>> daysData = [];
        if (planData['days'] != null) {
          List<dynamic> days = List<dynamic>.from(planData['days']);
          for (var day in days) {
            daysData.add({
              'dayTitle': day['day_title'] ?? 'No Title',
              'sideNotes': List<String>.from(day['side_note'] ?? []),
            });
          }
        }

        recommendedPlans.add({
          'planId': doc.id,
          'planName': planData['plan_name'],
          'authorName': (authorDoc.data() as Map<String, dynamic>)['name'],
          'days': daysData,
          'postDate': planData['post_date'],
        });

        devtools.log('Successfully added plan: ${planData['plan_name']}');
      } catch (e) {
        devtools.log('Error processing plan ${planData['plan_name']}: $e');
      }
    }

    devtools.log('Returning ${recommendedPlans.length} recommended plans');
    return recommendedPlans;
  } catch (e) {
    devtools.log('Error in fetchRecommendedPlans: $e');
    return [];
  }
}
