// ignore_for_file: use_build_context_synchronously
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:travelcustom/utilities/destination_content.dart';
import 'package:travelcustom/utilities/navigation_bar.dart';
import 'dart:developer' as devtools show log;

class DestinationDetailPage extends StatefulWidget {
  final String destinationId;
  final bool isFavourited;

  const DestinationDetailPage(
      {super.key, required this.destinationId, this.isFavourited = false});

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> {
  final DestinationContent _destinationContent = DestinationContent();
  bool _isFavourited = false;
  bool _interactionRecorded = false;
  Map<String, Uint8List?> destinationImages = {};
  Uint8List? destinationImageData;
  String? _authorName;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _isFavourited = widget.isFavourited;
    _checkIfFavourited();
    _fetchDestinationImage();
    _fetchDestinationaAuthor();
    _fetchReviews();
  }

  Future<void> _fetchDestinationaAuthor() async {
    try {
      final destinationDoc =
          await _destinationContent.getDestinationDetails(widget.destinationId);
      final data = destinationDoc.data() as Map<String, dynamic>;
      final authorId = data['author'] as String?;

      if (authorId != null) {
        _authorName = await _destinationContent.getAuthorName(authorId);
        setState(() {});
      }
    } catch (e) {
      devtools.log('Error fetching destination or author details: $e');
    }
  }

  void _fetchDestinationImage() async {
    // Fetch the image data from Firebase
    destinationImageData =
        await _destinationContent.getDestinationImage(widget.destinationId);
    setState(() {}); // Trigger a rebuild to display the image
  }

  Future<void> _fetchReviews() async {
    try {
      final reviews =
          await _destinationContent.fetchReviews(widget.destinationId);

      // Loop through each review and fetch the user name based on userId
      for (var review in reviews) {
        final userId = review['userId'] as String;
        final userName = await _destinationContent.getUserName(userId);
        review['userName'] =
            userName ?? 'Unknown'; // Add the user name to the review map
      }

      setState(() {
        _reviews = reviews; // Update state with reviews that include user names
      });
    } catch (e) {
      devtools.log('Error fetching reviews with user names: $e');
    }
  }

  void _checkIfFavourited() async {
    _isFavourited =
        await _destinationContent.checkIfFavourited(widget.destinationId);
    setState(() {});
  }

  void _toggleFavourite() async {
    await _destinationContent.toggleFavourite(
        widget.destinationId, !_isFavourited);
    setState(() {
      _isFavourited = !_isFavourited;
    });
  }

  Future<DocumentSnapshot> _getDestinationDetails() {
    return _destinationContent.getDestinationDetails(widget.destinationId);
  }

  void trackUserViewInteraction(Map<String, dynamic> destinationData) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _destinationContent.trackUserViewInteraction(
          userId, widget.destinationId, destinationData);
    } else {
      devtools.log('User is not logged in');
    }
  }

  void _addToPlan() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      devtools.log('User is not logged in');
      return;
    }

    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selectedTime != null) {
      String formattedTime = selectedTime.format(context);
      await _destinationContent.addToPlan(
          userId, widget.destinationId, formattedTime);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CustomBottomNavigationBar()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Destination Details'),
        centerTitle: true,
        backgroundColor: Colors.grey[200],
        scrolledUnderElevation: 0,
      ),
      backgroundColor: Colors.grey[200],
      body: FutureBuilder<DocumentSnapshot>(
        future: _getDestinationDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          devtools.log('authorName(page): $_authorName');

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading details'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Destination not found'));
          }

          final destinationData = snapshot.data!.data() as Map<String, dynamic>;

          if (!_interactionRecorded) {
            trackUserViewInteraction(destinationData);
            _interactionRecorded = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.grey[200],
                    image: destinationImageData != null
                        ? DecorationImage(
                            image: MemoryImage(destinationImageData!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment:
                            Alignment.topLeft, // Align the text to the top left
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            destinationData['destination'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              backgroundColor: Colors.transparent,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: _toggleFavourite,
                          icon: FaIcon(
                            FontAwesomeIcons.solidStar,
                            color: _isFavourited
                                ? Colors.yellow
                                : const Color.fromARGB(255, 169, 169, 169)
                                    .withOpacity(0.7),
                            size: 36.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Horizontal Scrollable Reviews Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Rating: ",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 120, // Set height for the review cards
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return GestureDetector(
                              onTap: () {
                                // Handle tap on review
                              },
                              child: Container(
                                width: 200,
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(
                                              255, 121, 121, 121)
                                          .withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(0,
                                          3), // Only shadow for bottom, left, and right
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review['userName'] ??
                                          'Anonymous', // Display reviewer ID
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      review['review_content'] ??
                                          'No review', // Display review text
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Text('Rating:'),
                                        const SizedBox(width: 5),
                                        Text(review['rating']
                                            .toString()), // Display rating
                                        const Icon(
                                          Icons.star,
                                          color: Colors.yellow,
                                          size: 16,
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 15),
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
                    const SizedBox(height: 15),
                    const Text(
                      'Location:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      destinationData['location'] ?? '-',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Number of Reviews:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _reviews.length.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Posted Date:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      destinationData['post_date'] != null
                          ? (destinationData['post_date'] as Timestamp)
                              .toDate()
                              .toLocal()
                              .toString()
                              .split(' ')[0]
                              .split('-')
                              .reversed
                              .join('-')
                          : '-',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Author:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _authorName ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: _addToPlan,
                    child: const Text('Add to Plan'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
