// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:travelcustom/views/destination_detail.dart';
import 'dart:developer' as devtools show log;

class SearchPage extends StatefulWidget {
  final bool fromLocationButton;
  final List<String> initialTags;
  const SearchPage(
      {super.key,
      this.fromLocationButton = false,
      this.initialTags = const []});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String searchQuery = '';
  String selectedSort = 'Rating';
  Timer? _debounce;
  bool _isLoading = true;

  List<Map<String, dynamic>> localDestination = [];
  Map<String, Uint8List?> destinationImages = {};
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<String> selectedTags = [];
  List<String> tags = [
    'Urban',
    'Nightlife',
    'History',
    'Art',
    'Adventure',
    'Beach',
    'Nature',
    'Agriculture',
    'Island',
    'Family-friendly'
  ];

  RangeValues _selectedBudgetRange = const RangeValues(0, 1000);
  bool _budgetFilter = false;

  @override
  void initState() {
    super.initState();
    selectedTags = widget.initialTags;
    _fetchDestinations();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchDestinations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collectionGroup('sub_destinations')
          .get();

      Map<String, Map<String, dynamic>> uniqueDestinations = {};

      for (var doc in snapshot.docs) {
        String docId = doc.id;
        if (!uniqueDestinations.containsKey(docId)) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          num estimateCost = 0;
          if (data['estimate_cost'] != null) {
            if (data['estimate_cost'] is String) {
              estimateCost = num.tryParse(data['estimate_cost']) ?? 0;
            } else if (data['estimate_cost'] is num) {
              estimateCost = data['estimate_cost'];
            }
          }

          num rating = 0.0;
          if (data['rating'] != null) {
            if (data['rating'] is String) {
              rating = num.tryParse(data['rating']) ?? 0.0;
            } else if (data['rating'] is num) {
              rating = data['rating'];
            }
          }

          num clickCount = 0;
          if (data['click_count'] != null) {
            if (data['click_count'] is String) {
              clickCount = num.tryParse(data['click_count']) ?? 0;
            } else if (data['click_count'] is num) {
              clickCount = data['click_count'];
            }
          }

          uniqueDestinations[docId] = {
            'id': docId,
            'name': data['name'] ?? '',
            'destinationId': doc.reference.parent.parent?.id,
            'tags': List<String>.from(data['tags'] ?? []),
            'estimate_cost': estimateCost,
            'click_count': clickCount,
            'rating': rating,
          };
        }
      }

      List<Map<String, dynamic>> fetchedDestinations =
          uniqueDestinations.values.toList();

      // Fetch images for each destination
      for (var destination in fetchedDestinations) {
        String destinationId = destination['id'];
        try {
          final ref =
              _storage.ref().child('destination_images/$destinationId.webp');
          Uint8List? destinationImageBytes = await ref.getData(100000000);
          destinationImages[destinationId] = destinationImageBytes;
        } catch (e) {
          devtools.log('Error fetching image for $destinationId: $e');
        }
      }

      if (mounted) {
        setState(() {
          localDestination = fetchedDestinations;
          _isLoading = false;
        });
      }
    } catch (e) {
      devtools.log('Error in _fetchDestinations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Search bar debounce
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

  // Filter local list
  List<Map<String, dynamic>> _filteredDestinations() {
    List<Map<String, dynamic>> filteredList = [];

    // Apply filters
    if (searchQuery.isEmpty && selectedTags.isEmpty && !_budgetFilter) {
      filteredList = List.from(localDestination);
    } else {
      String normalizedQuery = _normalizeQuery(searchQuery);
      filteredList = localDestination.where((destination) {
        bool matchesQuery =
            _normalizeQuery(destination['name']).startsWith(normalizedQuery);
        bool matchesTags = selectedTags.isEmpty ||
            selectedTags
                .any((tag) => destination['tags']?.contains(tag) ?? false);
        bool matchesBudget = !_budgetFilter ||
            (destination['estimate_cost'] >= _selectedBudgetRange.start &&
                destination['estimate_cost'] <= _selectedBudgetRange.end);
        return matchesQuery && matchesTags && matchesBudget;
      }).toList();
    }

    // Apply sorting
    if (selectedSort == 'Name') {
      filteredList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    } else if (selectedSort == 'Rating') {
      filteredList
          .sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
    } else if (selectedSort == 'Popularity') {
      filteredList.sort(
          (a, b) => (b['popularity'] ?? 0).compareTo(a['popularity'] ?? 0));
    }

    return filteredList;
  }

  void _showTagSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> tempSelectedTags = List.from(selectedTags);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Select Tags'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: tags.map((String tag) {
                    return CheckboxListTile(
                      value: tempSelectedTags.contains(tag),
                      title: Text(tag),
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            tempSelectedTags.add(tag);
                          } else {
                            tempSelectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Apply'),
                  onPressed: () {
                    setState(() {
                      selectedTags = List.from(tempSelectedTags);
                      devtools.log('Applied Tags: $selectedTags');
                    });
                    Navigator.of(context).pop();
                    _applyFilters();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBudgetRangeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        RangeValues tempBudgetRange = _selectedBudgetRange;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Select Budget Range'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RangeSlider(
                    values: tempBudgetRange,
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    labels: RangeLabels('RM${tempBudgetRange.start.round()}',
                        'RM${tempBudgetRange.end.round()}'),
                    onChanged: (RangeValues values) {
                      setState(() {
                        tempBudgetRange = values;
                      });
                    },
                  ),
                  Text(
                    'Budget: RM${tempBudgetRange.start.round()} - RM${tempBudgetRange.end.round()}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Clear'),
                  onPressed: () {
                    this.setState(() {
                      _selectedBudgetRange = const RangeValues(0, 1000);
                      _budgetFilter = false;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Apply'),
                  onPressed: () {
                    this.setState(() {
                      _selectedBudgetRange = tempBudgetRange;
                      _budgetFilter = true;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _applyFilters() {
    setState(() {
      final filteredDestinations = _filteredDestinations();
      devtools.log(
          'Filtered List: ${filteredDestinations.map((d) => d['name']).toList()}');
    });
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'Tags') {
                      _showTagSelectionDialog();
                    } else if (value == 'Budget') {
                      _showBudgetRangeDialog();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'Tags',
                      child: Text('Filter by Tags'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Budget',
                      child: Text('Filter by Budget'),
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
              child: Column(
                children: [
                  Text(
                    'Current Sort: $selectedSort',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (selectedTags.isNotEmpty)
                    Text(
                      'Filter by: ${selectedTags.join(', ')}',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  if (_budgetFilter)
                    Text(
                      'Budget: RM${_selectedBudgetRange.start.round()} - RM${_selectedBudgetRange.end.round()}',
                      style: const TextStyle(fontSize: 14),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
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
                  onTap: () async {
                    if (widget.fromLocationButton) {
                      final subDestinationName = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DestinationDetailPage(
                            destinationId: destination['destinationId'],
                            subdestinationId: destination['id'],
                            fromLocationButton: widget.fromLocationButton,
                          ),
                        ),
                      );
                      devtools.log(
                          'Received subDestinationName from DestinationDetailPage: $subDestinationName');
                      if (subDestinationName != null) {
                        Navigator.pop(context, subDestinationName);
                      }
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DestinationDetailPage(
                            destinationId: destination['destinationId'],
                            subdestinationId: destination['id'],
                          ),
                        ),
                      );
                    }
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
