import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailsPage extends StatelessWidget {
  final String destinationId;

  const DetailsPage({super.key, required this.destinationId});

  // Method to fetch destination details from Firestore by document ID
  Future<DocumentSnapshot> _getDestinationDetails() async {
    return FirebaseFirestore.instance
        .collection('destinations')
        .doc(destinationId)
        .get();
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading details'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Destination not found'));
          }

          final destinationData = snapshot.data!.data() as Map<String, dynamic>;

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
                    alignment: Alignment.topLeft, // Align the text to the top left
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        destinationData['destinations'] ?? 'Location in KL',
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

                const SizedBox(height: 20),

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
                    const SizedBox(height: 10),

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
                    const SizedBox(height: 10),

                    // Country
                    const Text(
                      'Country:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      destinationData['country'] ?? '-',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),

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
                    const SizedBox(height: 10),

                    // Popular Attractions
                    const Text(
                      'Popular Attractions:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      (destinationData['popular_attractions'] as List<dynamic>?)
                              ?.join(', ') ??
                          '-',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
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
