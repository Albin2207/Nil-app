import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reporterId; // User who reported
  final String reportedUserId; // User who posted the comment
  final String commentId;
  final String videoId;
  final String reason;
  final String commentText; // For context
  final Timestamp timestamp;
  final String status; // 'pending', 'reviewed', 'resolved', 'dismissed'

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.commentId,
    required this.videoId,
    required this.reason,
    required this.commentText,
    required this.timestamp,
    this.status = 'pending',
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reportedUserId: data['reportedUserId'] ?? '',
      commentId: data['commentId'] ?? '',
      videoId: data['videoId'] ?? '',
      reason: data['reason'] ?? '',
      commentText: data['commentText'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'commentId': commentId,
      'videoId': videoId,
      'reason': reason,
      'commentText': commentText,
      'timestamp': timestamp,
      'status': status,
    };
  }
}

