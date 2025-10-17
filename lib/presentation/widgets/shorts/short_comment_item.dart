import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/short_comment_model.dart';
import '../../../core/utils/format_helper.dart';
import '../../providers/shorts_provider_new.dart';

class ShortCommentItem extends StatelessWidget {
  final ShortComment comment;
  final String shortId;
  final VoidCallback onReply;
  final VoidCallback? onDelete;
  final List<ShortComment> replies;

  const ShortCommentItem({
    super.key,
    required this.comment,
    required this.shortId,
    required this.onReply,
    this.onDelete,
    required this.replies,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentContent(context),
        if (replies.isNotEmpty) _buildReplies(context),
      ],
    );
  }

  Widget _buildCommentContent(BuildContext context) {
    final provider = context.watch<ShortsProviderNew>();
    final isLiked = provider.isCommentLiked(shortId, comment.id);
    final isDisliked = provider.isCommentDisliked(shortId, comment.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(comment.userAvatar),
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(width: 12),
          
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username & timestamp
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(comment.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    if (onDelete != null)
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red.withValues(alpha: 0.7),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          // Ensure keyboard is dismissed
                          FocusManager.instance.primaryFocus?.unfocus();
                          FocusScope.of(context).unfocus();
                          // Small delay to ensure focus is cleared
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (context.mounted) {
                            _showDeleteDialog(context);
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Comment text
                Text(
                  comment.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                
                // Action buttons (like, dislike, reply)
                Row(
                  children: [
                    // Like button
                    InkWell(
                      onTap: () => provider.toggleCommentLike(shortId, comment.id),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            size: 16,
                            color: isLiked ? Colors.blue : Colors.grey[700],
                          ),
                          if (comment.likes > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              FormatHelper.formatCount(comment.likes),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Dislike button
                    InkWell(
                      onTap: () => provider.toggleCommentDislike(shortId, comment.id),
                      child: Icon(
                        isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                        size: 16,
                        color: isDisliked ? Colors.blue : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Reply button
                    InkWell(
                      onTap: onReply,
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplies(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48.0),
      child: Column(
        children: replies.map((reply) {
          return ShortCommentItem(
            key: ValueKey(reply.id),
            comment: reply,
            shortId: shortId,
            onReply: () {}, // Replies to replies can be added if needed
            onDelete: onDelete, // This will be set from parent with the correct reply ID
            replies: const [], // No nested replies for replies (1 level deep)
          );
        }).toList(),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return WillPopScope(
          onWillPop: () async {
            FocusManager.instance.primaryFocus?.unfocus();
            return true;
          },
          child: AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Delete comment?',
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
            content: const Text(
              'Are you sure you want to delete this comment? This action cannot be undone.',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (onDelete != null) {
                    onDelete!();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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
}

