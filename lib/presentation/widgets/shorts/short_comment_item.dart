import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/short_comment_model.dart';
import '../../../core/utils/format_helper.dart';
import '../../../core/utils/comment_utils.dart';
import '../../../core/services/report_service.dart';
import '../../providers/shorts_provider_new.dart';
import '../../providers/auth_provider.dart';
import '../comments/comment_actions_menu.dart';
import '../comments/report_comment_dialog.dart';
import '../comments/edit_comment_dialog.dart';

class ShortCommentItem extends StatefulWidget {
  final ShortComment comment;
  final String shortId;
  final String videoOwnerId;
  final VoidCallback onReply;
  final VoidCallback? onDelete;
  final List<ShortComment> replies;

  const ShortCommentItem({
    super.key,
    required this.comment,
    required this.shortId,
    required this.videoOwnerId,
    required this.onReply,
    this.onDelete,
    required this.replies,
  });

  @override
  State<ShortCommentItem> createState() => _ShortCommentItemState();
}

class _ShortCommentItemState extends State<ShortCommentItem> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentContent(context),
        if (widget.replies.isNotEmpty) _buildReplies(context),
      ],
    );
  }

  Widget _buildCommentContent(BuildContext context) {
    final provider = context.watch<ShortsProviderNew>();
    final authProvider = context.watch<AuthProvider>();
    final isLiked = provider.isCommentLiked(widget.shortId, widget.comment.id);
    final isDisliked = provider.isCommentDisliked(
      widget.shortId,
      widget.comment.id,
    );
    final currentUserId = authProvider.firebaseUser?.uid ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(widget.comment.userAvatar),
            backgroundColor: Colors.grey[700],
          ),
          const SizedBox(width: 12),

          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username & timestamp & menu
                Row(
                  children: [
                    Text(
                      widget.comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CommentUtils.formatTimestamp(widget.comment.timestamp),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    // 3-dot menu
                    CommentActionsMenu(
                      commentId: widget.comment.id,
                      commentText: widget.comment.text,
                      commentUserId: widget.comment.userId,
                      currentUserId: currentUserId,
                      videoOwnerId: widget.videoOwnerId,
                      videoId: widget.shortId,
                      isPinned: false,
                      onEdit: () {
                        showDialog(
                          context: context,
                          builder: (context) => EditCommentDialog(
                            commentId: widget.comment.id,
                            videoId: widget.shortId,
                            initialText: widget.comment.text,
                            isShort: true,
                          ),
                        );
                      },
                      onDelete: () async {
                        FocusManager.instance.primaryFocus?.unfocus();
                        await Future.delayed(const Duration(milliseconds: 100));
                        if (context.mounted) {
                          _showDeleteDialog(context);
                        }
                      },
                      onReport: () {
                        showDialog(
                          context: context,
                          builder: (context) => ReportCommentDialog(
                            commentId: widget.comment.id,
                            onReport: (reason) async {
                              try {
                                await ReportService().reportComment(
                                  reporterId: currentUserId,
                                  reportedUserId: widget.comment.userId,
                                  commentId: widget.comment.id,
                                  videoId: widget.shortId,
                                  reason: reason,
                                  commentText: widget.comment.text,
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error submitting report: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Comment text
                Text(
                  widget.comment.text,
                  style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                ),
                const SizedBox(height: 6),

                // Action buttons
                Row(
                  children: [
                    // Like
                    InkWell(
                      onTap: () => provider.toggleCommentLike(
                        widget.shortId,
                        widget.comment.id,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            size: 16,
                            color: isLiked
                                ? const Color(0xFF7B61FF)
                                : Colors.grey[500],
                          ),
                          if (widget.comment.likes > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              FormatHelper.formatCount(widget.comment.likes),
                              style: TextStyle(
                                fontSize: 12,
                                color: isLiked
                                    ? const Color(0xFF7B61FF)
                                    : Colors.grey[500],
                                fontWeight: isLiked
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Dislike
                    InkWell(
                      onTap: () => provider.toggleCommentDislike(
                        widget.shortId,
                        widget.comment.id,
                      ),
                      child: Icon(
                        isDisliked
                            ? Icons.thumb_down
                            : Icons.thumb_down_outlined,
                        size: 16,
                        color: isDisliked
                            ? const Color(0xFF7B61FF)
                            : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Reply
                    InkWell(
                      onTap: widget.onReply,
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[400],
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
        children: widget.replies.map((reply) {
          return ShortCommentItem(
            key: ValueKey(reply.id),
            comment: reply,
            shortId: widget.shortId,
            videoOwnerId: widget.videoOwnerId,
            onReply: () {}, // Simple flat system - no nested replies
            onDelete: widget.onDelete,
            replies: const [], // Keep it flat
          );
        }).toList(),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    CommentUtils.showDeleteDialog(
      context: context,
      onConfirm: () {
        if (widget.onDelete != null) {
          widget.onDelete!();
        }
      },
    );
  }
}
