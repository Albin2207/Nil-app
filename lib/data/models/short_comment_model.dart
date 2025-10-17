import 'package:cloud_firestore/cloud_firestore.dart';

class ShortComment {
  final String id;
  final String shortId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String text;
  final DateTime timestamp;
  final int likes;
  final int dislikes;
  final String? parentId; // For nested replies

  ShortComment({
    required this.id,
    required this.shortId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.timestamp,
    this.likes = 0,
    this.dislikes = 0,
    this.parentId,
  });

  factory ShortComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShortComment(
      id: doc.id,
      shortId: data['shortId'] ?? '',
      userId: data['userId'] ?? 'anonymous',
      userName: data['userName'] ?? 'Anonymous User',
      userAvatar: data['userAvatar'] ?? 'https://i.pravatar.cc/150?img=1',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: data['likes'] ?? 0,
      dislikes: data['dislikes'] ?? 0,
      parentId: data['parentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shortId': shortId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'dislikes': dislikes,
      'parentId': parentId,
    };
  }
}

