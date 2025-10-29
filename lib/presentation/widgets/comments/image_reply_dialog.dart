import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/image_comment_provider.dart';
import '../../providers/auth_provider.dart';

class ImageReplyDialog extends StatefulWidget {
  final String imagePostId;
  final String parentId;
  final String username;

  const ImageReplyDialog({
    super.key,
    required this.imagePostId,
    required this.parentId,
    required this.username,
  });

  @override
  State<ImageReplyDialog> createState() => _ImageReplyDialogState();
}

class _ImageReplyDialogState extends State<ImageReplyDialog> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _submitReply() {
    if (_replyController.text.trim().isEmpty) return;

    final imageCommentProvider = context.read<ImageCommentProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.firebaseUser;
    
    // Use Firebase Auth data directly (always available)
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Anonymous User';
    final userAvatar = user?.photoURL ?? 'https://ui-avatars.com/api/?name=$userName&background=random';
    
    imageCommentProvider.postComment(
      imagePostId: widget.imagePostId,
      text: _replyController.text,
      parentId: widget.parentId,
      userId: user?.uid,
      userName: userName,
      userAvatar: userAvatar,
      replyToUsername: widget.username, // Add reply context
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

