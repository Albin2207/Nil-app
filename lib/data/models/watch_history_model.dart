import 'package:cloud_firestore/cloud_firestore.dart';

class WatchHistoryModel {
  final String id;
  final String userId;
  final String contentId;
  final String contentType; // 'video' or 'short'
  final String title;
  final String thumbnailUrl;
  final String channelName;
  final String channelAvatar;
  final DateTime watchedAt;
  final Duration watchDuration; // How long they watched
  final Duration totalDuration; // Total video/short duration

  WatchHistoryModel({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.contentType,
    required this.title,
    required this.thumbnailUrl,
    required this.channelName,
    required this.channelAvatar,
    required this.watchedAt,
    required this.watchDuration,
    required this.totalDuration,
  });

  factory WatchHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WatchHistoryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      contentId: data['contentId'] ?? '',
      contentType: data['contentType'] ?? '',
      title: data['title'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      channelName: data['channelName'] ?? '',
      channelAvatar: data['channelAvatar'] ?? '',
      watchedAt: (data['watchedAt'] as Timestamp).toDate(),
      watchDuration: Duration(milliseconds: data['watchDurationMs'] ?? 0),
      totalDuration: Duration(milliseconds: data['totalDurationMs'] ?? 0),
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
      'watchedAt': Timestamp.fromDate(watchedAt),
      'watchDurationMs': watchDuration.inMilliseconds,
      'totalDurationMs': totalDuration.inMilliseconds,
    };
  }

  double get watchProgress {
    if (totalDuration.inMilliseconds == 0) return 0.0;
    return (watchDuration.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  String get formattedWatchTime {
    final hours = watchDuration.inHours;
    final minutes = watchDuration.inMinutes % 60;
    final seconds = watchDuration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get formattedTotalTime {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;
    final seconds = totalDuration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
