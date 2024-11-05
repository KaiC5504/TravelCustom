import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:travelcustom/views/destination_detail.dart';
import 'dart:developer' as devtools show log;

class SearchPage extends StatefulWidget {
  final bool fromLocationButton;
  const SearchPage({super.key, this.fromLocationButton = false});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String searchQuery = '';
  String selectedSort = 'Rating';
  Timer? _debounce;
  bool _isLoading = true;

  // Local list to store the fetched destinations
  List<Map<String, dynamic>> localDestination = [];
  Map<String, Uint8List?> destinationImages = {};
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _fetchDestinations();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // Fetch all destinations from Firestore and store locally
  Future<void> _fetchDestinations() async {
    setState(() {
      _isLoading = true;
    });
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('destinations').get();
    List<Map<String, dynamic>> fetchedDestinations = snapshot.docs.map((doc) {
      return {
        'id': doc.id, // You can use this ID as a unique identifier
        'name': doc['destination'],
        'rating': doc['average_rating'] ?? 0,
        'popularity': doc['number_of_reviews'] ?? 0,
      };
    }).toList();

    // Fetch images from Firebase Storage
    for (var destination in fetchedDestinations) {
      String destinationId = destination['id'];
      try {
        final ref =
            _storage.ref().child('destination_images/$destinationId.webp');
        Uint8List? destinationImageBytes = await ref.getData(100000000);
        destinationImages[destinationId] = destinationImageBytes;
      } catch (e) {
        if (e is FirebaseException && e.code == 'object-not-found') {
          devtools.log(
              'No destination image found for $destinationId, using default image.');
        } else {
          devtools.log('Error fetching image for $destinationId: $e');
        }
      }
    }

    if (mounted) {
      setState(() {
        localDestination = fetchedDestinations;
        _isLoading = false;
      });
    }
  }

  // Handle debounced search input
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          searchQuery = query;
        });
      }
    });
  }

  String _normalizeQuery(String input) {
    return input.trim().toLowerCase();
  }

  // Filter local list based on search query
  List<Map<String, dynamic>> _filteredDestinations() {
    List<Map<String, dynamic>> filteredList = [];

    if (searchQuery.isEmpty) {
      filteredList = List.from(localDestination);
    } else {
      String normalizedQuery = _normalizeQuery(searchQuery);
      filteredList = localDestination.where((destination) {
        return _normalizeQuery(destination['name']).startsWith(normalizedQuery);
      }).toList();
    }

    // Apply sorting based on the selectedSort value
    if (selectedSort == 'Name') {
      filteredList.sort((a, b) => a['name'].compareTo(b['name']));
    } else if (selectedSort == 'Rating') {
      filteredList.sort((a, b) => b['rating'].compareTo(a['rating']));
    } else if (selectedSort == 'Popularity') {
      // Assuming you have a 'popularity' field
      filteredList.sort((a, b) => b['popularity'].compareTo(a['popularity']));
    }

    return filteredList;
  }

  @override
  Widget build(BuildContext context) {
    final filteredDestinations = _filteredDestinations();
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for a destination...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: _onSearchChanged,
            ),

            const SizedBox(height: 20),

            // Filter and Sort Buttons with PopupMenuButton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PopupMenuButton<String>(
                  onSelected: (value) {},
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'Price',
                      child: Text('Filter by Price'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Rating',
                      child: Text('Filter by Rating'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Distance',
                      child: Text('Filter by Distance'),
                    ),
                  ],
                  color: const Color(0xFFD4EAF7),
                  position: PopupMenuPosition.under,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4EAF7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Text(
                          'Filter',
                          style: TextStyle(color: Colors.black),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_drop_down,
                            size: 18, color: Colors.black),
                      ],
                    ),
                  ),
                ),
                // Sort By Button
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() {
                      selectedSort = value;
                    });
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'Name',
                      child: Text('Sort by Name'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Rating',
                      child: Text('Sort by Rating'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Popularity',
                      child: Text('Sort by Popularity'),
                    ),
                  ],
                  color: const Color(0xFFD4EAF7),
                  position: PopupMenuPosition.under,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4EAF7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Text(
                          'Sort by',
                          style: TextStyle(color: Colors.black),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_drop_down,
                            size: 18, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                'Current Sort: $selectedSort',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ListView to display local data
            _isLoading
                ? Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _buildDestinationList(filteredDestinations),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationList(
      List<Map<String, dynamic>> filteredDestinations) {
    return filteredDestinations.isEmpty
        ? Center(
            child: Text(
              'No Destination Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : Expanded(
            child: ListView.builder(
              itemCount: filteredDestinations.length,
              itemBuilder: (context, index) {
                var destination = filteredDestinations[index];
                String destinationId = destination['id'];
                Uint8List? destinationImage = destinationImages[destinationId];

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DestinationDetailPage(
                          destinationId: destinationId,
                          subdestinationId: null,
                          fromLocationButton: widget.fromLocationButton,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey[200],
                        image: destinationImage != null
                            ? DecorationImage(
                                image: MemoryImage(destinationImage),
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
                              destination['name'] ?? 'Unknown Destination',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  'Rating: ${(destination['rating'] ?? 'N/A').toString()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const Icon(Icons.star,
                                    color: Colors.yellow, size: 18),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
  }
}
