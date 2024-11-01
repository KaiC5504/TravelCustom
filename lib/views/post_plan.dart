// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'dart:developer' as devtools show log;

class PostPlanPage extends StatefulWidget {
  const PostPlanPage({super.key});

  @override
  State<PostPlanPage> createState() => _PostPlanPageState();
}

class _PostPlanPageState extends State<PostPlanPage> {
  final TextEditingController _nameController = TextEditingController();
  String planName = '';
  List<Map<String, dynamic>> activities = [];
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

        List<Map<String, dynamic>> fetchedActivities =
            List<Map<String, dynamic>>.from(planData['activities'] ?? []);

        // Fetch destination names for any destinationIds
        await fetchDestinationNames(fetchedActivities);

        setState(() {
          planName = planData['plan_name'] ?? 'Untitled Plan';
          activities =
              List<Map<String, dynamic>>.from(planData['activities'] ?? []);
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

  void _showEmptyNameDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text('No name')),
          content: Text('Please enter a name for your travel plan.'),
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

    if (planName.isEmpty) {
      _showEmptyNameDialog();
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
              'Name of Plan',
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
            SizedBox(height: 24.0),
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
                    child: activities.isEmpty
                        ? Text('No activities in Travel Plan')
                        : Column(
                            children: activities.map((activity) {
                              String displayDestination =
                                  destinationNames[activity['destination']] ??
                                      activity['destination'];
                              return _buildMiniTimelineItem(
                                activity['time'] ?? 'No time',
                                displayDestination,
                              );
                            }).toList(),
                          ),
                  )
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTimelineItem(String time, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TimelineTile(
        alignment: TimelineAlign.manual,
        lineXY: 0.3,
        isFirst: false,
        isLast: false,
        indicatorStyle: IndicatorStyle(
          width: 20,
          color: const Color.fromARGB(255, 135, 139, 227),
          padding: EdgeInsets.all(6),
        ),
        beforeLineStyle: LineStyle(
          color: Color.fromARGB(255, 127, 127, 127),
          thickness: 4,
        ),
        afterLineStyle: LineStyle(
          color: const Color.fromARGB(255, 127, 127, 127),
          thickness: 4,
        ),
        // Time
        startChild: Container(
          alignment: Alignment.centerRight,
          width: 60,
          child: Text(
            time,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        // Activity Title
        endChild: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
