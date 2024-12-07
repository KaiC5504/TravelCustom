import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:typed_data';
import 'package:travelcustom/utilities/platform_post.dart';
import 'package:travelcustom/views/destination_detail.dart';
import 'package:travelcustom/views/planning.dart';
import 'package:travelcustom/views/post_destination.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:travelcustom/views/post_plan.dart';
import 'dart:developer' as devtools show log;

class PlatformPage extends StatefulWidget {
  const PlatformPage({super.key});

  @override
  State<PlatformPage> createState() => _PlatformPageState();
}

class _PlatformPageState extends State<PlatformPage> {
  final PlatformPostsContent _platformPostsContent = PlatformPostsContent();

  List<Map<String, dynamic>> destinationPosts = [];
  Map<String, Uint8List?> destinationProfilePictures = {};
  Map<String, Uint8List?> destinationImages = {};
  Map<String, String> destinationNames = {};

  List<Map<String, dynamic>> planPosts = [];
  Map<String, Uint8List?> planProfilePictures = {};

  bool showDestinations = true;

  @override
  void initState() {
    super.initState();
    _fetchDestinationPosts();
  }

  Future<void> _fetchDestinationPosts() async {
    try {
      final data = await _platformPostsContent.fetchDestinationPosts();

      setState(() {
        destinationPosts = data['combinedPosts'];
        destinationProfilePictures = data['profilePictures'];
        destinationImages = data['destinationImages'];

        destinationNames = {
          for (var post in destinationPosts)
            post['destinationId']: post['destination']
        };
      });
    } catch (e) {
      devtools.log('Error fetching posts: $e');
    }
  }

  Future<void> _fetchPlanPosts() async {
    try {
      // Fetch plan data from DestinationService
      final data = await _platformPostsContent.fetchPlanPosts();

      // Update the state with plan data
      setState(() {
        planPosts = data['planPosts'];
        planProfilePictures = data['profilePictures'];
      });
    } catch (e) {
      devtools.log('Error fetching travel plans: $e');
    }
  }

