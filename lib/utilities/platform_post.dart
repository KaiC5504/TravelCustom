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


  Future<Map<String, dynamic>> fetchDestinationPosts() async {
    List<Map<String, dynamic>> destinationPosts = [];

    try {
      QuerySnapshot destinationSnapshot =
          await _firestore.collection('destinations').get();

      for (var destinationDoc in destinationSnapshot.docs) {
        QuerySnapshot subDestinationsSnapshot = await destinationDoc.reference
            .collection('sub_destinations')
            .orderBy('post_date', descending: true)
            .get();

        for (var subDestinationDoc in subDestinationsSnapshot.docs) {
          var subDestinationData =
              subDestinationDoc.data() as Map<String, dynamic>;
          String userId = subDestinationData['author'];

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

          //Fetch sub-destination image with local caching
          Uint8List? destinationBytes;
          File? cachedDestinationImage =
              await getCachedImage('${subDestinationDoc.id}.webp');
          if (cachedDestinationImage != null) {
            destinationBytes = await cachedDestinationImage.readAsBytes();
          } else {
            try {
              final ref = _storage
                  .ref()
                  .child('destination_images/${subDestinationDoc.id}.webp');
              destinationBytes = await ref.getData(100000000);
              if (destinationBytes != null) {
                await saveImageLocally(
                    destinationBytes, '${subDestinationDoc.id}.webp');
              }
            } catch (e) {
              devtools.log(
                  'Error fetching destination image for ${subDestinationDoc.id}: $e');
            }
          }
          destinationImages[subDestinationDoc.id] = destinationBytes;

          // Combine destination and user data
          destinationPosts.add({
            'destinationId': destinationDoc.id,
            'subDestinationId': subDestinationDoc.id,
            'authorName': userData['name'],
            'authorRole': userData['role'], // Add this line
            'authorId': userId,
            'destination': subDestinationData['name'],
            'description': subDestinationData['description'],
            'postDate': subDestinationData['post_date'] ?? Timestamp.now(),
          });
        }
      }

      // Sort the posts by post_date in descending order
      destinationPosts.sort((a, b) {
        Timestamp postDateA = a['postDate'] as Timestamp;
        Timestamp postDateB = b['postDate'] as Timestamp;
        return postDateB.compareTo(postDateA);
      });
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

        // Fetch and process days data
        List<Map<String, dynamic>> daysData = [];
        if (planData['days'] != null) {
          List<Map<String, dynamic>> days =
              List<Map<String, dynamic>>.from(planData['days']);
          for (var day in days) {
            String dayTitle = day['day_title'] ?? 'No Title';
            List<String> sideNotes = List<String>.from(day['side_note'] ?? []);
            daysData.add({
              'dayTitle': dayTitle,
              'sideNotes': sideNotes,
            });
          }
        }

        // Add plan data to the list of plan posts
        planPosts.add({
          'planId': planDoc.id,
          'planName': planData['plan_name'],
          'userId': userId,
          'authorName': userData['name'],
          'authorRole': userData['role'],
          'days': daysData,
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
