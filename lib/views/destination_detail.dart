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

  @override
  void initState() {
    super.initState();
    _isFavourited = widget.isFavourited;
    _checkIfFavourited();
    _fetchDestinationImage();
  }

  void _fetchDestinationImage() async {
    // Fetch the image data from Firebase
    destinationImageData =
        await _destinationContent.getDestinationImage(widget.destinationId);
    setState(() {}); // Trigger a rebuild to display the image
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

  String? _authorName;

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
          devtools.log('authorName: $_authorName');

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
                const SizedBox(height: 30),
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
                      'Average Rating:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      destinationData['average_rating']?.toString() ?? '-',
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
                      destinationData['number_of_reviews']?.toString() ?? '-',
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
