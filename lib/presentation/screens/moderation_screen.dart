import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/report_model.dart';
import '../../data/models/comment_model.dart';

class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  String _selectedFilter = 'all'; // all, resolved

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Moderation'),
          backgroundColor: Colors.black,
        ),
        body: const Center(child: Text('Please log in to access moderation')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Moderation', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
            ),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Resolved', 'resolved'),
              ],
            ),
          ),

          // Reports List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getReportsStream(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF7B61FF)));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading reports',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  );
                }

                final reports = snapshot.data?.docs ?? [];

                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'all' 
                              ? 'No reports yet'
                              : 'No $_selectedFilter reports',
                          style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Comments reported on your content will appear here',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final reportDoc = reports[index];
                    final report = ReportModel.fromFirestore(reportDoc);
                    return _buildReportCard(report, reportDoc.id, currentUserId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[850],
      selectedColor: const Color(0xFF7B61FF).withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[400],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF7B61FF) : Colors.grey[700]!,
      ),
    );
  }

  Stream<QuerySnapshot> _getReportsStream(String currentUserId) {
    if (_selectedFilter == 'resolved') {
      return FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'resolved')
          .snapshots();
    } else {
      // 'all' - show only pending/unresolved
      return FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .snapshots();
    }
  }

  Widget _buildReportCard(ReportModel report, String reportId, String currentUserId) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: report.status == 'pending' ? Colors.orange : Colors.grey[800]!,
          width: report.status == 'pending' ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Reporter info & status
            Row(
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(report.reporterId)
                      .get(),
                  builder: (context, snapshot) {
                    String reporterName = 'Loading...';
                    if (snapshot.hasData && snapshot.data != null) {
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      reporterName = data?['username'] ?? 'Unknown User';
                    }
                    return Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.flag, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Reported by $reporterName',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[400],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: report.status == 'pending'
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: report.status == 'pending' ? Colors.orange : Colors.green,
                    ),
                  ),
                  child: Text(
                    report.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: report.status == 'pending' ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Reason
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reason: ${report.reason}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Content Details (different for each type)
            if (report.type == 'video' || report.type == 'short')
              // Video/Short Report
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          report.type == 'video' ? Icons.videocam : Icons.video_library,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            report.contentTitle ?? 'Untitled ${report.type}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (report.channelName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 6),
                          Text(
                            'Channel: ${report.channelName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Content ID: ${report.contentId}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              // Comment Report
              FutureBuilder<DocumentSnapshot>(
                future: report.videoId != null && report.commentId != null
                    ? FirebaseFirestore.instance
                        .collection('videos')
                        .doc(report.videoId)
                        .collection('comments')
                        .doc(report.commentId)
                        .get()
                    // ignore: null_argument_to_non_null_type
                    : Future.value(null),
                builder: (context, commentSnapshot) {
                  if (!commentSnapshot.hasData || commentSnapshot.data == null) {
                    return const Text(
                      'Loading comment...',
                      style: TextStyle(color: Colors.grey),
                    );
                  }

                  if (!commentSnapshot.data!.exists) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.grey[600], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Comment has been deleted',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final comment = CommentModel.fromFirestore(commentSnapshot.data!);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Comment author
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(comment.userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        String userName = 'Loading...';
                        if (userSnapshot.hasData && userSnapshot.data != null) {
                          final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                          userName = data?['username'] ?? 'Unknown';
                        }
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF7B61FF),
                              child: Text(
                                userName[0].toUpperCase(),
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimestamp(comment.timestamp),
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Comment text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        comment.text,
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),

            // View Content Button
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _viewReportedContent(report),
                icon: const Icon(Icons.play_circle_filled, size: 24),
                label: Text(
                  'View ${report.type == 'comment' ? 'Comment' : report.type == 'video' ? 'Video' : 'Short'}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            // Action buttons
            const SizedBox(height: 12),
            if (report.status == 'resolved')
              // Resolved indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Report Resolved',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              // Action buttons for pending reports
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteReport(reportId),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Dismiss'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[400],
                        side: BorderSide(color: Colors.grey[700]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (report.type == 'comment' && report.commentId != null) {
                          _deleteComment(reportId, report.commentId!, report.videoId);
                        } else if (report.type == 'video') {
                          _deleteVideo(reportId, report.contentId);
                        } else if (report.type == 'short') {
                          _deleteShort(reportId, report.contentId);
                        }
                      },
                      icon: const Icon(Icons.delete, size: 18),
                      label: Text('Delete ${report.type == 'comment' ? 'Comment' : report.type[0].toUpperCase()}${report.type.substring(1)}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }


  void _viewReportedContent(ReportModel report) {
    if (report.type == 'video') {
      // Show video details
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Reported Video', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Title: ${report.contentTitle ?? 'Unknown'}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Channel: ${report.channelName ?? 'Unknown'}',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              Text(
                'Video ID: ${report.contentId}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else if (report.type == 'short') {
      // Show short details
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Reported Short', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Title: ${report.contentTitle ?? 'Unknown'}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Channel: ${report.channelName ?? 'Unknown'}',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              Text(
                'Short ID: ${report.contentId}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      // Comment - show in a dialog
      SnackBarHelper.showInfo(context, 'Comment content is shown above', icon: Icons.info);
    }
  }

  Future<void> _deleteReport(String reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Report', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to permanently delete this report?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .delete();

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Report deleted', icon: Icons.delete);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Failed to delete report: $e');
      }
    }
  }

  Future<void> _deleteVideo(String reportId, String videoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Video', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this video? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get video to find uploader
      final videoDoc = await FirebaseFirestore.instance
          .collection('videos')
          .doc(videoId)
          .get();
      
      final uploaderId = videoDoc.data()?['uploadedBy'];
      
      // Delete the video from Firestore
      await FirebaseFirestore.instance
          .collection('videos')
          .doc(videoId)
          .delete();

      // Update uploader's video count
      if (uploaderId != null) {
        print('🔄 Decrementing video count for user: $uploaderId');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uploaderId)
            .update({
          'uploadedVideosCount': FieldValue.increment(-1),
        });
        print('✅ Video count decremented');
      } else {
        print('⚠️ No uploader ID found, cannot decrement count');
      }

      // Mark report as resolved
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'action': 'content_deleted',
      });

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Video deleted and report resolved', icon: Icons.check);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Failed to delete video: $e');
      }
    }
  }

  Future<void> _deleteShort(String reportId, String shortId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Short', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this short? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get short to find uploader
      final shortDoc = await FirebaseFirestore.instance
          .collection('shorts')
          .doc(shortId)
          .get();
      
      final uploaderId = shortDoc.data()?['uploadedBy'];
      
      // Delete the short from Firestore
      await FirebaseFirestore.instance
          .collection('shorts')
          .doc(shortId)
          .delete();

      // Update uploader's shorts count
      if (uploaderId != null) {
        print('🔄 Decrementing shorts count for user: $uploaderId');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uploaderId)
            .update({
          'uploadedShortsCount': FieldValue.increment(-1),
        });
        print('✅ Shorts count decremented');
      } else {
        print('⚠️ No uploader ID found, cannot decrement shorts count');
      }

      // Mark report as resolved
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'action': 'content_deleted',
      });

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Short deleted and report resolved', icon: Icons.check);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Failed to delete short: $e');
      }
    }
  }

  Future<void> _deleteComment(String reportId, String commentId, [String? videoId]) async {
    // Get videoId from the report if not provided
    if (videoId == null) {
      final reportDoc = await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .get();
      videoId = reportDoc.data()?['videoId'];
      
      if (videoId == null) {
        SnackBarHelper.showError(context, 'Cannot find video ID');
        return;
      }
    }
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Comment', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Delete the comment from the video's comments subcollection
      await FirebaseFirestore.instance
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Mark report as resolved
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'action': 'content_deleted',
      });

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Comment deleted and report resolved', icon: Icons.check);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Failed to delete comment: $e');
      }
    }
  }
}


