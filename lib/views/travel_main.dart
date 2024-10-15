import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travelcustom/views/detail_view.dart';
import 'package:travelcustom/views/search_view.dart';

class TravelView extends StatefulWidget {
  const TravelView({super.key});

  @override
  State<TravelView> createState() => _TravelViewState();
}

class _TravelViewState extends State<TravelView> {
  // Fetch the destinations from Firestore
  Stream<QuerySnapshot> _getDestinations() {
    return FirebaseFirestore.instance.collection('destinations').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0, // Remove default AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  return const Center(child: Text('No destinations available'));
                }

                final destinations = snapshot.data!.docs;

                return SizedBox(
                  height: 120, // Height for the horizontal list
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      var destinationData =
                          destinations[index].data() as Map<String, dynamic>;

                      return GestureDetector(
                        onTap: () {
                          // Get the document ID for the selected destination
              String destinationId = snapshot.data!.docs[index].id;
                          // Navigate to the detailed page when tapped
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
                            image: destinationData['images'] != null &&
                                    destinationData['images'].isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(
                                        destinationData['images'][0]),
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
                                  padding: const EdgeInsets.all(8.0),
                                  color: const Color.fromARGB(34, 0, 0,
                                      0), // Semi-transparent background for better readability
                                  child: Text(
                                    destinationData['destination'] ??
                                        'No Destination', // Fallback if 'destination' is missing
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
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

            // Placeholder for recommended location card
            Container(
              height: 150,
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Location'),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text('Add to plan'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
