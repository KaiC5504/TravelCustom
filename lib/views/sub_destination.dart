// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:travelcustom/utilities/destination_content.dart';
import 'dart:developer' as devtools show log;

class SubDestinationsCard extends StatefulWidget {
  final String destinationId;

  const SubDestinationsCard({super.key, required this.destinationId});

  @override
  State<SubDestinationsCard> createState() => _SubDestinationsCardState();
}

class _SubDestinationsCardState extends State<SubDestinationsCard> {
  List<Map<String, dynamic>> _subDestinations = [];
  bool _isLoadingSubDestinations = true;
  final DestinationContent _destinationContent = DestinationContent();

  @override
  void initState() {
    super.initState();
    _fetchSubDestinations();
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
    } catch (e) {
      devtools.log('Error fetching sub-destinations: $e');
      if (mounted) {
        setState(() {
          _isLoadingSubDestinations = false;
        });
      }
    }
  }

  Future<String> _getAuthorName(String authorId) async {
    // Call the getAuthorName method from DestinationContent
    return await _destinationContent.getAuthorName(authorId) ?? 'Unknown';
  }

  Future<void> _showSubDestinationDetails(
      BuildContext context, Map<String, dynamic> subDes) async {
    String authorName = await _getAuthorName(subDes['author'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  Text(
                    subDes['name'] ?? 'Unknown Place',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
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
                    subDes['estimate_cost']?.toString() ?? 'N/A',
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
                      onPressed: () {},
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
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Popular Locations:",
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
                        onTap: () => _showSubDestinationDetails(context, subs),
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