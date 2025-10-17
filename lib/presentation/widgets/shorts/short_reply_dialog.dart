import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/short_comment_model.dart';
import '../../providers/shorts_provider_new.dart';
import '../../providers/auth_provider.dart';

class ShortReplyDialog extends StatefulWidget {
  final String shortId;
  final ShortComment parentComment;

  const ShortReplyDialog({
    super.key,
    required this.shortId,
    required this.parentComment,
  });

  @override
  State<ShortReplyDialog> createState() => _ShortReplyDialogState();
}

class _ShortReplyDialogState extends State<ShortReplyDialog> {
  final TextEditingController _replyController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _postReply() async {
    if (_replyController.text.trim().isEmpty || _isPosting) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.firebaseUser;
      
      // Use Firebase Auth data directly (always available)
      final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Anonymous User';
      final userAvatar = user?.photoURL ?? 'https://ui-avatars.com/api/?name=$userName&background=random';
      
      await context.read<ShortsProviderNew>().postComment(
            shortId: widget.shortId,
            text: _replyController.text.trim(),
            parentId: widget.parentComment.id,
            userId: user?.uid,
            userName: userName,
            userAvatar: userAvatar,
          );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post reply: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text(
        'Reply to comment',
        style: TextStyle(color: Colors.black, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Original comment
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(widget.parentComment.userAvatar),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.parentComment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.parentComment.text,
                  style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Reply input
          TextField(
            controller: _replyController,
            autofocus: true,
            maxLines: 4,
            minLines: 3,
            style: const TextStyle(color: Colors.black),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _postReply(),
            decoration: InputDecoration(
              hintText: 'Write your reply...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isPosting ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
        ElevatedButton(
          onPressed: _isPosting ? null : _postReply,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isPosting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Reply'),
        ),
      ],
    );
  }
}

