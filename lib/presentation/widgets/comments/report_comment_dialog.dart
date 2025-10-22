import 'package:flutter/material.dart';

class ReportCommentDialog extends StatefulWidget {
  final String commentId;
  final Function(String reason) onReport;

  const ReportCommentDialog({
    super.key,
    required this.commentId,
    required this.onReport,
  });

  @override
  State<ReportCommentDialog> createState() => _ReportCommentDialogState();
}

class _ReportCommentDialogState extends State<ReportCommentDialog> {
  String? _selectedReason;
  
  final List<Map<String, dynamic>> _reasons = [
    {'value': 'spam', 'label': 'Spam or misleading', 'icon': Icons.error_outline},
    {'value': 'harassment', 'label': 'Harassment or bullying', 'icon': Icons.person_off},
    {'value': 'hate', 'label': 'Hate speech', 'icon': Icons.report},
    {'value': 'violence', 'label': 'Violence or threats', 'icon': Icons.dangerous},
    {'value': 'inappropriate', 'label': 'Inappropriate content', 'icon': Icons.block},
    {'value': 'other', 'label': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.flag, color: Colors.orange[300], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Report Comment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Help us understand what\'s wrong',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 20),

            // Reasons list
            ..._reasons.map((reason) => RadioListTile<String>(
                  value: reason['value'],
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value;
                    });
                  },
                  title: Row(
                    children: [
                      Icon(
                        reason['icon'],
                        size: 20,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 12),
                      Text(
                        reason['label'],
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                  activeColor: Colors.orange[300],
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),

            const SizedBox(height: 20),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedReason == null
                      ? null
                      : () {
                          widget.onReport(_selectedReason!);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thank you for reporting. We\'ll review this comment.'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Colors.black87,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

