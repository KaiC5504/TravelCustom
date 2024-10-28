import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PlatformPage extends StatelessWidget {
  const PlatformPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Travel Posts'),
        backgroundColor: Colors.grey[200],
      ),
      backgroundColor: Colors.grey[200],
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main content: List of posts
          ListView.builder(
            itemCount: 10, // Placeholder for number of posts
            itemBuilder: (context, index) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Material(
                    color: Colors.white,
                    child: InkWell(
                      onTap: () {
                        devtools.log('Post $index tapped');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                SizedBox(width: 10.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Name',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Spacer(),
                                Text(
                                  'How Long Ago',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Destination Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                                SizedBox(height: 8.0),
                                Image.network(
                                  'https://cdn.britannica.com/49/102749-050-B4874C95/Kuala-Lumpur-Malaysia.jpg',
                                  height: 200.0,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ],
                            ),
                            SizedBox(height: 16.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Floating Action Button at the bottom center
          Positioned(
            bottom: 0, // Adjust to control overlap
            left: MediaQuery.of(context).size.width / 2 - 140 / 2,
            child: Material(
              color: Color.fromARGB(255, 56, 56, 56),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(45),
              ),
              child: InkWell(
                onTap: () {
                  devtools.log('Add button tapped');
                },
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(45),
                ),
                splashColor: Color.fromARGB(255, 91, 91, 91).withOpacity(0.2),
                highlightColor: Color.fromARGB(255, 91, 91, 91)
                    .withOpacity(0.2), // Highlight color when pressed
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
          )
        ],
      ),
    );
  }
}
