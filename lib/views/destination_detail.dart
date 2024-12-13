// ignore_for_file: use_build_context_synchronously
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travelcustom/utilities/destination_content.dart';
import 'package:travelcustom/views/sub_destination.dart';
import 'dart:developer' as devtools show log;

class DestinationDetailPage extends StatefulWidget {
  final String destinationId;
  final String? subdestinationId;
  final bool isFavourited;
  final bool fromLocationButton;

  const DestinationDetailPage(
      {super.key,
      required this.destinationId,
      required this.subdestinationId,
      this.isFavourited = false,
      this.fromLocationButton = false});

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> {
  final DestinationContent _destinationContent = DestinationContent();
  final ValueNotifier<bool> _isFavoritedNotifier = ValueNotifier<bool>(false);
  Map<String, Uint8List?> destinationImages = {};
  Uint8List? destinationImageData;
  final ValueNotifier<int> _reviewCountNotifier = ValueNotifier<int>(0);
  final GlobalKey<ReviewsWidgetState> _reviewsWidgetKey =
      GlobalKey<ReviewsWidgetState>();

  @override
  void initState() {
    super.initState();
    _checkIfFavourited();
    _fetchDestinationImage();
  }

  void _fetchDestinationImage() async {
   
    destinationImageData =
        await _destinationContent.getDestinationImage(widget.destinationId);
    setState(() {}); 
  }

  Future<void> _checkIfFavourited() async {
    bool isFavorited =
        await _destinationContent.checkIfFavourited(widget.destinationId);
    _isFavoritedNotifier.value = isFavorited;
  }

  void trackUserViewInteraction(Map<String, dynamic> subDestinationData) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _destinationContent.trackUserViewInteraction(
          userId, widget.subdestinationId!, subDestinationData);
    } else {
      devtools.log('User is not logged in');
    }
  }

  Future<DocumentSnapshot> _getDestinationDetails() {
    return _destinationContent.getDestinationDetails(widget.destinationId);
  }

  void _handleAddToPlan(String subDestinationName) {
    if (widget.fromLocationButton) {
     
      devtools.log(
          'PPP Returning subDestinationName: $subDestinationName to SearchPage');
      Navigator.pop(context, subDestinationName);
      Navigator.pop(context, subDestinationName);
    } else {
      
      _destinationContent.getSubDestinationDetails(widget.destinationId, subDestinationName).then((subDestinationData) {
        trackUserViewInteraction(subDestinationData);
      });
    }
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double rating = 0;
        TextEditingController reviewController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[200],
              title: const Center(child: Text('Write a Review')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rating:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color:
                              index < rating ? Colors.amber[600] : Colors.grey,
                          size: 40.0, 
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Review:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    await _destinationContent.addReview(
                      widget.destinationId,
                      rating,
                      reviewController.text,
                    );
                    Navigator.of(context).pop();
                    setState(() {}); 
                    _reviewsWidgetKey.currentState?.refreshReviews();
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
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
                            Alignment.topLeft,
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
                     
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SubDestinationsCard(
                  destinationId: widget.destinationId,
                  initialSubDestinationId: widget.subdestinationId,
                  fromLocationButton: widget.fromLocationButton,
                  onAddToPlan: _handleAddToPlan,
                ),
                const SizedBox(height: 13),

                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Recent Reviews: ",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ReviewsWidget(
                        key: _reviewsWidgetKey,
                        destinationId: widget.destinationId,
                        destinationContent: _destinationContent,
                        onReviewsLoaded: (reviewCount) {
                          _reviewCountNotifier.value =
                              reviewCount; 
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
                    onPressed: _showReviewDialog,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.grey[800], 
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      elevation: 5,
                    ),
                    child: const Text('Write a Review'),
                  ),
                ),
                const SizedBox(height: 20),
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
          return CircularProgressIndicator(); 
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Text('Unknown');
        }
        return Text(snapshot.data!);
      },
    );
  }
}

class ReviewsWidget extends StatefulWidget {
  final String destinationId;
  final DestinationContent destinationContent;
  final Function(int) onReviewsLoaded;

  const ReviewsWidget({
    super.key,
    required this.destinationId,
    required this.destinationContent,
    required this.onReviewsLoaded,
  });

  @override
  ReviewsWidgetState createState() => ReviewsWidgetState();
}

class ReviewsWidgetState extends State<ReviewsWidget> {
  Future<List<Map<String, dynamic>>> _fetchReviews() async {
    try {
      final reviews =
          await widget.destinationContent.fetchReviews(widget.destinationId);
      for (var review in reviews) {
        final userId = review['userId'] as String;
        final userName = await widget.destinationContent.getUserName(userId);
        review['userName'] = userName ?? 'Unknown';
      }
      widget.onReviewsLoaded(reviews.length);
      return reviews;
    } catch (e) {
      devtools.log('Error fetching reviews: $e');
      widget.onReviewsLoaded(0);
      return [];
    }
  }

  void refreshReviews() {
    setState(() {});
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
          height: 120, 
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
                    Row(
                      children: [
                        Text(
                          review['rating'].toInt().toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Icon(
                          Icons.star,
                          color: Colors.yellow,
                          size: 23,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      review['review_content'] ?? 'No review',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.black,
                      ),
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