  void _toggleContent(bool showDestinations) {
    setState(() {
      this.showDestinations = showDestinations;
      if (showDestinations && destinationPosts.isEmpty) {
        _fetchDestinationPosts();
      } else if (!showDestinations && planPosts.isEmpty) {
        _fetchPlanPosts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('TravelCustom'),
        backgroundColor: Colors.grey[200],
        scrolledUnderElevation: 0,
      ),
      backgroundColor: Colors.grey[200],
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              // Toggle buttons for Destinations and Plans
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center the whole row
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        onPressed: () => _toggleContent(true),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: showDestinations
                              ? const Color.fromARGB(255, 131, 107, 174)
                              : Color.fromARGB(255, 114, 114, 114),
                          side: BorderSide(
                              color: showDestinations
                                  ? Color.fromARGB(255, 172, 155, 216)
                                  : Color.fromARGB(255, 77, 77, 77),
                              width: 2.0),
                        ),
                        child: Text("Destinations"),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        onPressed: () => _toggleContent(false),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: !showDestinations
                              ? const Color.fromARGB(255, 131, 107, 174)
                              : Color.fromARGB(255, 114, 114, 114),
                          side: BorderSide(
                              color: !showDestinations
                                  ? Color.fromARGB(255, 172, 155, 216)
                                  : Color.fromARGB(255, 77, 77, 77),
                              width: 2.0),
                        ),
                        child: Text("Plans"),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                height: 2,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 63, 63, 63)
                          .withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: Offset(0, 1), // changes position of shadow
                    ),
                  ],
                ),
              ),
              Expanded(
                child: showDestinations
                    ? _buildDestinationPosts()
                    : _buildPlanPosts(),
              ),
            ],
          ),

          // Posting button
          Positioned(
            bottom: 0,
            left: MediaQuery.of(context).size.width / 2 - 140 / 2,
            child: Material(
              color: Color.fromARGB(255, 56, 56, 56),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(45),
              ),
              child: InkWell(
                onTap: () async {
                  if (showDestinations) {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => PostDestinationPage()),
                    );

                    if (result == true) {
                      _fetchDestinationPosts();
                    }
                  } else {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => PostPlanPage()),
                    );

                    if (result == true) {
                      _fetchPlanPosts();
                    }
                  }
                },
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(45),
                ),
                splashColor: Color.fromARGB(255, 91, 91, 91).withOpacity(0.2),
                highlightColor: Color.fromARGB(255, 91, 91, 91)
                    .withOpacity(0.2), // Highlight color when pressed
                child: Hero(
                  tag: 'platform_add_button', 
                  child: Container(
                    width: 140,
                    height: 39, // Half the height for a semi-circle
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(45),
                      ),
                    ),
                    child: Icon(
                      FontAwesomeIcons.plus,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDestinationPosts() {
    return destinationPosts.isEmpty
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchDestinationPosts,
            child: ListView.builder(
              itemCount: destinationPosts.length,
              itemBuilder: (context, index) {
                var post = destinationPosts[index];
                Uint8List? profilePicture =
                    destinationProfilePictures[post['authorId']];
                String timeAgo =
                    timeago.format((post['postDate'] as Timestamp).toDate());

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Material(
                      color: Colors.white,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DestinationDetailPage(
                                destinationId: post['destinationId'], subdestinationId: post['subDestinationId'],
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: profilePicture != null
                                        ? MemoryImage(profilePicture)
                                        : null,
                                    backgroundColor: Colors.grey[200],
                                    child: profilePicture == null
                                        ? Icon(Icons.person)
                                        : null,
                                  ),
                                  SizedBox(width: 10.0),
                                  Text(
                                    post['authorName'],
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 5.0),
                                  Text(
                                    '(${post['authorRole']})',
                                    style: TextStyle(color: Colors.grey, fontSize: 12.0),
                                  ),
                                  Spacer(),
                                  Text(
                                    timeAgo,
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12.0),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.0),
                              Text(
                                post['destination'],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0),
                              ),
                              SizedBox(height: 8.0),
                              destinationImages[post['subDestinationId']] !=
                                      null
                                  ? Image.memory(
                                      destinationImages[
                                          post['subDestinationId']]!,
                                      height: 200.0,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 200.0,
                                      width: double.infinity,
                                      color: Colors.grey[200],
                                      child:
                                          Icon(Icons.error, color: Colors.red),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
  }

  Widget _buildPlanPosts() {
    return planPosts.isEmpty
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchPlanPosts,
            child: ListView.builder(
              itemCount: planPosts.length,
              itemBuilder: (context, index) {
                var post = planPosts[index];
                Uint8List? profilePicture = planProfilePictures[post['userId']];
                List<dynamic> days = post['days'];
                String timeAgo =
                    timeago.format((post['postDate'] as Timestamp).toDate());

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Material(
                      color: Colors.white,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PlanningView(
                                planId: post['planId'],
                                collectionName: 'platform_plans',
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: profilePicture != null
                                        ? MemoryImage(profilePicture)
                                        : null,
                                        backgroundColor: Colors.grey[300],
                                    child: profilePicture == null
                                        ? Icon(Icons.person)
                                        : null,
                                  ),
                                  SizedBox(width: 10.0),
                                  Text(
                                    post['authorName'],
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 5.0),
                                  Text(
                                    '(${post['authorRole']})',
                                    style: TextStyle(color: Colors.grey, fontSize: 12.0),
                                  ),
                                  Spacer(),
                                  Text(
                                    timeAgo,
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12.0),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.0),
                              Text(
                                post['planName'],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.0),
                              ),
                              SizedBox(height: 8.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Display day titles and side notes for each day
                                  for (var i = 0;
                                      i < (days.length > 3 ? 3 : days.length);
                                      i++)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            days[i]['dayTitle'] ?? 'No Title',
                                            style: TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 4.0),
                                          ...days[i]['sideNotes']
                                              .take(2)
                                              .map((note) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 2.0),
                                                    child: Text(
                                                      note,
                                                      style: TextStyle(
                                                          fontSize: 14.0,
                                                          color:
                                                              Colors.grey[700]),
                                                    ),
                                                  )),
                                        ],
                                      ),
                                    ),
                                  if (days.length > 3)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      child: Text(
                                        "......",
                                        style: TextStyle(
                                            fontSize: 18.0, color: Colors.grey),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
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
