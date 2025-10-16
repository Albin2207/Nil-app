import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/comment_provider.dart';

class ReplyDialog extends StatefulWidget {
  final String videoId;
  final String parentId;
  final String username;

  const ReplyDialog({
    super.key,
    required this.videoId,
    required this.parentId,
    required this.username,
  });

  @override
  State<ReplyDialog> createState() => _ReplyDialogState();
}

class _ReplyDialogState extends State<ReplyDialog> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _submitReply() {
    if (_replyController.text.trim().isEmpty) return;

    final provider = context.read<CommentProvider>();
    provider.postComment(
      videoId: widget.videoId,
      text: _replyController.text,
      parentId: widget.parentId,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        'Reply to ${widget.username}',
        style: const TextStyle(
          color: AppConstants.textPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: TextField(
        controller: _replyController,
        autofocus: true,
        maxLines: 3,
        style: const TextStyle(color: AppConstants.textPrimaryColor),
        decoration: InputDecoration(
          hintText: 'Write a reply...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppConstants.primaryColor, width: 2),
          ),
        ),
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
          onPressed: _submitReply,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Reply'),
        ),
      ],
    );
  }
}

