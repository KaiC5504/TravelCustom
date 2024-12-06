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

Future<void> trackUserInteraction(String userId, String subdestinationId,
    List<String> tags, String interactionType) async {
  // Get all interactions for the user
  QuerySnapshot existingInteraction = await FirebaseFirestore.instance
      .collection('interaction')
      .where('user_id', isEqualTo: userId)
      .where('destination_id', isEqualTo: subdestinationId)
      .get();

  // Get the current timestamp
  Timestamp now = Timestamp.now();
  double timeScore = calculateTimeBasedScore(now);

  if (existingInteraction.docs.isNotEmpty) {
    // Existing interaction found, refresh all interactions
    await refreshAllUserInteractions(
        userId, subdestinationId, tags, interactionType);
  } else {
    // No existing interaction for this sub-destination, create a new interaction document
    await FirebaseFirestore.instance.collection('interaction').add({
      'user_id': userId,
      'destination_id': subdestinationId,
      'preference_score': timeScore,
      'interaction_type': interactionType, // e.g., 'view', 'like', 'save'
      'tags': tags,
      'timestamp': now,
    }).then((value) {
      devtools.log(
          'Created new interaction for user $userId with sub-destination $subdestinationId, time score: $timeScore');
    }).catchError((error) {
      devtools.log('Failed to create interaction: $error');
    });

    // Now refresh all interactions (including this new one)
    await refreshAllUserInteractions(
        userId, subdestinationId, tags, interactionType);
  }
}

Future<void> refreshAllUserInteractions(
    String userId,
    String clickedSubdestinationId,
    List<String> clickedTags,
    String interactionType) async {
  // Get all interactions for the user
  QuerySnapshot allInteractionsSnapshot = await FirebaseFirestore.instance
      .collection('interaction')
      .where('user_id', isEqualTo: userId)
      .get();

  Timestamp now = Timestamp.now();
  double timeScore = calculateTimeBasedScore(now);

  // Loop through all interactions and refresh them
  for (var doc in allInteractionsSnapshot.docs) {
    var interactionData = doc.data() as Map<String, dynamic>;
    String interactionDocId = doc.id;
    String subdestinationId = interactionData['destination_id'];
    Timestamp lastInteractionTime = interactionData['timestamp'];
    double lastScore = interactionData['preference_score'];

    // Calculate time decay for each interaction
    double timeDecay = calculateTimeBasedScore(lastInteractionTime);
    double newScore = lastScore * timeDecay;

    if (subdestinationId == clickedSubdestinationId) {
      // Increase the score for the clicked sub-destination
      newScore += timeScore;

      // Update the interaction with the new preference score
      await FirebaseFirestore.instance
          .collection('interaction')
          .doc(interactionDocId)
          .update({
        'preference_score': newScore,
        'interaction_type': interactionType,
        'tags': clickedTags,
        'timestamp': now,
      });
    } else {
      if (newScore < 0.01) {
        newScore = 0; // Ensure that preference_score doesn't go below 0
      }

      await FirebaseFirestore.instance
          .collection('interaction')
          .doc(interactionDocId)
          .update({
        'preference_score': newScore,
        'timestamp': now,
      });
    }
  }

  devtools.log('All interactions refreshed for user $userId');
}

// Time-based score
double calculateTimeBasedScore(Timestamp timestamp) {
  final now = DateTime.now();
  final interactionTime = timestamp.toDate();
  final timeDifference = now.difference(interactionTime).inSeconds;

  //Recent higher score
  double score = 1 / (1 + timeDifference);

  //Set lowest
  if (score < 0) {
    score = 0;
  }

  return score;
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

Future<Map<String, double>> getUserPreferences(String userId) async {
  // Fetch all interactions for the given user
  QuerySnapshot userInteractions = await FirebaseFirestore.instance
      .collection('interaction')
      .where('user_id', isEqualTo: userId)
      .get();

  // Map to hold the cumulative preference score for each tag
  Map<String, double> tagPreferences = {};

  // Loop through each interaction and update the tag preference scores
  for (var doc in userInteractions.docs) {
    List<String> tags = List<String>.from(doc['tags']);
    double preferenceScore = doc['preference_score'];
    Timestamp interactionTimestamp = doc['timestamp'];

    // Apply time decay to each interaction
    double timeBasedWeight = calculateTimeBasedScore(interactionTimestamp);

    // Update the cumulative score for each tag
    for (String tag in tags) {
      tagPreferences[tag] =
          (tagPreferences[tag] ?? 0) + (preferenceScore * timeBasedWeight);
    }
  }

  return tagPreferences; // Return the map of tag preferences
}

void showUserPreferences(String userId) async {
  // Fetch the user's current preferences
  Map<String, double> userPreferences = await getUserPreferences(userId);

  // Sort the preferences by highest score (most interested tags)
  var sortedPreferences = userPreferences.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value)); // Sort in descending order

  // Display the sorted preferences
  for (var preference in sortedPreferences) {
    devtools.log(
        'Tag: ${preference.key}, Score: ${preference.value.toStringAsFixed(2)}');
  }

  // Show the user's top preference (most interested)
  if (sortedPreferences.isNotEmpty) {
    devtools.log(
        'User is currently most interested in: ${sortedPreferences.first.key}');
  } else {
    devtools.log('No preferences found for user.');
  }
}
