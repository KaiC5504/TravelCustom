import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'dart:developer' as devtools show log;
import 'package:intl/intl.dart';

class TravelPlanView extends StatefulWidget {
  const TravelPlanView({super.key});

  @override
  State<TravelPlanView> createState() => _TravelPlanViewState();
}

class _TravelPlanViewState extends State<TravelPlanView> {
  int selectedDay = 1;
  String planName = '';
  String startDate = '';
  String endDate = '';
  List<Map<String, dynamic>> activities = [];
  Map<String, String> destinationNames = {};

  @override
  void initState() {
    super.initState();
    checkUserHasPlan();
    setState(() {
      fetchTravelPlanDetails();
    });
  }

  Future<void> fetchTravelPlanDetails() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        devtools.log('User is not logged in');
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;
        if (userData != null && userData['planId'] != null) {
          String planId = userData['planId'];

          // Fetch the travel plan document
          DocumentSnapshot planDoc = await FirebaseFirestore.instance
              .collection('travel_plans')
              .doc(planId)
              .get();

          if (planDoc.exists) {
            Map<String, dynamic>? planData =
                planDoc.data() as Map<String, dynamic>?;
            if (planData != null) {
              List<Map<String, dynamic>> fetchedActivities =
                  List<Map<String, dynamic>>.from(planData['activities'] ?? []);

              for (var activity in fetchedActivities) {
                String destinationId = activity['destination'] ?? '';
                if (destinationId.isNotEmpty) {
                  DocumentSnapshot destinationDoc = await FirebaseFirestore
                      .instance
                      .collection('destinations')
                      .doc(destinationId)
                      .get();

                  if (destinationDoc.exists) {
                    String destinationName =
                        destinationDoc['destination'] ?? 'Not Found';
                    destinationNames[destinationId] = destinationName;
                  }
                }
              }

              setState(() {
                planName = planData['planName'] ?? '';
                Timestamp startTimestamp = planData['start'] ?? Timestamp.now();
                Timestamp endTimestamp = planData['end'] ?? Timestamp.now();
                startDate =
                    DateFormat('dd-MM-yyyy').format(startTimestamp.toDate());
                endDate =
                    DateFormat('dd-MM-yyyy').format(endTimestamp.toDate());
                activities = fetchedActivities;
              });
              devtools.log(
                  'Fetched travel plan details: $planName, $startDate - $endDate, Activities: ${activities.length}');
            }
          } else {
            devtools.log('Plan document does not exist.');
          }
        }
      } else {
        devtools.log('User document does not exist.');
      }
    } catch (e) {
      devtools.log('Error fetching travel plan details: $e');
    }
  }

  Future<void> checkUserHasPlan() async {
    try {
      // Get the current user ID
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        devtools.log('User is not logged in');
        return;
      }

      // Reference to the 'users' collection and the specific user document
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Check if the 'planId' field exists and is not empty
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;
        if (userData != null && userData['planId'] != null) {
          String planId = userData['planId'];
          if (planId.isNotEmpty) {
            devtools.log('User has a planId: $planId');
          } else {
            devtools.log('No plan, creating new planId...');
            String newPlanId =
                FirebaseFirestore.instance.collection('travel_plans').doc().id;

            // Create a new travel plan document with the newPlanId
            await FirebaseFirestore.instance
                .collection('travel_plans')
                .doc(newPlanId)
                .set({
              'planName': '',
              'start': Timestamp.now(),
              'end': Timestamp.now(),
              'activities': [],
              'userId': userId,
            });

            // Update the user's document with the new planId
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({'planId': newPlanId});

            devtools.log('New plan ID created and stored: $newPlanId');
            fetchTravelPlanDetails();
          }
        } else {
          devtools.log('User does not have a plan.');
        }
      } else {
        devtools.log('User document does not exist.');
      }
    } catch (e) {
      devtools.log('Error checking user plan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Detail Plan'),
      ),
      body: Column(
        children: [
          // Day Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDayButton(1, startDate),
              SizedBox(width: 10),
              _buildDayButton(2, endDate),
              IconButton(
                icon: Icon(Icons.add_circle_outline),
                onPressed: () {
                  // Add new day functionality can go here
                },
              ),
            ],
          ),
          Divider(),
          // Timeline for the selected day
          Expanded(
            child: ListView(
              children: activities.asMap().map((index, activity) {
                String activityTime = activity['time'] ?? '';
                String destinationId = activity['destination'] ?? '';
                String activityDestination =
                    destinationNames[destinationId] ?? 'Unknown Destination';
                return MapEntry(
                    index,
                    _buildTimeLineItem(
                      activityTime,
                      activityDestination,
                      Icons.location_on,
                      isFirst: index == 0,
                    ));
              }).values.toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Day switch button builder
  Widget _buildDayButton(int day, String date) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: selectedDay == day ? Colors.white : Colors.black,
        backgroundColor: selectedDay == day
            ? const Color.fromARGB(255, 206, 119, 221)
            : Colors.grey[300],
      ),
      onPressed: () {
        setState(() {
          selectedDay = day;
        });
      },
      child: Column(
        children: [
          Text('Day $day'),
          Text(date),
        ],
      ),
    );
  }

  // Timeline Item Builder
  Widget _buildTimeLineItem(String time, String title, IconData icon,
      {bool isFirst = false, bool isLast = false}) {
    return SizedBox(
      height: 110,
      child: TimelineTile(
        alignment: TimelineAlign.manual,
        lineXY: 0.2, // Adjust to position the line between time and activity
        isFirst: isFirst,
        isLast: isLast,
        indicatorStyle: IndicatorStyle(
          width: 40,
          color: const Color.fromARGB(255, 135, 139, 227),
          padding: EdgeInsets.all(6),
          iconStyle: IconStyle(
            iconData: icon,
            color: Colors.white,
            fontSize: 30,
          ),
        ),
        beforeLineStyle: LineStyle(
          color: Color.fromARGB(255, 127, 127, 127),
          thickness: 6,
        ),
        afterLineStyle: LineStyle(
          color: const Color.fromARGB(255, 127, 127, 127),
          thickness: 6,
        ),

        //Time
        startChild: Container(
          alignment: Alignment.centerRight,
          width: 80,
          child: Padding(
            padding:
                const EdgeInsets.only(right: 10.0), // Increase padding here
            child: Text(
              time,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),

        //Activity
        endChild: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
