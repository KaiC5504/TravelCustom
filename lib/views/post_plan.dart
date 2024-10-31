import 'package:flutter/material.dart';

class PostPlanPage extends StatelessWidget {
  const PostPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Travel Plan'),
        backgroundColor: Colors.grey[200],
      ),
      body: Center(
        child: Text(
          'Form to create a new travel plan',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
