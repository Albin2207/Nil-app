import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String type; // 'comment', 'video', 'short'
  final String reporterId; // User who reported
  final String? reportedUserId; // User who posted the comment (nullable for video/short reports)
  final String? commentId; // Only for comment reports
  final String? videoId; // Only for video reports
  final String contentId; // ID of the reported content (comment/video/short)
  final String? contentTitle; // Title of video/short
  final String? channelName; // Channel name for video/short reports
  final String reason;
  final String? commentText; // For comment context
  final Timestamp timestamp;
  final String status; // 'pending', 'reviewed', 'resolved', 'dismissed'

  ReportModel({
    required this.id,
    required this.type,
    required this.reporterId,
    this.reportedUserId,
    this.commentId,
    this.videoId,
    required this.contentId,
    this.contentTitle,
    this.channelName,
    required this.reason,
    this.commentText,
    required this.timestamp,
    this.status = 'pending',
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      type: data['type'] ?? 'comment', // Default to comment for backward compatibility
      reporterId: data['reporterId'] ?? '',
      reportedUserId: data['reportedUserId'],
      commentId: data['commentId'],
      videoId: data['videoId'],
      contentId: data['contentId'] ?? data['commentId'] ?? '',
      contentTitle: data['contentTitle'],
      channelName: data['channelName'],
      reason: data['reason'] ?? '',
      commentText: data['commentText'],
      timestamp: data['timestamp'] ?? Timestamp.now(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'reporterId': reporterId,
      if (reportedUserId != null) 'reportedUserId': reportedUserId,
      if (commentId != null) 'commentId': commentId,
      if (videoId != null) 'videoId': videoId,
      'contentId': contentId,
      if (contentTitle != null) 'contentTitle': contentTitle,
      if (channelName != null) 'channelName': channelName,
      'reason': reason,
      if (commentText != null) 'commentText': commentText,
      'timestamp': timestamp,
      'status': status,
    };
  }
}

