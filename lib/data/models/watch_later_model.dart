import 'package:cloud_firestore/cloud_firestore.dart';

class WatchLaterModel {
  final String id;
  final String userId;
  final String contentId;
  final String contentType; // 'video' or 'short'
  final String title;
  final String thumbnailUrl;
  final String channelName;
  final String channelAvatar;
  final DateTime savedAt;

  WatchLaterModel({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.contentType,
    required this.title,
    required this.thumbnailUrl,
    required this.channelName,
    required this.channelAvatar,
    required this.savedAt,
  });

  factory WatchLaterModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WatchLaterModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      contentId: data['contentId'] ?? '',
      contentType: data['contentType'] ?? '',
      title: data['title'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      channelName: data['channelName'] ?? '',
      channelAvatar: data['channelAvatar'] ?? '',
      savedAt: (data['savedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'contentId': contentId,
      'contentType': contentType,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'channelName': channelName,
      'channelAvatar': channelAvatar,
      'savedAt': Timestamp.fromDate(savedAt),
    };
  }
}
