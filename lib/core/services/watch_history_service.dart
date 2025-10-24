import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/watch_history_model.dart';

class WatchHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> addToWatchHistory({
    required String contentId,
    required String contentType,
    required String title,
    required String thumbnailUrl,
    required String channelName,
    required String channelAvatar,
    required Duration watchDuration,
    required Duration totalDuration,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Check if already exists
      final existingQuery = await _firestore
          .collection('watchHistory')
          .where('userId', isEqualTo: userId)
          .where('contentId', isEqualTo: contentId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        // Update existing entry
        final docId = existingQuery.docs.first.id;
        await _firestore.collection('watchHistory').doc(docId).update({
          'watchDurationMs': watchDuration.inMilliseconds,
          'totalDurationMs': totalDuration.inMilliseconds,
          'watchedAt': Timestamp.now(),
        });
      } else {
        // Add new entry
        final newEntry = WatchHistoryModel(
          id: '', // Firestore will generate this
          userId: userId,
          contentId: contentId,
          contentType: contentType,
          title: title,
          thumbnailUrl: thumbnailUrl,
          channelName: channelName,
          channelAvatar: channelAvatar,
          watchedAt: DateTime.now(),
          watchDuration: watchDuration,
          totalDuration: totalDuration,
        );
        await _firestore.collection('watchHistory').add(newEntry.toMap());
      }
    } catch (e) {
      debugPrint('Error adding to watch history: $e');
    }
  }

  static Future<void> updateWatchProgress({
    required String contentId,
    required Duration watchDuration,
    required Duration totalDuration,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final existingQuery = await _firestore
          .collection('watchHistory')
          .where('userId', isEqualTo: userId)
          .where('contentId', isEqualTo: contentId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        final docId = existingQuery.docs.first.id;
        await _firestore.collection('watchHistory').doc(docId).update({
          'watchDurationMs': watchDuration.inMilliseconds,
          'totalDurationMs': totalDuration.inMilliseconds,
          'watchedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      debugPrint('Error updating watch progress: $e');
    }
  }

  static Stream<List<WatchHistoryModel>> getWatchHistoryStream(String userId) {
    return _firestore
        .collection('watchHistory')
        .where('userId', isEqualTo: userId)
        .orderBy('watchedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WatchHistoryModel.fromFirestore(doc))
            .toList());
  }

  static Future<void> clearWatchHistory(String userId) async {
    try {
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('watchHistory')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing watch history: $e');
      rethrow;
    }
  }
}
