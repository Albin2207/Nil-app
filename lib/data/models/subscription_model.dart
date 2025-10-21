import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String id;
  final String userId; // User who subscribed
  final String channelId; // Creator/channel being subscribed to
  final String channelName;
  final String channelAvatar;
  final Timestamp subscribedAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.channelId,
    required this.channelName,
    required this.channelAvatar,
    required this.subscribedAt,
  });

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      channelId: data['channelId'] ?? '',
      channelName: data['channelName'] ?? '',
      channelAvatar: data['channelAvatar'] ?? '',
      subscribedAt: data['subscribedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'channelId': channelId,
      'channelName': channelName,
      'channelAvatar': channelAvatar,
      'subscribedAt': subscribedAt,
    };
  }
}


