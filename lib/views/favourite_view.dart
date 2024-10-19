import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;
import 'package:travelcustom/views/detail_view.dart';

class FavouritePage extends StatefulWidget {
  const FavouritePage({super.key});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  late Future<List<Map<String, dynamic>>> _favouritesFuture;

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
            destinationData['id'] = destinationDoc.id; // Use document ID
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
      ),
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

                return GestureDetector(
                  onTap: () async {
                    // Navigate to the detailed page when tapped
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DetailsPage(
                          destinationId: destination['id'],
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
                        image: destination['images'] != null
                            ? DecorationImage(
                                image: NetworkImage(destination['images'][0]),
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
