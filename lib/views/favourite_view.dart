import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:travelcustom/views/detail_view.dart';
import 'dart:developer' as devtools show log;

class FavouritePage extends StatefulWidget {
  const FavouritePage({super.key});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  late Future<List<Map<String, dynamic>>> _favouritesFuture;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Map<String, Uint8List?> destinationImages = {};

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  void _loadFavourites() {
    _favouritesFuture = _getFavourites();
  }

  // Method to retrieve the favourite destinations from Firestore
  Future<List<Map<String, dynamic>>> _getFavourites() async {
    List<Map<String, dynamic>> favouriteDestinations = [];
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      // Retrieve user's document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // Check if the document exists and contains a 'favourites' field
      if (userDoc.exists && userDoc['favourites'] != null) {
        List<dynamic> favourites = userDoc['favourites'];

        // Retrieve matching destinations from 'destinations' collection
        for (String destinationId in favourites) {
          DocumentSnapshot destinationDoc = await FirebaseFirestore.instance
              .collection('destinations')
              .doc(destinationId)
              .get();

          if (destinationDoc.exists) {
            Map<String, dynamic> destinationData =
                destinationDoc.data() as Map<String, dynamic>;
            destinationData['id'] = destinationDoc.id;

            try {
              final ref =
                  _storage.ref().child('destination_images/$destinationId.webp');
              Uint8List? destinationImageBytes = await ref.getData(100000000);
              destinationImages[destinationId] = destinationImageBytes;
            } catch (e) {
              if (e is FirebaseException && e.code == 'object-not-found') {
                devtools.log(
                    'No destination image found for $destinationId, using default image.');
              } else {
                devtools.log('Error fetching image for $destinationId: $e');
              }
            }

            favouriteDestinations.add(destinationData);
          }
        }
      }
    } catch (e) {
      devtools.log('Error fetching favourites: $e');
    }

    return favouriteDestinations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Favourites'),
        backgroundColor: Colors.grey[200],
        scrolledUnderElevation: 0,
      ),
      backgroundColor: Colors.grey[200],
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _favouritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No favourites found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          } else {
            List<Map<String, dynamic>> favourites = snapshot.data!;

            return ListView.builder(
              itemCount: favourites.length,
              itemBuilder: (context, index) {
                var destination = favourites[index];
                String destinationId = destination['id'];
                Uint8List? destinationImage = destinationImages[destinationId];

                return GestureDetector(
                  onTap: () async {
                    // Navigate to the detailed page when tapped
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DetailsPage(
                          destinationId: destinationId,
                        ),
                      ),
                    );
                    //Reload widget
                    setState(() {
                      _loadFavourites();
                    });
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey[200],
                        image: destinationImage != null
                            ? DecorationImage(
                                image: MemoryImage(destinationImage),
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
                              destination['destination'] ??
                                  'Unknown Destination',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Additional destination details can be added here
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
