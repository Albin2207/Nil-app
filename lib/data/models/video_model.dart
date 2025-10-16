import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final String channelName;
  final String channelAvatar;
  final int duration;
  final int views;
  final int likes;
  final int dislikes;
  final int subscribers;
  final Timestamp timestamp;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.channelName,
    required this.channelAvatar,
    required this.duration,
    required this.views,
    required this.likes,
    required this.dislikes,
    required this.subscribers,
    required this.timestamp,
  });

  factory VideoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      channelName: data['channelName'] ?? '',
      channelAvatar: data['channelAvatar'] ?? '',
      duration: data['duration'] ?? 0,
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
      dislikes: data['dislikes'] ?? 0,
      subscribers: data['subscribers'] ?? 0,
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'channelName': channelName,
      'channelAvatar': channelAvatar,
      'duration': duration,
      'views': views,
      'likes': likes,
      'dislikes': dislikes,
      'subscribers': subscribers,
      'timestamp': timestamp,
    };
  }
}

