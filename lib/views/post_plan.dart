// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:developer' as devtools show log;

class PostPlanPage extends StatefulWidget {
  const PostPlanPage({super.key});

  @override
  State<PostPlanPage> createState() => _PostPlanPageState();
}

class _PostPlanPageState extends State<PostPlanPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  String planName = '';
  String cost = '';
  List<Map<String, dynamic>> days = [];
  Map<String, String> destinationNames = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPlanPreview();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> fetchPlanPreview() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) return;

      // Fetch the user's travel plan
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('travel_plans')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userPlanDoc = querySnapshot.docs.first;
        Map<String, dynamic> planData =
            userPlanDoc.data() as Map<String, dynamic>;
        devtools.log('Fetched Plan data');

        List<Map<String, dynamic>> fetchedDays =
            List<Map<String, dynamic>>.from(planData['days'] ?? []);

        setState(() {
          planName = planData['plan_name'] ?? 'Untitled Plan';
          days = fetchedDays;
          isLoading = false;
        });
      } else {
        devtools.log('No travel plan found for user');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      devtools.log('Error fetching plan preview: $e');
      isLoading = false;
    }
  }

  // Fetch destination names and store them in destinationNames map
  Future<void> fetchDestinationNames(
      List<Map<String, dynamic>> activities) async {
    for (var activity in activities) {
      String destinationId = activity['destination'];

      // Check if the destination looks like an ID and if we haven't fetched it already
      if (destinationId.isNotEmpty &&
          !destinationNames.containsKey(destinationId)) {
        try {
          DocumentSnapshot destinationDoc = await FirebaseFirestore.instance
              .collection('destinations')
              .doc(destinationId)
              .get();

          if (destinationDoc.exists) {
            destinationNames[destinationId] = destinationDoc['destination'];
          } else {
            destinationNames[destinationId] = destinationId;
          }
        } catch (e) {
          devtools.log('Error fetching destination name: $e');
          destinationNames[destinationId] = destinationId;
        }
      }
    }
  }

  void _emptyFieldsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text('Fields not complete')),
          content: Text('Please fill in all fields'),
          actions: [
            // TextButton(
            //   onPressed: () {
            //     Navigator.of(context).pop(); // Close the dialog
            //   },
            //   child: Text('OK'),
            // ),
          ],
        );
      },
    );
  }

  Future<void> _uploadPlan() async {
    String planName = _nameController.text.trim();
    String cost = _costController.text.trim();

    if (planName.isEmpty || cost.isEmpty) {
      _emptyFieldsDialog();
      return;
    }

    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        return;
      }

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('travel_plans')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        devtools.log('No travel plan found for user');
        return;
      }

      // Get Doc and update name
      DocumentSnapshot travelPlanDoc = querySnapshot.docs.first;
      await travelPlanDoc.reference.update({'plan_name': planName});
      devtools.log('Updated plan_name in travel_plans collection');

      Map<String, dynamic> travelPlanData =
          travelPlanDoc.data() as Map<String, dynamic>;
      travelPlanData['plan_name'] = planName;
      travelPlanData['estimated_cost'] = cost;
      travelPlanData['post_date'] = Timestamp.now();

      // New Doc for platform_plans
      DocumentReference platformPlanDoc =
          FirebaseFirestore.instance.collection('platform_plans').doc();
      await platformPlanDoc.set(travelPlanData);
      devtools.log(
          'Copied travel plan to platform_plans with new document ID: ${platformPlanDoc.id}');

      // Pop back to previous page after success
      Navigator.of(context).pop(true);
    } catch (e) {
      devtools.log('Error uploading plan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Post Travel Plan'),
        backgroundColor: Colors.grey[200],
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.angleLeft,
              color: const Color.fromARGB(255, 42, 42, 42)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: FaIcon(
              Icons.check,
              color: const Color.fromARGB(255, 42, 42, 42),
              size: 30.0,
            ),
            onPressed: () {
              _uploadPlan();
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 20.0),
            Text(
              'Estimated Cost',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _costController,
              decoration: InputDecoration(
                hintText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 25.0),
            Text(
              'Preview Travel Plan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            SizedBox(height: 8.0),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.0),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: days.isEmpty
                        ? Text('No days in Travel Plan')
                        : Column(
                            children: days.asMap().entries.map((entry) {
                              int index = entry.key;
                              Map<String, dynamic> day = entry.value;
                              String dayTitle = day['day_title'] ?? '-';
                              List<String> sideNotes =
                                  List<String>.from(day['side_note'] ?? []);
                              String dayNumber = (index + 1).toString();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildMiniTimelineItem('Day $dayNumber'),
                                  SizedBox(height: 5),
                                  // Day Title with Indicator
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 18.0, top: 4.0),
                                    child: Text(dayTitle,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ),
                                  SizedBox(height: 3),
                                  // List of side notes under each day
                                  ...sideNotes.map((note) => Padding(
                                        padding: const EdgeInsets.only(
                                            left: 18.0, top: 4.0, bottom: 4.0),
                                        child: Text(note),
                                      )),
                                  if (index != days.length - 1)
                                    Divider(
                                        thickness: 1,
                                        color: Colors.grey.shade300),
                                ],
                              );
                            }).toList(),
                          ),
                  )
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTimelineItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Purple Indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 135, 139, 227),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          // Title Text
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
