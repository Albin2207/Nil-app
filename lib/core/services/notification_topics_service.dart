import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationTopicsService {
  static final NotificationTopicsService _instance = NotificationTopicsService._internal();
  factory NotificationTopicsService() => _instance;
  NotificationTopicsService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Subscribe to general app topics
  Future<void> subscribeToGeneralTopics() async {
    try {
      // Subscribe to general topics
      await _messaging.subscribeToTopic('all_users');
      await _messaging.subscribeToTopic('new_videos');
      await _messaging.subscribeToTopic('new_shorts');
      await _messaging.subscribeToTopic('app_updates');
      
      debugPrint('📡 Subscribed to general topics');
    } catch (e) {
      debugPrint('❌ Error subscribing to general topics: $e');
    }
  }

  /// Subscribe to user-specific topics
  Future<void> subscribeToUserTopics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userId = user.uid;
      
      // Subscribe to user-specific topics
      await _messaging.subscribeToTopic('user_$userId');
      await _messaging.subscribeToTopic('user_notifications_$userId');
      
      // Save user's FCM token to Firestore for targeted notifications
      await _saveUserToken(userId);
      
      debugPrint('📡 Subscribed to user-specific topics for: $userId');
    } catch (e) {
      debugPrint('❌ Error subscribing to user topics: $e');
    }
  }

  /// Save user's FCM token to Firestore
  Future<void> _saveUserToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _firestore.collection('user_tokens').doc(userId).set({
        'userId': userId,
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
        'platform': 'web', // or 'android', 'ios'
      }, SetOptions(merge: true));

      debugPrint('💾 Saved FCM token for user: $userId');
    } catch (e) {
      debugPrint('❌ Error saving user token: $e');
    }
  }

  /// Subscribe to channel-specific topics (for subscribers)
  Future<void> subscribeToChannelTopics(String channelId) async {
    try {
      await _messaging.subscribeToTopic('channel_$channelId');
      debugPrint('📡 Subscribed to channel: $channelId');
    } catch (e) {
      debugPrint('❌ Error subscribing to channel: $e');
    }
  }

  /// Unsubscribe from channel topics
  Future<void> unsubscribeFromChannelTopics(String channelId) async {
    try {
      await _messaging.unsubscribeFromTopic('channel_$channelId');
      debugPrint('📡 Unsubscribed from channel: $channelId');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from channel: $e');
    }
  }

  /// Initialize all subscriptions
  Future<void> initializeSubscriptions() async {
    await subscribeToGeneralTopics();
    await subscribeToUserTopics();
  }

  /// Update token when it refreshes
  Future<void> handleTokenRefresh() async {
    _messaging.onTokenRefresh.listen((newToken) async {
      final user = _auth.currentUser;
      if (user != null) {
        await _saveUserToken(user.uid);
      }
    });
  }
}
