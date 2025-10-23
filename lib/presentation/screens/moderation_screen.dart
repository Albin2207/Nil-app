import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/report_model.dart';
import '../../data/models/comment_model.dart';
import '../../data/models/user_model.dart';

class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  String _selectedFilter = 'all'; // all, pending, resolved

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
                _buildFilterChip('Pending', 'pending'),
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
    Query query = FirebaseFirestore.instance
        .collection('reports')
        .where('contentOwnerId', isEqualTo: currentUserId)
        .orderBy('reportedAt', descending: true);

    if (_selectedFilter == 'pending') {
      query = query.where('status', isEqualTo: 'pending');
    } else if (_selectedFilter == 'resolved') {
      query = query.where('status', isEqualTo: 'resolved');
    }

    return query.snapshots();
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

            // Comment Details
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('comments')
                  .doc(report.commentId)
                  .get(),
              builder: (context, commentSnapshot) {
                if (!commentSnapshot.hasData) {
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

            // Action buttons (only if pending)
            if (report.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _dismissReport(reportId),
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
                      onPressed: () => _deleteComment(reportId, report.commentId),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete Comment'),
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

  Future<void> _dismissReport(String reportId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'action': 'dismissed',
      });

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Report dismissed');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Failed to dismiss report: $e');
      }
    }
  }

  Future<void> _deleteComment(String reportId, String commentId) async {
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
      // Delete the comment
      await FirebaseFirestore.instance
          .collection('comments')
          .doc(commentId)
          .delete();

      // Update report status
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
        'action': 'comment_deleted',
      });

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Comment deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Failed to delete comment: $e');
      }
    }
  }
}

