// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:developer' as devtools show log;
import 'package:intl/intl.dart';
import 'package:travelcustom/views/search_view.dart';

class PlanningView extends StatefulWidget {
  final String? planId;
  final String collectionName;
  const PlanningView(
      {super.key, this.planId, this.collectionName = 'travel_plans'});

  @override
  State<PlanningView> createState() => _PlanningViewState();
}

class _PlanningViewState extends State<PlanningView> {
  int selectedDay = 1;
  String planName = '';
  String startDate = '';
  String endDate = '';
  List<Map<String, dynamic>> activities = [];
  Map<String, String> destinationNames = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    setState(() {
      fetchTravelPlanDetails();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchTravelPlanDetails() async {
    try {
      String planId = widget.planId ?? await _getUserPlanId();
      devtools.log('Plan ID: $planId');

      if (planId.isEmpty) {
        devtools.log('No planId found');
        return;
      }

      DocumentSnapshot planDoc = await FirebaseFirestore.instance
          .collection(widget.collectionName) // Use platform_plans collection
          .doc(planId)
          .get();

      if (planDoc.exists) {
        Map<String, dynamic>? planData =
            planDoc.data() as Map<String, dynamic>?;
        if (planData != null) {
          List<Map<String, dynamic>> fetchedDays =
              List<Map<String, dynamic>>.from(planData['days'] ?? []);

          if (fetchedDays.isEmpty) {
            devtools.log('No days found');
          } else {
            for (int i = 0; i < fetchedDays.length; i++) {
              var day = fetchedDays[i];
              String dayTitle = day['day_title'] ?? 'No Title';
              List<String> sideNotes =
                  List<String>.from(day['side_note'] ?? []);
              devtools.log('Day ${i + 1} (Index $i):');
              devtools.log('Day Title: $dayTitle');
              devtools.log('Side Notes: ${sideNotes.join(', ')}');
            }
          }
          // Log the details of each day by index

          if (mounted) {
            setState(() {
              planName = planData['plan_name'] ?? '';
              Timestamp startTimestamp = planData['start'] ?? Timestamp.now();
              Timestamp endTimestamp = planData['end'] ?? Timestamp.now();
              startDate =
                  DateFormat('dd-MM-yyyy').format(startTimestamp.toDate());
              endDate = DateFormat('dd-MM-yyyy').format(endTimestamp.toDate());
              activities = fetchedDays;
            });
          }
          devtools.log(
              'Fetched platform plan details: $planName, $startDate - $endDate, Days: ${fetchedDays.length}');
        }
      } else {
        devtools.log('Plan document does not exist.');
      }
    } catch (e) {
      devtools.log('Error fetching platform plan details: $e');
    }
  }

  Future<String> _getUserPlanId() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return '';

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    return userDoc.exists ? userDoc['planId'] ?? '' : '';
  }

  Future<void> _addDay() async {
    int newDayNumber = activities.length + 1;
    TextEditingController dayTitleController = TextEditingController();
    List<String> newSideNotes = [];

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: Colors.grey[200],
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(16.0), // Control overall padding
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Day $newDayNumber',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(height: 25),

                    TextField(
                      controller: dayTitleController,
                      decoration: InputDecoration(
                        labelText: 'Enter Day Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),

                    Text('Add Locations or Side Notes'),
                    SizedBox(height: 10),

                    // Scrollable container for side notes
                    SizedBox(
                      height: 150, // Set a fixed height for the scrollable area
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: newSideNotes
                              .map((note) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(note),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            // Navigate to location search page (to be implemented)
                            final location = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchPage(),
                              ),
                            );
                            if (location != null) {
                              setState(() {
                                newSideNotes.add(location);
                              });
                            }
                          },
                          child: Text('Location'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _addSideNote(context, setState, newSideNotes);
                          },
                          child: Text('Side Note'),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            String dayTitle = dayTitleController.text.trim();
                            if (dayTitle.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Please enter a title for the day.')),
                              );
                              return;
                            }

                            await _saveNewDayToFirestore(
                                newDayNumber, dayTitle, newSideNotes);
                            Navigator.of(context).pop();
                            await fetchTravelPlanDetails(); // Refresh the plan view
                          },
                          child: Text('Add'),
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

  void _addSideNote(
      BuildContext context, StateSetter setState, List<String> newSideNotes) {
    final TextEditingController sideNoteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Side Note'),
          content: TextField(
            controller: sideNoteController,
            decoration: InputDecoration(labelText: 'Enter side note'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final sideNote = sideNoteController.text;
                if (sideNote.isNotEmpty) {
                  setState(() {
                    newSideNotes.add(sideNote);
                  });
                  Navigator.of(context).pop();

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveNewDayToFirestore(
      int dayNumber, String dayTitle, List<String> sideNotes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final planId = await _getUserPlanId();
    if (planId.isEmpty) return;

    final planDocRef =
        FirebaseFirestore.instance.collection('travel_plans').doc(planId);

    await planDocRef.update({
      'days': FieldValue.arrayUnion([
        {
          'day_title': dayTitle,
          'side_note': sideNotes,
        }
      ]),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Travel Plan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey[200],
        scrolledUnderElevation: 0,
      ),
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: activities.isEmpty
            ? Center(
                child: Text(
                  'No Travel Plan',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final dayData = activities[index];
                  final dayTitle = dayData['day_title'] ?? 'No Title';
                  final sideNotes =
                      List<String>.from(dayData['side_note'] ?? []);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 50.0),
                    child: _buildPlanDays(
                      'Day ${index + 1}',
                      dayTitle,
                      sideNotes,
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: widget.collectionName == 'travel_plans'
          ? Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: FloatingActionButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                onPressed: _addDay,
                backgroundColor: const Color.fromARGB(255, 135, 139, 227),
                child: FaIcon(FontAwesomeIcons.plus, color: Colors.white),
              ))
          : null,
    );
  }
}

Widget _buildPlanDays(String day, String title, List<String> sideNotes) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Day label on the left
      Expanded(
        flex: 2,
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      // Icon in the center
      Icon(
        Icons.location_on,
        color: const Color.fromARGB(255, 135, 139, 227),
        size: 30,
      ),

      // Activities on the right
      Expanded(
        flex: 5,
        child: Container(
          margin: EdgeInsets.only(left: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              ...sideNotes.map((activity) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      activity,
                      style: TextStyle(fontSize: 16),
                    ),
                  )),
            ],
          ),
        ),
      ),
    ],
  );
}
