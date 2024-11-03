// ignore_for_file: use_build_context_synchronously
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:travelcustom/utilities/destination_content.dart';
import 'package:travelcustom/utilities/navigation_bar.dart';
import 'package:travelcustom/views/sub_destination.dart';
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
  final ValueNotifier<bool> _isFavoritedNotifier = ValueNotifier<bool>(false);
  bool _interactionRecorded = false;
  Map<String, Uint8List?> destinationImages = {};
  Uint8List? destinationImageData;
  final ValueNotifier<int> _reviewCountNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _checkIfFavourited();
    _fetchDestinationImage();
  }

  void _fetchDestinationImage() async {
    // Fetch the image data from Firebase
    destinationImageData =
        await _destinationContent.getDestinationImage(widget.destinationId);
    setState(() {}); // Trigger a rebuild to display the image
  }

  Future<void> _checkIfFavourited() async {
    bool isFavorited =
        await _destinationContent.checkIfFavourited(widget.destinationId);
    _isFavoritedNotifier.value = isFavorited;
  }

  void _toggleFavourite() async {
    bool newFavoritedState = !_isFavoritedNotifier.value;
    await _destinationContent.toggleFavourite(
        widget.destinationId, newFavoritedState);
    _isFavoritedNotifier.value = newFavoritedState;
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

  Future<DocumentSnapshot> _getDestinationDetails() {
    return _destinationContent.getDestinationDetails(widget.destinationId);
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
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _isFavoritedNotifier,
                          builder: (context, isFavourited, child) {
                            return IconButton(
                              onPressed: _toggleFavourite,
                              icon: FaIcon(
                                FontAwesomeIcons.solidStar,
                                color: isFavourited
                                    ? Colors.yellow
                                    : const Color.fromARGB(255, 169, 169, 169)
                                        .withOpacity(0.7),
                                size: 36.0,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SubDestinationsCard(destinationId: widget.destinationId),
                const SizedBox(height: 13),

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
                      ReviewsWidget(
                        destinationId: widget.destinationId,
                        destinationContent: _destinationContent,
                        onReviewsLoaded: (reviewCount) {
                          _reviewCountNotifier.value =
                              reviewCount; // Directly update the ValueNotifier
                        },
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
                    ValueListenableBuilder<int>(
                      valueListenable: _reviewCountNotifier,
                      builder: (context, reviewCount, child) {
                        return Text(
                          reviewCount.toString(),
                          style: const TextStyle(fontSize: 16),
                        );
                      },
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

class FavoriteButton extends StatelessWidget {
  final ValueNotifier<bool> isFavoritedNotifier;
  final String destinationId;
  final DestinationContent destinationContent;

  const FavoriteButton({
    super.key,
    required this.isFavoritedNotifier,
    required this.destinationId,
    required this.destinationContent,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isFavoritedNotifier,
      builder: (context, isFavorited, _) {
        return IconButton(
          onPressed: () async {
            await destinationContent.toggleFavourite(
                destinationId, !isFavorited);
            isFavoritedNotifier.value = !isFavorited;
          },
          icon: Icon(
            isFavorited ? Icons.star : Icons.star_border,
            color: isFavorited ? Colors.yellow : Colors.grey,
          ),
        );
      },
    );
  }
}

class AuthorNameWidget extends StatelessWidget {
  final String destinationId;
  final DestinationContent destinationContent;

  const AuthorNameWidget({
    super.key,
    required this.destinationId,
    required this.destinationContent,
  });

  Future<String?> _fetchAuthorName() async {
    try {
      final destinationDoc =
          await destinationContent.getDestinationDetails(destinationId);
      final data = destinationDoc.data() as Map<String, dynamic>;
      final authorId = data['author'] as String?;

      if (authorId != null) {
        return await destinationContent.getAuthorName(authorId);
      }
    } catch (e) {
      devtools.log('Error fetching author name: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _fetchAuthorName(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Loading indicator
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Text('Unknown');
        }
        return Text(snapshot.data!);
      },
    );
  }
}

class ReviewsWidget extends StatelessWidget {
  final String destinationId;
  final DestinationContent destinationContent;
  final Function(int) onReviewsLoaded;

  const ReviewsWidget({
    super.key,
    required this.destinationId,
    required this.destinationContent,
    required this.onReviewsLoaded,
  });

  Future<List<Map<String, dynamic>>> _fetchReviews() async {
    try {
      final reviews = await destinationContent.fetchReviews(destinationId);
      for (var review in reviews) {
        final userId = review['userId'] as String;
        final userName = await destinationContent.getUserName(userId);
        review['userName'] = userName ?? 'Unknown';
      }
      onReviewsLoaded(reviews.length);
      return reviews;
    } catch (e) {
      devtools.log('Error fetching reviews: $e');
      onReviewsLoaded(0);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No reviews available');
        }

        final reviews = snapshot.data!;
        return SizedBox(
          height: 120, // Set height for the review cards
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['userName'] ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      review['review_content'] ?? 'No review',
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
                        Text(review['rating'].toString()),
                        const Icon(
                          Icons.star,
                          color: Colors.yellow,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
