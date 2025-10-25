import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/watch_later_model.dart';

class WatchLaterService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<bool> addToWatchLater({
    required String contentId,
    required String contentType,
    required String title,
    required String thumbnailUrl,
    required String channelName,
    required String channelAvatar,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      // Check if already saved
      final existingEntry = await _firestore
          .collection('watchLater')
          .where('userId', isEqualTo: userId)
          .where('contentId', isEqualTo: contentId)
          .limit(1)
          .get();

      if (existingEntry.docs.isEmpty) {
        // Add new entry
        final newEntry = WatchLaterModel(
          id: '', // Firestore will generate this
          userId: userId,
          contentId: contentId,
          contentType: contentType,
          title: title,
          thumbnailUrl: thumbnailUrl,
          channelName: channelName,
          channelAvatar: channelAvatar,
          savedAt: DateTime.now(),
        );
        await _firestore.collection('watchLater').add(newEntry.toMap());
        return true; // Successfully added
      }
      return false; // Already exists
    } catch (e) {
      debugPrint('Error adding to watch later: $e');
      return false;
    }
  }

  static Future<void> removeFromWatchLater(String contentId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final querySnapshot = await _firestore
          .collection('watchLater')
          .where('userId', isEqualTo: userId)
          .where('contentId', isEqualTo: contentId)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error removing from watch later: $e');
    }
  }

  static Future<bool> isInWatchLater(String contentId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final querySnapshot = await _firestore
          .collection('watchLater')
          .where('userId', isEqualTo: userId)
          .where('contentId', isEqualTo: contentId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking watch later status: $e');
      return false;
    }
  }

  static Stream<List<WatchLaterModel>> getWatchLaterStream(String userId) {
    return _firestore
        .collection('watchLater')
        .where('userId', isEqualTo: userId)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WatchLaterModel.fromFirestore(doc))
            .toList());
  }

  static Future<void> clearWatchLater(String userId) async {
    try {
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('watchLater')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing watch later: $e');
    }
  }
}
