import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Report a comment
  Future<void> reportComment({
    required String reporterId,
    required String reportedUserId,
    required String commentId,
    required String videoId,
    required String reason,
    required String commentText,
  }) async {
    try {
      // Check if user already reported this comment
      final existingReport = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: reporterId)
          .where('commentId', isEqualTo: commentId)
          .limit(1)
          .get();

      if (existingReport.docs.isNotEmpty) {
        print('User already reported this comment');
        return; // Don't allow duplicate reports
      }

      // Create new report
      final report = ReportModel(
        id: '', // Will be auto-generated
        type: 'comment',
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        commentId: commentId,
        videoId: videoId,
        contentId: commentId,
        reason: reason,
        commentText: commentText,
        timestamp: Timestamp.now(),
        status: 'pending',
      );

      await _firestore.collection('reports').add(report.toMap());

      print('✅ Comment reported successfully');
    } catch (e) {
      print('❌ Error reporting comment: $e');
      rethrow;
    }
  }

  /// Get all reports (for admin/moderation purposes - future feature)
  Stream<List<ReportModel>> getReportsStream() {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList());
  }

  /// Update report status (for admin/moderation - future feature)
  Future<void> updateReportStatus(String reportId, String status) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': status,
      });
    } catch (e) {
      print('Error updating report status: $e');
      rethrow;
    }
  }

  /// Get report count for a specific comment
  Future<int> getCommentReportCount(String commentId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('commentId', isEqualTo: commentId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting report count: $e');
      return 0;
    }
  }
}

