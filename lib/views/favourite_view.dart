import 'package:flutter/material.dart';

class FavouritePage extends StatelessWidget {
  const FavouritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Favourites'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: 3, // You can update this to reflect your list length
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Card(
                elevation: 3,
                child: Container(
                  height: 100, // Adjust the height as necessary
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300], // Gray background
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Location', // This will be replaced with the actual location name
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}