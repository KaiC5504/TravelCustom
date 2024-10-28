// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'dart:developer' as devtools show log;
import 'package:intl/intl.dart';
import 'package:travelcustom/views/search_view.dart';

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

              // Sort the activities by time
              fetchedActivities.sort((a, b) {
                int timeAInMinutes =
                    _convertTimeToMinutes(a['time'] ?? '12:00 AM');
                int timeBInMinutes =
                    _convertTimeToMinutes(b['time'] ?? '12:00 AM');
                return timeAInMinutes.compareTo(timeBInMinutes);
              });

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

                if (mounted) {
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
                }
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

  int _convertTimeToMinutes(String time) {
    try {
      final isPM = time.toLowerCase().contains('pm');
      final parts = time.split(':');
      int hour = int.parse(parts[0].trim());
      int minute = int.parse(parts[1].split(' ')[0].trim());

      if (isPM && hour != 12) {
        hour += 12;
      } else if (!isPM && hour == 12) {
        hour = 0;
      }

      return hour * 60 + minute;
    } catch (e) {
      devtools.log('Error converting time to minutes: $e');
      return 0;
    }
  }

  void _deleteActivity(int index) async {
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
        String planId = userDoc['planId'] ?? '';
        if (planId.isNotEmpty) {
          Map<String, dynamic> activityToDelete = activities[index];
          await FirebaseFirestore.instance
              .collection('travel_plans')
              .doc(planId)
              .update({
            'activities': FieldValue.arrayRemove([activityToDelete])
          });

          setState(() {
            activities.removeAt(index);
          });

          devtools.log('Activity deleted successfully');
        }
      }
    } catch (e) {
      devtools.log('Error deleting activity: $e');
    }
  }

  void _handleDeleteActivity(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text('Delete Activity')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.cancel, color: Colors.black),
                    label:
                        Text('Cancel', style: TextStyle(color: Colors.black)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text('Delete', style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      _deleteActivity(index);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Travel Plan'),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Center(
                    child: Text(
                      'Add to Plan',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => const SearchPage()),
                          );
                        },
                        child: Text(
                          'Add Destination',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              TextEditingController destinationController =
                                  TextEditingController();
                              TimeOfDay? selectedTime;

                              return AlertDialog(
                                title: Text(
                                  'Create Custom Activity',
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: destinationController,
                                      decoration: InputDecoration(
                                          labelText: 'Destination'),
                                    ),
                                    SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: () async {
                                        selectedTime = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now(),
                                        );
                                        setState(() {});
                                      },
                                      child: Text('Select Time'),
                                    ),
                                    if (selectedTime != null)
                                      Text(
                                          'Selected Time: ${selectedTime!.format(context)}'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      if (destinationController
                                              .text.isNotEmpty &&
                                          selectedTime != null) {
                                        String destination =
                                            destinationController.text;
                                        String time =
                                            selectedTime!.format(context);

                                        String userId = FirebaseAuth
                                                .instance.currentUser?.uid ??
                                            '';
                                        if (userId.isNotEmpty) {
                                          FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userId)
                                              .get()
                                              .then(
                                            (userDoc) {
                                              if (userDoc.exists) {
                                                String planId =
                                                    userDoc['planId'] ?? '';
                                                if (planId.isNotEmpty) {
                                                  FirebaseFirestore.instance
                                                      .collection(
                                                          'travel_plans')
                                                      .doc(planId)
                                                      .update(
                                                    {
                                                      'activities':
                                                          FieldValue.arrayUnion(
                                                        [
                                                          {
                                                            'destination':
                                                                destination,
                                                            'time': time
                                                          }
                                                        ],
                                                      )
                                                    },
                                                  );
                                                }
                                              }
                                            },
                                          );
                                        }

                                        // Add the new custom activity to the activities list
                                        setState(() {
                                          activities.add({
                                            'destination': destination,
                                            'time': time
                                          });
                                        });

                                        Navigator.of(context).pop();
                                        fetchTravelPlanDetails();
                                      }
                                    },
                                    child: Text('Add Activity'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Text(
                          'Create Custom Activity',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          backgroundColor: const Color.fromARGB(255, 135, 139, 227),
          child: FaIcon(FontAwesomeIcons.plus, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Day Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDayButton(1, startDate),
              IconButton(
                icon: Icon(Icons.add_circle_outline),
                onPressed: () {
                  //New day functionality
                },
              ),
            ],
          ),
          Divider(),
          // Timeline for the selected day
          Expanded(
            child: ListView(
              children: activities
                  .asMap()
                  .map((index, activity) {
                    String activityTime = activity['time'] ?? '';
                    String destinationId = activity['destination'] ?? '';
                    String activityDestination =
                        destinationNames.containsKey(destinationId)
                            ? destinationNames[destinationId]!
                            : destinationId;

                    return MapEntry(
                        index,
                        GestureDetector(
                          onLongPress: () {
                            _handleDeleteActivity(index);
                          },
                          child: _buildTimeLineItem(
                            activityTime,
                            activityDestination,
                            Icons.location_on,
                            isFirst: index == 0,
                            isLast: index == activities.length - 1,
                          ),
                        ));
                  })
                  .values
                  .toList(),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = MediaQuery.of(context).size.width;
        devtools.log('Screen width: $screenWidth');
        double lineXY;
        bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;
        devtools.log('Is iOS: $isIOS');

        if (isIOS) {
          if (screenWidth >= 430) {
            lineXY = 0.3;
          } else if (screenWidth >= 400) {
            lineXY = 0.32;
          } else {
            lineXY = 0.35;
          }
        } else {
          if (screenWidth >= 448) {
            lineXY = 0.27;
          } else if (screenWidth >= 426) {
            lineXY = 0.28;
          } else if (screenWidth >= 412) {
            lineXY = 0.29;
          } else if (screenWidth >= 350) {
            lineXY = 0.33;
          } else {
            lineXY = 0.45;
          }
        }

        return SizedBox(
          height: 110,
          child: TimelineTile(
            alignment: TimelineAlign.manual,
            lineXY: lineXY,
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

            // Time
            startChild: Container(
              alignment: Alignment.centerRight,
              width: 80,
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Text(
                  time,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),

            // Activity
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
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
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
}
