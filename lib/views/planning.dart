// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:developer' as devtools show log;
import 'package:intl/intl.dart';
import 'package:travelcustom/constants/routes.dart';
import 'package:travelcustom/views/search_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:travelcustom/utilities/display_error.dart';

class PlanningView extends StatefulWidget {
  final String? planId;
  final String collectionName;
  final bool newDay;
  final bool existingDay;
  final String? subDestinationName;
  final bool addToSideNote;
  final bool showAddDayDialog;
  final String? initialSideNote;

  const PlanningView(
      {super.key,
      this.planId,
      this.collectionName = 'travel_plans',
      this.newDay = false,
      this.existingDay = false,
      this.subDestinationName,
      this.addToSideNote = false,
      this.showAddDayDialog = false,
      this.initialSideNote});

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
  bool isLoading = true;
  final ValueNotifier<int> _reviewCountNotifier = ValueNotifier<int>(0);
  final GlobalKey<PlanReviewsWidgetState> _reviewsWidgetKey =
      GlobalKey<PlanReviewsWidgetState>();
  bool _dataInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlan();
  }

  Future<void> _initializePlan() async {
    await fetchTravelPlanDetails();
    setState(() {
      _dataInitialized = true;
    });

   
    if (_dataInitialized && widget.showAddDayDialog && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        int nextDayNumber = activities.length + 1;
        _addDay(
            initialSideNote: widget.initialSideNote,
            forcedDayNumber: nextDayNumber);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchTravelPlanDetails() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoading = true;
      });

      String planId = widget.planId ?? await _getUserPlanId();
      if (planId.isEmpty) {
        setState(() {
          activities = [];
          isLoading = false;
        });
        return;
      }

      DocumentSnapshot planDoc = await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(planId)
          .get();

      if (!mounted) return;

      if (planDoc.exists) {
        Map<String, dynamic>? planData =
            planDoc.data() as Map<String, dynamic>?;
        if (planData != null) {
          List<Map<String, dynamic>> fetchedDays =
              List<Map<String, dynamic>>.from(planData['days'] ?? []);

          setState(() {
            activities = fetchedDays;
            planName = planData['plan_name'] ?? '';
            startDate = DateFormat('dd-MM-yyyy')
                .format((planData['start'] as Timestamp).toDate());
            endDate = DateFormat('dd-MM-yyyy')
                .format((planData['end'] as Timestamp).toDate());
          });
        }
      }
    } catch (e) {
      devtools.log('Error fetching plan details: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<String> _getUserPlanId() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return '';

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    return userDoc.exists ? userDoc['planId'] ?? '' : '';
  }

  Future<void> _addDay({String? initialSideNote, int? forcedDayNumber}) async {
   
    int newDayNumber = forcedDayNumber ?? activities.length + 1;
    TextEditingController dayTitleController = TextEditingController();
    List<String> newSideNotes = [];

    if (initialSideNote != null) {
      newSideNotes.add(initialSideNote);
    }

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
              double screenHeight = MediaQuery.of(context).size.height;
              double screenWidth = MediaQuery.of(context).size.width;
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.8,
                  maxWidth: screenWidth * 0.9,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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

                        
                        SizedBox(
                          height: 150,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children:
                                  newSideNotes.asMap().entries.map((entry) {
                                int idx = entry.key;
                                String note = entry.value;
                                return Container(
                                  margin: EdgeInsets.symmetric(vertical: 2),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          note,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            newSideNotes.removeAt(idx);
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                               
                                final location = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchPage(
                                      fromLocationButton: true,
                                    ),
                                  ),
                                );
                                if (location != null) {
                                  setState(() {
                                    newSideNotes.add(location);
                                    devtools.log(
                                        'PPP Location to Side: $newSideNotes');
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
                                String dayTitle =
                                    dayTitleController.text.trim();
                                if (dayTitle.isEmpty) {
                                  displayCustomErrorMessage(
                                    context,
                                    'Please enter a title for the day',
                                  );
                                  return;
                                }

                                await _saveNewDayToFirestore(
                                    newDayNumber, dayTitle, newSideNotes);
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                    naviRoute, (Route<dynamic> route) => false);
                                await fetchTravelPlanDetails(); 
                              },
                              child: Text('Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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

  Future<void> autoPlan(String userInput) async {
    final apiKey =
        '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';
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful assistant.'},
            {
              'role': 'user',
              'content':
                  "Generate a travel plan based on the following input: $userInput. Please use the following format for each day:\n\nDay Title\nSide Note (3 words)\nSide Note (3 words)\nSide Note (3 words)\n\nOnly provide the title and three-word side notes as requested, with no additional labels like 'Day 1' or 'Day 2'. Also, add relevant side notes, such as restaurant recommendations, activities, or nearby attractions."
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final planText = data['choices'][0]['message']['content'];

        devtools.log('API Response: $planText');

      
        List<Map<String, dynamic>> generatedPlan = _parsePlanText(planText);

        if (mounted) {
          setState(() {
            activities = generatedPlan;
          });
        }

       
        await _saveGeneratedPlanToFirestore(generatedPlan);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']['message'];
        devtools.log('Failed to generate plan: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate plan: $errorMessage')),
        );
      }
    } catch (e) {
      devtools.log('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  Future<void> _saveGeneratedPlanToFirestore(
      List<Map<String, dynamic>> generatedPlan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final planId = await _getUserPlanId();
    if (planId.isEmpty) return;

    final planDocRef =
        FirebaseFirestore.instance.collection('travel_plans').doc(planId);

    await planDocRef.update({
      'days': generatedPlan,
    });
  }

  List<Map<String, dynamic>> _parsePlanText(String planText) {
    List<Map<String, dynamic>> parsedPlan = [];
    List<String> days = planText.split('\n\n');

    for (String day in days) {
      List<String> lines = day.split('\n');
      if (lines.isNotEmpty) {
        String dayTitle = lines[0].replaceAll('**', '').trim();
        List<String> sideNotes = lines
            .sublist(1)
            .map((note) =>
                note.replaceFirst('-', '').trim().split(' ').join(' '))
            .toList();
        parsedPlan.add({
          'day_title': dayTitle,
          'side_note': sideNotes,
        });
      }
    }

    return parsedPlan;
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double rating = 0;
        TextEditingController reviewController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[200],
              title: const Center(child: Text('Write a Review')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rating:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color:
                              index < rating ? Colors.amber[600] : Colors.grey,
                          size: 40.0,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Review:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                   
                    if (rating == 0) {
                      displayCustomErrorMessage(
                        context,
                        'Please provide a rating',
                      );
                      return;
                    }
                    if (reviewController.text.trim().isEmpty) {
                      displayCustomErrorMessage(
                        context,
                        'Please write a review',
                      );
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('platform_plans')
                        .doc(widget.planId)
                        .collection('reviews')
                        .add({
                      'userId': FirebaseAuth.instance.currentUser?.uid,
                      'rating': rating,
                      'review_content': reviewController.text,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    Navigator.of(context).pop();
                    _reviewsWidgetKey.currentState?.refreshReviews();
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editDay(int dayIndex, Map<String, dynamic> dayData) async {
    TextEditingController dayTitleController =
        TextEditingController(text: dayData['day_title']);
    List<String> editedSideNotes =
        List<String>.from(dayData['side_note'] ?? []);

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
              double screenHeight = MediaQuery.of(context).size.height;
              double screenWidth = MediaQuery.of(context).size.width;

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.8,
                  maxWidth: screenWidth * 0.9,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Day ${dayIndex + 1}',
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
                       
                        SizedBox(
                          height: 150,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children:
                                  editedSideNotes.asMap().entries.map((entry) {
                                int idx = entry.key;
                                String note = entry.value;
                                return Container(
                                  margin: EdgeInsets.symmetric(vertical: 2),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          note,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            editedSideNotes.removeAt(idx);
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final location = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchPage(
                                      fromLocationButton: true,
                                    ),
                                  ),
                                );
                                if (location != null) {
                                  setState(() {
                                    editedSideNotes.add(location);
                                  });
                                }
                              },
                              child: Text('Location'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _addSideNote(
                                    context, setState, editedSideNotes);
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
                                String dayTitle =
                                    dayTitleController.text.trim();
                                if (dayTitle.isEmpty) {
                                  displayCustomErrorMessage(
                                    context,
                                    'Please enter a title for the day',
                                  );
                                  return;
                                }
                                await _updateDayInFirestore(
                                    dayIndex, dayTitle, editedSideNotes);
                                Navigator.of(context).pop();
                                await fetchTravelPlanDetails();
                              },
                              child: Text('Save'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _updateDayInFirestore(
      int dayIndex, String dayTitle, List<String> sideNotes) async {
    final planId = await _getUserPlanId();
    if (planId.isEmpty) return;

    final planDocRef =
        FirebaseFirestore.instance.collection('travel_plans').doc(planId);

    List<Map<String, dynamic>> updatedDays = List.from(activities);
    updatedDays[dayIndex] = {
      'day_title': dayTitle,
      'side_note': sideNotes,
    };

    await planDocRef.update({
      'days': updatedDays,
    });
  }

  Future<void> _deleteDay(int dayIndex) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Day'),
        content: Text('Are you sure you want to delete this day?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final planId = await _getUserPlanId();
      if (planId.isEmpty) return;

      final planDocRef =
          FirebaseFirestore.instance.collection('travel_plans').doc(planId);

      List<Map<String, dynamic>> updatedDays = List.from(activities);
      updatedDays.removeAt(dayIndex);

      await planDocRef.update({
        'days': updatedDays,
      });

      await fetchTravelPlanDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Travel Plan'),
          backgroundColor: Colors.grey[200],
          scrolledUnderElevation: 0,
        ),
        backgroundColor: Colors.grey[200],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                'You are not logged in',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(loginRoute);
                },
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchTravelPlanDetails,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: activities.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.8,
                            child: Center(
                              child: Text(
                                'No Travel Plan',
                                style:
                                    TextStyle(fontSize: 18, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        children: [
                          
                          if (widget.collectionName == 'platform_plans') ...[
                            const Text(
                              "Recent Reviews: ",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            PlanReviewsWidget(
                              key: _reviewsWidgetKey,
                              planId: widget.planId ?? '',
                              onReviewsLoaded: (reviewCount) {
                                _reviewCountNotifier.value = reviewCount;
                              },
                            ),
                            const SizedBox(height: 50),
                          ],
                        
                          ...List.generate(
                            activities.length,
                            (index) {
                              final dayData = activities[index];
                              final dayTitle =
                                  dayData['day_title'] ?? 'No Title';
                              final sideNotes =
                                  List<String>.from(dayData['side_note'] ?? []);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 50.0),
                                child: _buildPlanDays(
                                  'Day ${index + 1}',
                                  dayTitle,
                                  sideNotes,
                                  index,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          if (widget.collectionName == 'platform_plans') ...[
                            Center(
                              child: ElevatedButton(
                                onPressed: _showReviewDialog,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.grey[800],
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text('Write a Review'),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
      floatingActionButton: widget.collectionName == 'travel_plans'
          ? Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'add_day_button',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    onPressed: _addDay,
                    backgroundColor: const Color.fromARGB(255, 135, 139, 227),
                    child: FaIcon(FontAwesomeIcons.plus, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  FloatingActionButton(
                    heroTag: 'auto_plan_button',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    onPressed: () async {
                      String userInput = await _getUserInputForAutoPlan();
                      if (userInput.isNotEmpty) {
                        await autoPlan(userInput);
                      }
                    },
                    backgroundColor: const Color.fromARGB(255, 135, 139, 227),
                    child:
                        FaIcon(FontAwesomeIcons.wandMagic, color: Colors.white),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Future<String> _getUserInputForAutoPlan() async {
    TextEditingController userInputController = TextEditingController();
    String userInput = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter your travel preferences'),
          content: TextField(
            controller: userInputController,
            decoration: InputDecoration(labelText: 'Describe your travel plan'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                userInput = userInputController.text;
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );

    return userInput;
  }

  Widget _buildPlanDays(
      String day, String title, List<String> sideNotes, int index) {
    return GestureDetector(
      onLongPress: widget.collectionName == 'travel_plans'
          ? () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Manage Day ${index + 1}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        onTap: () {
                          Navigator.pop(context);
                          _editDay(index,
                              activities[index]); 
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title:
                            Text('Delete', style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          _deleteDay(index);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Icon(
            Icons.location_on,
            color: const Color.fromARGB(255, 135, 139, 227),
            size: 30,
          ),
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
      ),
    );
  }
}

class PlanReviewsWidget extends StatefulWidget {
  final String planId;
  final Function(int) onReviewsLoaded;

  const PlanReviewsWidget({
    super.key,
    required this.planId,
    required this.onReviewsLoaded,
  });

  @override
  PlanReviewsWidgetState createState() => PlanReviewsWidgetState();
}

class PlanReviewsWidgetState extends State<PlanReviewsWidget> {
  Future<List<Map<String, dynamic>>> _fetchReviews() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('platform_plans')
          .doc(widget.planId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .get();

      final reviews = await Future.wait(querySnapshot.docs.map((doc) async {
        final data = doc.data();
        final userId = data['userId'] as String?;
        String userName = 'Anonymous';

        if (userId != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          userName = userDoc.data()?['name'] ?? 'Anonymous';
        }

        return {
          ...data,
          'userName': userName,
        };
      }));

      widget.onReviewsLoaded(reviews.length);
      return reviews;
    } catch (e) {
      devtools.log('Error fetching reviews: $e');
      widget.onReviewsLoaded(0);
      return [];
    }
  }

  void refreshReviews() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No reviews available');
        }

        final reviews = snapshot.data!;
        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['userName'] ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          review['rating'].toInt().toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Icon(
                          Icons.star,
                          color: Colors.yellow,
                          size: 23,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      review['review_content'] ?? 'No review',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.black,
                      ),
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
}
