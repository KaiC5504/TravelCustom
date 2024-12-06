import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticPage extends StatelessWidget {
  const StatisticPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.grey[200],
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('trending_locations')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No trending locations found.'));
          }
          final locations = snapshot.data!.docs;
          return ListView.builder(
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return ListTile(
                title: Text(location['name']),
                subtitle: Text(location['tags'].join(', ')),
              );
            },
          );
        },
      ),
    );
  }
}
