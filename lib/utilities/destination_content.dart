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

  Future<String?> getAuthorName(String authorId) async {
    try {
      DocumentSnapshot authorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authorId)
          .get();

      if (authorDoc.exists) {
        String authorName = authorDoc['name'] as String? ?? 'Unknown';
        return authorName;
      } else {
        devtools.log('Author not found in users collection');
        return 'Unknown';
      }
    } catch (e) {
      devtools.log('Error fetching author name: $e');
      return 'Unknown';
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

  Future<List<Map<String, dynamic>>> fetchSubDestinations(
      String destinationId) async {
    try {
      final subDestinationsSnapshot = await FirebaseFirestore.instance
          .collection('destinations')
          .doc(destinationId)
          .collection('sub_destinations')
          .orderBy('post_date',
              descending: true) // Sort by post_date in descending order
          .get();

      devtools.log('Sub-destinations fetched successfully');
      return subDestinationsSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      devtools.log('Error fetching sub-destinations: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchReviews(String destinationId) async {
    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('destinations')
          .doc(destinationId)
          .collection('reviews')
          .orderBy('review_date', descending: true)
          .limit(10)
          .get();

      // Convert the documents to a list of maps for easier usage
      devtools.log('Reviews fetched successfully');
      return reviewsSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      devtools.log('Error fetching reviews: $e');
      return [];
    }
  }

  Future<String?> getUserName(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        String userName = userDoc['name'] as String? ?? 'Unknown';
        devtools.log('Fetched user name: $userName');
        return userName;
      } else {
        devtools.log('User not found in users collection');
        return 'Unknown';
      }
    } catch (e) {
      devtools.log('Error fetching user name: $e');
      return 'Unknown';
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

  Future<void> addReview(
      String destinationId, double rating, String reviewContent) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      devtools.log('User is not logged in');
      return;
    }

    // Trim spaces at the end and remove excess rows
    reviewContent = reviewContent.trimRight();
    reviewContent = reviewContent.replaceAll(RegExp(r'\n\s*\n'), '\n');

    try {
      await FirebaseFirestore.instance
          .collection('destinations')
          .doc(destinationId)
          .collection('reviews')
          .add({
        'userId': userId,
        'rating': rating,
        'review_content': reviewContent,
        'review_date': Timestamp.now(),
      });
      devtools.log('Review added successfully');
    } catch (e) {
      devtools.log('Error adding review: $e');
    }
  }
}
