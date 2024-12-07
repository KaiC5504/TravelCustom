// ignore_for_file: avoid_types_as_parameter_names

import 'dart:developer' as devtools show log;
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> trackUserInteraction(String userId, String subdestinationId,
    List<String> tags, String interactionType) async {
  // Get interactions
  QuerySnapshot existingInteraction = await FirebaseFirestore.instance
      .collection('interaction')
      .where('user_id', isEqualTo: userId)
      .where('destination_id', isEqualTo: subdestinationId)
      .get();

  // Get current timestamp
  Timestamp now = Timestamp.now();
  double timeScore = calculateTimeBasedScore(now);

  if (existingInteraction.docs.isNotEmpty) {
    await refreshAllUserInteractions(
        userId, subdestinationId, tags, interactionType);
  } else {
    await FirebaseFirestore.instance.collection('interaction').add({
      'user_id': userId,
      'destination_id': subdestinationId,
      'preference_score': timeScore,
      'interaction_type': interactionType, 
      'tags': tags,
      'timestamp': now,
    }).then((value) {
      devtools.log(
          'Created new interaction for user $userId with sub-destination $subdestinationId, time score: $timeScore');
    }).catchError((error) {
      devtools.log('Failed to create interaction: $error');
    });
    await refreshAllUserInteractions(
        userId, subdestinationId, tags, interactionType);
  }
}

Future<void> refreshAllUserInteractions(
    String userId,
    String clickedSubdestinationId,
    List<String> clickedTags,
    String interactionType) async {
  QuerySnapshot allInteractionsSnapshot = await FirebaseFirestore.instance
      .collection('interaction')
      .where('user_id', isEqualTo: userId)
      .get();

  Timestamp now = Timestamp.now();
  double timeScore = calculateTimeBasedScore(now);

  // Refresh inteeractions
  for (var doc in allInteractionsSnapshot.docs) {
    var interactionData = doc.data() as Map<String, dynamic>;
    String interactionDocId = doc.id;
    String subdestinationId = interactionData['destination_id'];
    Timestamp lastInteractionTime = interactionData['timestamp'];
    double lastScore = interactionData['preference_score'];

    // Calculate time decay
    double timeDecay = calculateTimeBasedScore(lastInteractionTime);
    double newScore = lastScore * timeDecay;

    if (subdestinationId == clickedSubdestinationId) {
      newScore += timeScore;

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
        newScore = 0; 
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

  double score = 1 / (1 + timeDifference);

  if (score < 0) {
    score = 0;
  }

  return score;
}
