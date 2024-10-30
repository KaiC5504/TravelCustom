import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:timeago/timeago.dart' as timeago;
import 'package:path/path.dart' as p;
import 'dart:developer' as devtools show log;

import 'package:travelcustom/views/detail_view.dart';

class PlatformPage extends StatefulWidget {
  const PlatformPage({super.key});

  @override
  State<PlatformPage> createState() => _PlatformPageState();
}

class _PlatformPageState extends State<PlatformPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Store combined data
  List<Map<String, dynamic>> combinedPosts = [];
  Map<String, Uint8List?> profilePictures = {};
  Map<String, Uint8List?> destinationImages = {};

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<File?> getCachedImage(String imageName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, imageName);
    final file = File(path);
    return await file.exists() ? file : null;
  }

  Future<File> saveImageLocally(Uint8List imageBytes, String imageName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, imageName);
    final file = File(path);
    return file.writeAsBytes(imageBytes);
  }

  // Fetch destination and user data
  Future<void> _fetchPosts() async {
    try {
      // Clear previous data on refresh
      combinedPosts.clear();
      profilePictures.clear();
      destinationImages.clear();

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
        File? cachedProfileImage = await getCachedImage('$userId.png');
        if (cachedProfileImage != null) {
          profileBytes = await cachedProfileImage.readAsBytes();
        } else {
          try {
            final ref = _storage.ref().child('profile_pictures/$userId.png');
            profileBytes = await ref.getData(100000000);
            if (profileBytes != null) {
              await saveImageLocally(profileBytes, '$userId.png');
            }
          } catch (e) {
            if (e is FirebaseException && e.code == 'object-not-found') {
              devtools.log(
                  'No profile picture found for user $userId, using default picture.');
            } else {
              devtools.log('Error fetching picture for user $userId: $e');
            }
          }
        }

        // Cache the profile picture
        profilePictures[userId] = profileBytes;

        // Fetch destination image with local caching
        Uint8List? destinationBytes;
        File? cachedDestinationImage =
            await getCachedImage('${destinationDoc.id}.png');
        if (cachedDestinationImage != null) {
          destinationBytes = await cachedDestinationImage.readAsBytes();
        } else {
          try {
            final ref = _storage
                .ref()
                .child('destination_images/${destinationDoc.id}.png');
            destinationBytes = await ref.getData(100000000);
            if (destinationBytes != null) {
              await saveImageLocally(
                  destinationBytes, '${destinationDoc.id}.png');
            }
          } catch (e) {
            if (e is FirebaseException && e.code == 'object-not-found') {
              devtools.log(
                  'No destination image found for destination ${destinationDoc.id}, using default image.');
            } else {
              devtools.log(
                  'Error fetching image for destination ${destinationDoc.id}: $e');
            }
          }
        }

        // Cache the destination image
        destinationImages[destinationDoc.id] = destinationBytes;

        // Combine destination and user data
        combinedPosts.add({
          'destinationId': destinationDoc.id,
          'authorName': userData['name'],
          'authorId': userId,
          'destination': destinationData['destination'],
          'averageRating': destinationData['average_rating'],
          'postDate': destinationData['post_date'] ?? Timestamp.now(),
        });
      }

      setState(() {});
    } catch (e) {
      devtools.log('Error fetching posts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Travel Posts'),
        backgroundColor: Colors.grey[200],
      ),
      backgroundColor: Colors.grey[200],
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main content: List of posts
          combinedPosts.isEmpty
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : RefreshIndicator(
                  onRefresh: _fetchPosts,
                  child: ListView.builder(
                    itemCount: combinedPosts.length,
                    itemBuilder: (context, index) {
                      var post = combinedPosts[index];
                      Uint8List? profilePicture =
                          profilePictures[post['authorId']];
                      String timeAgo = timeago
                          .format((post['postDate'] as Timestamp).toDate());
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15.0),
                          child: Material(
                            color: Colors.white,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => DetailsPage(
                                        destinationId: post['destinationId'])));
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage:
                                              profilePicture != null
                                                  ? MemoryImage(profilePicture)
                                                  : null,
                                          child: profilePicture == null
                                              ? Icon(Icons.person)
                                              : null,
                                        ),
                                        SizedBox(width: 10.0),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              post['authorName'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Spacer(),
                                        Text(
                                          timeAgo,
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16.0),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post['destination'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.0,
                                          ),
                                        ),
                                        SizedBox(height: 8.0),
                                        destinationImages[
                                                    post['destinationId']] !=
                                                null
                                            ? Image.memory(
                                                destinationImages[
                                                    post['destinationId']]!,
                                                height: 200.0,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                height: 200.0,
                                                width: double.infinity,
                                                color: Colors.grey[200],
                                                child: Icon(Icons.error,
                                                    color: Colors.red),
                                              ),
                                      ],
                                    ),
                                    SizedBox(height: 16.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

          // Add button
          Positioned(
            bottom: 0,
            left: MediaQuery.of(context).size.width / 2 - 140 / 2,
            child: Material(
              color: Color.fromARGB(255, 56, 56, 56),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(45),
              ),
              child: InkWell(
                onTap: () {
                  devtools.log('Add button tapped');
                },
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(45),
                ),
                splashColor: Color.fromARGB(255, 91, 91, 91).withOpacity(0.2),
                highlightColor: Color.fromARGB(255, 91, 91, 91)
                    .withOpacity(0.2), // Highlight color when pressed
                child: Container(
                  width: 140,
                  height: 39, // Half the height for a semi-circle
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(45),
                    ),
                  ),
                  child: Icon(
                    FontAwesomeIcons.plus,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
