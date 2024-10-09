import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:travelcustom/views/detail_view.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String searchQuery = '';
  String selectedSort = 'Rating';
  Timer? _debounce;

  // Local list to store the fetched destinations
  List<Map<String, dynamic>> localDestinations = [];

  @override
  void initState() {
    super.initState();
    _fetchDestinations(); // Fetch destinations on page load
  }

  // Fetch all destinations from Firestore and store locally
  Future<void> _fetchDestinations() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('destinations').get();
    setState(() {
      localDestinations = snapshot.docs.map((doc) {
        return {
          'id': doc.id, // You can use this ID as a unique identifier
          'name': doc['destinations'],
          'rating': doc['average_rating'],
          'imageUrl': (doc['images'] as List<dynamic>).isNotEmpty
              ? doc['images'][0]
              : '',
        };
      }).toList();
    });
  }

  // Handle debounced search input
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 50), () {
      setState(() {
        searchQuery = query;
      });
    });
  }

  String _normalizeQuery(String input) {
    return input.trim().toLowerCase();
  }

  // Filter local list based on search query
  List<Map<String, dynamic>> _filteredDestinations() {
    if (searchQuery.isEmpty) {
      return localDestinations;
    }
    String normalizedQuery = _normalizeQuery(searchQuery);
    // String capQuery = _capFirstLetter(searchQuery);
    return localDestinations.where((destination) {
      return _normalizeQuery(destination['name']).startsWith(normalizedQuery);
    }).toList();
  }

  // String _capFirstLetter(String input) {
  //   if (input.isEmpty) return '';
  //   return input.split(' ').map((word) {
  //     if (word.isEmpty) return word;
  //     return word[0].toUpperCase() + word.substring(1).toLowerCase();
  //   }).join(' ');
  // }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Expanded(
              child: _filteredDestinations().isEmpty
                  ? Center(
                      child: Text(
                        'No Destination Found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredDestinations().length,
                      itemBuilder: (context, index) {
                        var destination = _filteredDestinations()[index];
                        return GestureDetector(
                          onTap: () {
                            // Navigate to the detailed page when tapped
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DetailsPage(
                                  destinationId: destination['id'], // Pass the ID or name
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
                                image: destination['imageUrl'] != null
                                    ? DecorationImage(
                                        image: NetworkImage(destination['imageUrl']),
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
                                          'Rating: ${destination['rating']?.toString() ?? 'N/A'}',
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
            ),
          ],
        ),
      ),
    );
  }
}
