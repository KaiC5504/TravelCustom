// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

class TravelPlanView extends StatefulWidget {
  const TravelPlanView({super.key});

  @override
  _TravelPlanViewState createState() => _TravelPlanViewState();
}

class _TravelPlanViewState extends State<TravelPlanView> {
  String selectedDate = 'Date';

  // Sample data for time and location
  final List<Map<String, String>> travelPlan = [
    {'time': '10AM', 'location': '1'},
    {'time': '11AM', 'location': '2'},
    {'time': '12AM', 'location': '3'},
    {'time': '1PM', 'location': '4'},
    {'time': '2PM', 'location': '5'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Travelling Plan',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Dropdown button for date selection
            // Dropdown button with a black border
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color.fromARGB(255, 88, 88, 88),
                        width: 1), // Black border with 2px width
                    borderRadius:
                        BorderRadius.circular(20), // Optional: Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10), // Add some padding inside the container
                  child: DropdownButton<String>(
                    value: selectedDate,
                    items: <String>['Date', 'Date1', 'Date2', 'Date3']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedDate = newValue!;
                      });
                    },
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    elevation: 16,
                    icon: const Icon(Icons.arrow_drop_down),
                    borderRadius: BorderRadius.circular(20),
                    underline: Container(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Table for time and location
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(),
                  columnWidths: const {
                    0: FractionColumnWidth(0.3),
                    1: FractionColumnWidth(0.7),
                  },
                  children: [
                    // Table header
                    const TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Time',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Location',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Table rows with time and location
                    for (var entry in travelPlan)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(),
                              ),
                              child: Center(child: Text(entry['time']!)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(child: Text(entry['location']!)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
