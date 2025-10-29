import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class ImageReportCommentDialog extends StatefulWidget {
  final String commentId;
  final Function(String reason) onReport;

  const ImageReportCommentDialog({
    super.key,
    required this.commentId,
    required this.onReport,
  });

  @override
  State<ImageReportCommentDialog> createState() => _ImageReportCommentDialogState();
}

class _ImageReportCommentDialogState extends State<ImageReportCommentDialog> {
  String? _selectedReason;

  final List<String> _reportReasons = [
    'Spam',
    'Harassment or bullying',
    'Hate speech',
    'Violence or dangerous content',
    'Nudity or sexual content',
    'False information',
    'Copyright violation',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Report Comment',
        style: TextStyle(
          color: AppConstants.textPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why are you reporting this comment?',
            style: TextStyle(
              color: AppConstants.textPrimaryColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ..._reportReasons.map((reason) => RadioListTile<String>(
            title: Text(
              reason,
              style: const TextStyle(
                color: AppConstants.textPrimaryColor,
                fontSize: 14,
              ),
            ),
            value: reason,
            groupValue: _selectedReason,
            onChanged: (value) {
              setState(() {
                _selectedReason = value;
              });
            },
            activeColor: AppConstants.primaryColor,
          )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedReason != null
              ? () {
                  widget.onReport(_selectedReason!);
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Report'),
        ),
      ],
    );
  }
}

