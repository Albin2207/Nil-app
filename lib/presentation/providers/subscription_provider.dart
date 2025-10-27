import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/subscription_model.dart';
import '../../core/services/notification_topics_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<SubscriptionModel> _subscriptions = [];
  Set<String> _subscribedChannelIds = {};
  
  List<SubscriptionModel> get subscriptions => _subscriptions;
  Set<String> get subscribedChannelIds => _subscribedChannelIds;

  // Check if user is subscribed to a channel
  bool isSubscribed(String channelId) {
    return _subscribedChannelIds.contains(channelId);
  }

  // Load user's subscriptions
  Future<void> loadSubscriptions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get();

      _subscriptions = snapshot.docs
          .map((doc) => SubscriptionModel.fromFirestore(doc))
          .toList();

      _subscribedChannelIds = _subscriptions.map((s) => s.channelId).toSet();
      
      notifyListeners();
    } catch (e) {
      print('Error loading subscriptions: $e');
    }
  }

  // Stream user's subscriptions
  Stream<List<SubscriptionModel>> getSubscriptionsStream(String userId) {
    return _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .orderBy('subscribedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      _subscriptions = snapshot.docs
          .map((doc) => SubscriptionModel.fromFirestore(doc))
          .toList();
      
      _subscribedChannelIds = _subscriptions.map((s) => s.channelId).toSet();
      
      return _subscriptions;
    });
  }

  // Subscribe to a channel
  Future<bool> subscribe({
    required String userId,
    required String channelId,
    required String channelName,
    required String channelAvatar,
  }) async {
    try {
      print('🔔 Subscribe attempt - userId: $userId, channelId: $channelId');
      
      // Check if already subscribed
      final existing = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('channelId', isEqualTo: channelId)
          .get();

      if (existing.docs.isNotEmpty) {
        print('⚠️ Already subscribed');
        return true; // Already subscribed - treat as success
      }

      print('✅ Creating subscription...');
      // Add subscription
      await _firestore.collection('subscriptions').add({
        'userId': userId,
        'channelId': channelId,
        'channelName': channelName,
        'channelAvatar': channelAvatar,
        'subscribedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Incrementing subscriber count...');
      // Increment subscriber count for the channel
      await _firestore.collection('users').doc(channelId).update({
        'subscribersCount': FieldValue.increment(1),
      });

      _subscribedChannelIds.add(channelId);
      notifyListeners();
      
      // Subscribe to channel notifications
      await NotificationTopicsService().subscribeToChannelTopics(channelId);
      
      print('✅ Subscribe success!');
      return true;
    } catch (e) {
      print('❌ Error subscribing: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Unsubscribe from a channel
  Future<bool> unsubscribe({
    required String userId,
    required String channelId,
  }) async {
    try {
      print('🔕 Unsubscribe attempt - userId: $userId, channelId: $channelId');
      
      // Find subscription
      final snapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('channelId', isEqualTo: channelId)
          .get();

      if (snapshot.docs.isEmpty) {
        print('⚠️ Not subscribed');
        return true; // Not subscribed - treat as success
      }

      print('✅ Deleting subscription...');
      // Delete subscription
      await snapshot.docs.first.reference.delete();

      print('✅ Decrementing subscriber count...');
      // Decrement subscriber count for the channel
      final channelDoc = await _firestore.collection('users').doc(channelId).get();
      final currentCount = (channelDoc.data()?['subscribersCount'] ?? 0) as int;
      
      if (currentCount > 0) {
        await _firestore.collection('users').doc(channelId).update({
          'subscribersCount': FieldValue.increment(-1),
        });
      }

      _subscribedChannelIds.remove(channelId);
      _subscriptions.removeWhere((s) => s.channelId == channelId);
      notifyListeners();
      
      // Unsubscribe from channel notifications
      await NotificationTopicsService().unsubscribeFromChannelTopics(channelId);
      
      print('✅ Unsubscribe success!');
      return true;
    } catch (e) {
      print('❌ Error unsubscribing: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Get subscriber count for a channel
  Future<int> getSubscriberCount(String channelId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(channelId).get();
      return (userDoc.data()?['subscribersCount'] ?? 0) as int;
    } catch (e) {
      print('Error getting subscriber count: $e');
      return 0;
    }
  }

  // Stream subscriber count for a channel
  Stream<int> getSubscriberCountStream(String channelId) {
    return _firestore
        .collection('users')
        .doc(channelId)
        .snapshots()
        .map((snapshot) => (snapshot.data()?['subscribersCount'] ?? 0) as int);
  }
}


