import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImageCommentActionsMenu extends StatelessWidget {
  final String commentId;
  final String commentText;
  final String commentUserId;
  final String currentUserId;
  final String imagePostOwnerId;
  final String imagePostId;
  final bool isPinned;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onPin;

  const ImageCommentActionsMenu({
    super.key,
    required this.commentId,
    required this.commentText,
    required this.commentUserId,
    required this.currentUserId,
    required this.imagePostOwnerId,
    required this.imagePostId,
    this.isPinned = false,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.onPin,
  });

  bool get isOwnComment => commentUserId == currentUserId;
  bool get isImagePostOwner => currentUserId == imagePostOwnerId;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.grey[400],
        size: 20,
      ),
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.zero,
      itemBuilder: (context) => [
        // Copy comment
        PopupMenuItem<String>(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, size: 20, color: Colors.grey[300]),
              const SizedBox(width: 12),
              Text(
                'Copy text',
                style: TextStyle(color: Colors.grey[300]),
              ),
            ],
          ),
        ),

        // Edit (only for own comments)
        if (isOwnComment)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 20, color: Colors.grey[300]),
                const SizedBox(width: 12),
                Text(
                  'Edit',
                  style: TextStyle(color: Colors.grey[300]),
                ),
              ],
            ),
          ),

        // Pin/Unpin (only for image post owner)
        if (isImagePostOwner && onPin != null)
          PopupMenuItem<String>(
            value: 'pin',
            child: Row(
              children: [
                Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 20,
                  color: Colors.grey[300],
                ),
                const SizedBox(width: 12),
                Text(
                  isPinned ? 'Unpin' : 'Pin',
                  style: TextStyle(color: Colors.grey[300]),
                ),
              ],
            ),
          ),

        // Delete (for own comments or image post owner)
        if (isOwnComment || isImagePostOwner)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, size: 20, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  'Delete',
                  style: TextStyle(color: Colors.red[300]),
                ),
              ],
            ),
          ),

        // Report (for other people's comments)
        if (!isOwnComment)
          PopupMenuItem<String>(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag, size: 20, color: Colors.orange[300]),
                const SizedBox(width: 12),
                Text(
                  'Report',
                  style: TextStyle(color: Colors.orange[300]),
                ),
              ],
            ),
          ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'copy':
            Clipboard.setData(ClipboardData(text: commentText));
            // Find root scaffold messenger
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Comment copied',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 1500),
                backgroundColor: const Color(0xFF7B61FF),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.75,
                  left: 16,
                  right: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
            );
            break;
          case 'edit':
            if (onEdit != null) onEdit!();
            break;
          case 'pin':
            if (onPin != null) onPin!();
            break;
          case 'delete':
            if (onDelete != null) onDelete!();
            break;
          case 'report':
            if (onReport != null) onReport!();
            break;
        }
      },
    );
  }
}

