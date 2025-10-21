import 'package:cloud_firestore/cloud_firestore.dart';

class ShortVideo {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String title;
  final String description;
  final String channelName;
  final String channelAvatar;
  final int views;
  final int likes;
  final int dislikes;
  final int commentsCount;
  final Timestamp timestamp;
  final String? uploadedBy;

  ShortVideo({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.title,
    required this.description,
    required this.channelName,
    required this.channelAvatar,
    required this.views,
    required this.likes,
    required this.dislikes,
    required this.commentsCount,
    required this.timestamp,
    this.uploadedBy,
  });

  factory ShortVideo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShortVideo(
      id: doc.id,
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      channelName: data['channelName'] ?? '',
      channelAvatar: data['channelAvatar'] ?? 'https://i.pravatar.cc/150?img=2',
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
      dislikes: data['dislikes'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      timestamp: data['timestamp'] ?? Timestamp.now(),
      uploadedBy: data['uploadedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'description': description,
      'channelName': channelName,
      'channelAvatar': channelAvatar,
      'views': views,
      'likes': likes,
      'dislikes': dislikes,
      'commentsCount': commentsCount,
      'timestamp': timestamp,
    };
  }
}


