import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:developer' as devtools show log;

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Map<String, Uint8List?> destinationImages = {};

  Future<List<DocumentSnapshot>> _getAllSubDestinations() async {
    // Get all destination documents
    QuerySnapshot destinationsSnapshot =
        await FirebaseFirestore.instance.collection('destinations').get();

    List<DocumentSnapshot> allSubDestinations = [];

    // For each destination, get its sub_destinations
    for (var destination in destinationsSnapshot.docs) {
      QuerySnapshot subDestinationsSnapshot =
          await destination.reference.collection('sub_destinations').get();
      allSubDestinations.addAll(subDestinationsSnapshot.docs);
    }

    // Sort by click_count in descending order
    allSubDestinations.sort((a, b) {
      final clickCountA =
          (a.data() as Map<String, dynamic>)['click_count'] ?? 0;
      final clickCountB =
          (b.data() as Map<String, dynamic>)['click_count'] ?? 0;
      return clickCountB.compareTo(clickCountA);
    });

    return allSubDestinations;
  }

  Future<Uint8List?> _loadImage(String destinationId) async {
    try {
      final ref =
          _storage.ref().child('destination_images/$destinationId.webp');
      return await ref.getData(100000000);
    } catch (e) {
      devtools.log('Error loading image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending Locations'),
        backgroundColor: Colors.grey[200],
        scrolledUnderElevation: 0,
      ),
      backgroundColor: Colors.grey[200],
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _getAllSubDestinations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No trending locations found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }
          final locations = snapshot.data!;
          return ListView.builder(
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final locationData =
                  locations[index].data() as Map<String, dynamic>;
              final destinationId = locations[index].id;

              return FutureBuilder<Uint8List?>(
                future: _loadImage(destinationId),
                builder: (context, imageSnapshot) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey[200],
                        image: imageSnapshot.data != null
                            ? DecorationImage(
                                image: MemoryImage(imageSnapshot.data!),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.4),
                                  BlendMode.darken,
                                ),
                              )
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locationData['name'] ?? 'Unknown Location',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Clicks: ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${locationData['click_count'] ?? 0}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (locationData['tags'] != null)
                              RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Tags: ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: locationData['tags'].join(', '),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 21,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
