import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContentPreferencesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mark a video as "Not Interested"
  static Future<bool> markVideoNotInterested(String videoId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notInterested')
          .doc(videoId)
          .set({
        'videoId': videoId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error marking video as not interested: $e');
      return false;
    }
  }

  /// Mark a channel as "Don't Recommend"
  static Future<bool> dontRecommendChannel(String channelId, String channelName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('blockedChannels')
          .doc(channelId)
          .set({
        'channelId': channelId,
        'channelName': channelName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error blocking channel: $e');
      return false;
    }
  }

  /// Get list of not interested video IDs
  static Future<Set<String>> getNotInterestedVideos() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notInterested')
          .get();

      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      print('Error getting not interested videos: $e');
      return {};
    }
  }

  /// Get list of blocked channel IDs
  static Future<Set<String>> getBlockedChannels() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blockedChannels')
          .get();

      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      print('Error getting blocked channels: $e');
      return {};
    }
  }

  /// Remove video from not interested list
  static Future<bool> removeNotInterested(String videoId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notInterested')
          .doc(videoId)
          .delete();

      return true;
    } catch (e) {
      print('Error removing not interested: $e');
      return false;
    }
  }

  /// Unblock a channel
  static Future<bool> unblockChannel(String channelId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('blockedChannels')
          .doc(channelId)
          .delete();

      return true;
    } catch (e) {
      print('Error unblocking channel: $e');
      return false;
    }
  }

  /// Check if video is marked as not interested
  static Future<bool> isVideoNotInterested(String videoId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notInterested')
          .doc(videoId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Check if channel is blocked
  static Future<bool> isChannelBlocked(String channelId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blockedChannels')
          .doc(channelId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}

