import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as devtools show log;
import 'package:travelcustom/utilities/content_filter.dart';

class DestinationContent {
  Future<bool> checkIfFavourited(String destinationId) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      devtools.log('User is not logged in');
      return false;
    }

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      List<dynamic> favourites = userDoc['favourites'] ?? [];
      return favourites.contains(destinationId);
    }
    return false;
  }

  Future<void> toggleFavourite(String destinationId, bool isFavourited) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      devtools.log('User is not logged in');
      return;
    }

    DocumentReference userDocRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    try {
      if (isFavourited) {
        await userDocRef.update({
          'favourites': FieldValue.arrayUnion([destinationId])
        });
        devtools.log('Favourite added successfully');
      } else {
        await userDocRef.update({
          'favourites': FieldValue.arrayRemove([destinationId])
        });
        devtools.log('Favourite removed successfully');
      }
    } catch (error) {
      devtools.log('Failed to update favourite: $error');
    }
  }

  Future<DocumentSnapshot> getDestinationDetails(String destinationId) async {
    try {
      DocumentSnapshot destinationDoc = await FirebaseFirestore.instance
          .collection('destinations')
          .doc(destinationId)
          .get();
      if (destinationDoc.exists) {
        return destinationDoc;
      } else {
        throw Exception('Destination not found');
      }
    } catch (e) {
      devtools.log('Error fetching destination details: $e');
      rethrow;
    }
  }

  Future<Uint8List?> getDestinationImage(String destinationId) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('destination_images/$destinationId.webp');
      return await ref.getData(100000000);
    } catch (e) {
      if (e is FirebaseException && e.code == 'object-not-found') {
        devtools.log('No destination image found for $destinationId');
        return null;
      } else {
        devtools.log('Error fetching image for $destinationId: $e');
        return null;
      }
    }
  }

  Future<void> trackUserViewInteraction(String userId, String destinationId,
      Map<String, dynamic> destinationData) async {
    if (userId.isNotEmpty) {
      if (destinationData['tags'] != null && destinationData['tags'] is List) {
        List<String> destinationTypes =
            List<String>.from(destinationData['tags']);

        // Call trackUserInteraction from content_filter.dart
        await trackUserInteraction(
            userId, destinationId, destinationTypes, 'view');

        // Call showUserPreferences from content_filter.dart to display updated preferences
        showUserPreferences(userId);
      } else {
        devtools.log('tags is missing or not a valid list.');
      }
    } else {
      devtools.log('User is not logged in');
    }
  }

  Future<void> addToPlan(
      String userId, String destinationId, String formattedTime) async {
    QuerySnapshot travelPlansSnapshot = await FirebaseFirestore.instance
        .collection('travel_plans')
        .where('userId', isEqualTo: userId)
        .get();

    if (travelPlansSnapshot.docs.isNotEmpty) {
      DocumentReference travelPlanDocRef =
          travelPlansSnapshot.docs.first.reference;
      await travelPlanDocRef.update({
        'activities': FieldValue.arrayUnion([
          {'destination': destinationId, 'time': formattedTime}
        ])
      });
      devtools.log('Activity added to travel plan successfully');
    } else {
      devtools.log('No travel plan found for user');
    }
  }
}
