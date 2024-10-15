// ignore_for_file: avoid_types_as_parameter_names

import 'dart:math';
import 'dart:developer' as devtools show log;
import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> fetchDestinations() async {
  QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('destinations').get();
  return snapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>)
      .toList();
}

Map<String, double> calculateTFIDF(
    List<String> document, List<List<String>> allDocuments) {
  Map<String, double> tf = {}; // Term frequency
  Map<String, double> idf = {}; // Inverse document frequency

  // Calculate term frequency
  for (String word in document) {
    tf[word] = (tf[word] ?? 0) + 1;
  }

  // Normalize term frequency
  int totalTerms = document.length;
  tf.updateAll((key, value) => value / totalTerms);

  // Calculate IDF for each term
  for (var doc in allDocuments) {
    doc.toSet().forEach((term) {
      idf[term] = (idf[term] ?? 0) + 1;
    });
  }

  idf.updateAll((term, count) => log(allDocuments.length / (count)));

  // Combine TF and IDF
  Map<String, double> tfidf = {};
  tf.forEach((term, tfValue) {
    tfidf[term] = tfValue * (idf[term] ?? 0);
  });

  return tfidf;
}

List<double> normalizeData(List<double> data) {
  double mean = data.reduce((a, b) => a + b) / data.length;
  double variance =
      data.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
          data.length;
  double stdDev = sqrt(variance);

  return data.map((x) => (x - mean) / stdDev).toList();
}

// Function to calculate Euclidean distance
double euclideanDistance(List<double> a, List<double> b) {
  double sum = 0.0;
  for (int i = 0; i < a.length; i++) {
    sum += pow(a[i] - b[i], 2);
  }
  return sqrt(sum);
}

// Function to find the k nearest neighbors
List<Map<String, dynamic>> knn(List<Map<String, dynamic>> destinations,
    List<double> inputFeatures, int k) {
  List<Map<String, dynamic>> sortedDestinations = List.from(destinations);

  sortedDestinations.sort((a, b) {
    List<double> featuresA = [
      a['rating'],
      a['entry_fee'],
      a['public_transport']
    ];
    List<double> featuresB = [
      b['rating'],
      b['entry_fee'],
      b['public_transport']
    ];

    double distanceA = euclideanDistance(featuresA, inputFeatures);
    double distanceB = euclideanDistance(featuresB, inputFeatures);

    return distanceA.compareTo(distanceB);
  });

  return sortedDestinations.take(k).toList();
}

Future<void> trackUserInteraction(String userId, String destinationId,
    List<String> tags, String interactionType) async {
  // Query to check if the user already has an interaction with this destination
  QuerySnapshot existingInteraction = await FirebaseFirestore.instance
      .collection('interaction')
      .where('user_id', isEqualTo: userId)
      .where('destination_id', isEqualTo: destinationId)
      .get();

  if (existingInteraction.docs.isNotEmpty) {
    //exist user
    String interactionDocId = existingInteraction.docs.first.id;
    FirebaseFirestore.instance
        .collection('interaction')
        .doc(interactionDocId)
        .update(
      {
        'interaction_type': interactionType, // e.g., 'view', 'like', 'save'
        'tags': tags,
        'view_count': FieldValue.increment(1),
        'timestamp': FieldValue.serverTimestamp(),
      },
    ).then(
      (value) {
        devtools.log(
            'Successfully recorded $interactionType interaction for user $userId');
      },
    ).catchError(
      (error) {
        devtools.log(
            'Failed to record $interactionType interaction for user $userId: $error');
      },
    );
  } else {
    //not exist user
    FirebaseFirestore.instance.collection('interaction').add(
      {
        'user_id': userId,
        'destination_id': destinationId,
        'interaction_type': interactionType,
        'tags': tags,
        'view_count': FieldValue.increment(1),
        'timestamp': FieldValue.serverTimestamp(),
      },
    ).then(
      (value) {
        devtools.log(
            'Created new interaction for user $userId with destination $destinationId');
      },
    ).catchError(
      (error) {
        devtools.log('Failed to create interaction: $error');
      },
    );
  }
}

Future<List<String>> detectUserPreferences(String userId) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('interaction')
      .where('user_id', isEqualTo: userId)
      .where('interaction_type', isEqualTo: 'view')
      .get();

  // Aggregate the types of destinations the user interacted with
  Map<String, int> typeCounts = {};
  for (var doc in snapshot.docs) {
    List<String> destinationTypes = List<String>.from(doc['tags']);
    for (var type in destinationTypes) {
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }
  }

  if (typeCounts.isEmpty) {
    return [];
  }

  // Sort types by frequency to detect top preferences
  List<String> sortedPreferences = typeCounts.keys.toList()
    ..sort((a, b) => typeCounts[b]!.compareTo(typeCounts[a]!));

  return sortedPreferences;
}

Future<List<Map<String, dynamic>>> recommendDestinationsBasedOnPreferences(
    String userId) async {
  // Step 1: Detect the user's preferences
  List<String> userPreferences = await detectUserPreferences(userId);

  // Step 2: Fetch all destinations from Firestore
  List<Map<String, dynamic>> destinations = await fetchDestinations();

  if (userPreferences.isEmpty) {
    return [];
  }

  // Step 3: Filter destinations by matching types with user preferences
  List<Map<String, dynamic>> recommendedDestinations =
      destinations.where((destination) {
    List<String> destinationTypes = List<String>.from(destination['type']);
    return destinationTypes.any((type) => userPreferences.contains(type));
  }).toList();

  return recommendedDestinations;
}
