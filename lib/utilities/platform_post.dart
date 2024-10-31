import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:developer' as devtools show log;

class PlatformPostsContent {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Map<String, Uint8List?> profilePictures = {};
  Map<String, Uint8List?> destinationImages = {};

  // Method to retrieve cached images
  Future<File?> getCachedImage(String imageName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, imageName);
    final file = File(path);
    if (await file.exists()) {
      return file;
    } else {
      return null;
    }
  }

  // Method to save images locally
  Future<File> saveImageLocally(Uint8List imageBytes, String imageName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, imageName);
    final file = File(path);
    await file.writeAsBytes(imageBytes);
    return file;
  }

  // Fetch destinations and user data
  Future<Map<String, dynamic>> fetchDestinationPosts() async {
    List<Map<String, dynamic>> destinationPosts = [];

    try {
      QuerySnapshot destinationSnapshot = await _firestore
          .collection('destinations')
          .orderBy('post_date', descending: true)
          .get();

      for (var destinationDoc in destinationSnapshot.docs) {
        var destinationData = destinationDoc.data() as Map<String, dynamic>;
        String userId = destinationData['author'];

        // Fetch user details based on the author field
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(userId).get();
        var userData = userDoc.data() as Map<String, dynamic>;

        // Fetch profile picture with local caching
        Uint8List? profileBytes;
        File? cachedProfileImage = await getCachedImage('$userId.webp');
        if (cachedProfileImage != null) {
          profileBytes = await cachedProfileImage.readAsBytes();
        } else {
          try {
            final ref = _storage.ref().child('profile_pictures/$userId.webp');
            profileBytes = await ref.getData(100000000);
            if (profileBytes != null) {
              await saveImageLocally(profileBytes, '$userId.webp');
            }
          } catch (e) {
            if (e is FirebaseException && e.code == 'object-not-found') {
            } else {
              devtools
                  .log('Error fetching profile picture for user $userId: $e');
            }
          }
        }
        profilePictures[userId] = profileBytes;

        // Fetch destination image with local caching
        Uint8List? destinationBytes;
        File? cachedDestinationImage =
            await getCachedImage('${destinationDoc.id}.webp');
        if (cachedDestinationImage != null) {
          destinationBytes = await cachedDestinationImage.readAsBytes();
        } else {
          try {
            final ref = _storage
                .ref()
                .child('destination_images/${destinationDoc.id}.webp');
            destinationBytes = await ref.getData(100000000);
            if (destinationBytes != null) {
              await saveImageLocally(
                  destinationBytes, '${destinationDoc.id}.webp');
            }
          } catch (e) {
            if (e is FirebaseException && e.code == 'object-not-found') {
              devtools
                  .log('No destination image found for ${destinationDoc.id}');
            } else {
              devtools.log(
                  'Error fetching destination image for ${destinationDoc.id}: $e');
            }
          }
        }
        destinationImages[destinationDoc.id] = destinationBytes;

        // Combine destination and user data
        destinationPosts.add({
          'destinationId': destinationDoc.id,
          'authorName': userData['name'],
          'authorId': userId,
          'destination': destinationData['destination'],
          'averageRating': destinationData['average_rating'],
          'postDate': destinationData['post_date'] ?? Timestamp.now(),
        });
      }
    } catch (e) {
      devtools.log('Error fetching posts: $e');
    }

    // Return combined posts along with images
    return {
      'combinedPosts': destinationPosts,
      'profilePictures': profilePictures,
      'destinationImages': destinationImages,
    };
  }

  Future<Map<String, dynamic>> fetchPlanPosts() async {
    List<Map<String, dynamic>> planPosts = [];
    Map<String, Uint8List?> profilePictures = {};

    try {
      QuerySnapshot planSnapshot = await _firestore
          .collection('platform_plans')
          .orderBy('post_date', descending: true)
          .get();

      for (var planDoc in planSnapshot.docs) {
        var planData = planDoc.data() as Map<String, dynamic>;
        String userId = planData['userId'];

        // Fetch user details based on the userId field
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(userId).get();
        var userData = userDoc.data() as Map<String, dynamic>;

        // Fetch profile picture with local caching
        Uint8List? profileBytes;
        File? cachedProfileImage = await getCachedImage('$userId.webp');
        if (cachedProfileImage != null) {
          profileBytes = await cachedProfileImage.readAsBytes();
        } else {
          try {
            final ref = _storage.ref().child('profile_pictures/$userId.webp');
            profileBytes = await ref.getData(100000000);
            if (profileBytes != null) {
              await saveImageLocally(profileBytes, '$userId.webp');
            }
          } catch (e) {
            if (e is FirebaseException && e.code == 'object-not-found') {
              devtools.log('No profile picture found for user $userId');
            } else {
              devtools
                  .log('Error fetching profile picture for user $userId: $e');
            }
          }
        }
        profilePictures[userId] = profileBytes;

        // Add plan data to the list of plan posts
        planPosts.add({
          'planId': planDoc.id,
          'planName': planData['plan_name'],
          'userId': userId,
          'authorName': userData['name'],
          'activities': planData['activities'],
          'postDate': planData['post_date'],
        });
      }
    } catch (e) {
      devtools.log('Error fetching travel plans: $e');
    }

    return {
      'planPosts': planPosts,
      'profilePictures': profilePictures,
    };
  }
}
