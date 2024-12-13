// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:travelcustom/utilities/destination_content.dart';
import 'package:travelcustom/utilities/navigation_bar.dart';
import 'dart:developer' as devtools show log;

class SubDestinationsCard extends StatefulWidget {
  final String destinationId;
  final String? initialSubDestinationId;
  final bool fromLocationButton;
  final Function(String)? onAddToPlan;

  const SubDestinationsCard(
      {super.key,
      required this.destinationId,
      this.initialSubDestinationId,
      this.fromLocationButton = false,
      this.onAddToPlan});

  @override
  State<SubDestinationsCard> createState() => _SubDestinationsCardState();
}

class _SubDestinationsCardState extends State<SubDestinationsCard> {
  List<Map<String, dynamic>> _subDestinations = [];
  bool _isLoadingSubDestinations = true;
  final DestinationContent _destinationContent = DestinationContent();
  bool _dialogOpened = false;

  @override
  void initState() {
    super.initState();
    _fetchSubDestinations();

    if (widget.initialSubDestinationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openInitialSubDestinationDialog();
      });
    }
  }

  Future<void> _fetchSubDestinations() async {
    try {
      _subDestinations =
          await DestinationContent().fetchSubDestinations(widget.destinationId);
      if (mounted) {
        setState(() {
          _isLoadingSubDestinations = false;
        });
      }
      // Open the dialog only after sub-destinations are fetched
      if (widget.initialSubDestinationId != null && !_dialogOpened) {
        devtools.log('Opening initial subdes dialog');
        _openInitialSubDestinationDialog();
      }
    } catch (e) {
      devtools.log('Error fetching sub-destinations: $e');
      if (mounted) {
        setState(() {
          _isLoadingSubDestinations = false;
        });
      }
    }
  }

  Future<void> _openInitialSubDestinationDialog() async {
    if (_dialogOpened) return; // Check if the dialog has already been opened

    final initialSubDes = _subDestinations.firstWhere(
      (subDes) => subDes['id'] == widget.initialSubDestinationId,
      orElse: () => {},
    );

    if (initialSubDes.isNotEmpty) {
      await _showSubDestinationDetails(
          context, initialSubDes, widget.fromLocationButton);
      _dialogOpened = true; // Set the flag to true after the dialog is shown
    }
  }

  Future<String> _getAuthorName(String authorId) async {
    // Call the getAuthorName method from DestinationContent
    return await _destinationContent.getAuthorName(authorId) ?? 'Unknown';
  }

  void _onAddToPlan(String subDestinationName) {
    if (widget.fromLocationButton) {
      widget.onAddToPlan?.call(subDestinationName);
    } else {
      final controller = Get.find<NavigationController>();
      controller.navigateToPlan(
        showDialog: true,
        sideNote: subDestinationName,
      );
    }
  }

  Future<void> _showSubDestinationDetails(BuildContext context,
      Map<String, dynamic> subDes, bool fromLocationButton) async {
    devtools.log('Opening details for sub-destination: ${subDes['id']}');
    
    try {
      await _destinationContent.incrementClickCount(widget.destinationId, subDes['id']);
      devtools.log('Successfully called incrementClickCount');
    } catch (e) {
      devtools.log('Error calling incrementClickCount: $e');
    }
    
    String authorName = await _getAuthorName(subDes['author'] ?? '');

    // Open the dialog first
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            subDes['image'] ?? '',
                            height: 150,
                            width: MediaQuery.of(context).size.width * 0.8,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Text('No Image'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              subDes['name'] ?? 'Unknown Place',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              subDes['isFavourited'] ?? false
                                  ? Icons.star
                                  : Icons.star_border,
                              color: subDes['isFavourited'] ?? false
                                  ? const Color.fromARGB(255, 235, 211, 0)
                                  : Colors.grey,
                              size: 30, // Increase the size of the star
                            ),
                            onPressed: () async {
                              bool newFavouriteStatus =
                                  !(subDes['isFavourited'] ?? false);
                              await _toggleFavourite(
                                  subDes['id'], newFavouriteStatus);
                              setState(() {
                                subDes['isFavourited'] = newFavouriteStatus;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Description:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subDes['description'] ?? 'N/A',
                        softWrap: true,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Estimated Cost:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RM ${subDes['estimate_cost']?.toString() ?? 'N/A'}',
                        softWrap: true,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Location:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subDes['location'] ?? 'Location not available',
                        softWrap: true,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Author:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authorName,
                        softWrap: true,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              _onAddToPlan(subDes['name'] ?? 'Unknown Place'),
                          child: const Text('Add to plan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Track user interaction after opening the dialog
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await _destinationContent.trackUserViewInteraction(
          userId, subDes['id'], subDes);
    } else {
      devtools.log('User is not logged in');
    }
  }

  Future<void> _toggleFavourite(
      String subDestinationId, bool isFavourited) async {
    await _destinationContent.toggleFavourite(subDestinationId, isFavourited);
    setState(() {
      _subDestinations = _subDestinations.map((subDes) {
        if (subDes['id'] == subDestinationId) {
          subDes['isFavourited'] = isFavourited;
        }
        return subDes;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Locations:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: _isLoadingSubDestinations
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _subDestinations.length,
                    itemBuilder: (context, index) {
                      final subs = _subDestinations[index];
                      devtools.log('Sub-destination: $subs');
                      return GestureDetector(
                        onTap: () => _showSubDestinationDetails(
                            context, subs, widget.fromLocationButton),
                        child: Container(
                          width: 230,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
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
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    subs['image'] ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error,
                                            stackTrace) =>
                                        const Center(child: Text('No Image')),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: Icon(
                                    subs['isFavourited'] ?? false
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: subs['isFavourited'] ?? false
                                        ? const Color.fromARGB(255, 192, 172, 0)
                                        : Colors.grey,
                                  ),
                                  onPressed: () => _toggleFavourite(subs['id'],
                                      !(subs['isFavourited'] ?? false)),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  color: Colors.black.withOpacity(0.5),
                                  child: Text(
                                    subs['name'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
