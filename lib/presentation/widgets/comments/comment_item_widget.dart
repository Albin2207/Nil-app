import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../data/models/comment_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/comment_provider.dart';

class CommentItemWidget extends StatelessWidget {
  final String videoId;
  final CommentModel comment;
  final bool isReply;
  final VoidCallback? onReplyTap;

  const CommentItemWidget({
    super.key,
    required this.videoId,
    required this.comment,
    this.isReply = false,
    this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CommentProvider>(
      builder: (context, provider, child) {
        final hasLiked = provider.isCommentLiked(comment.id);
        final hasDisliked = provider.isCommentDisliked(comment.id);

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isReply ? 8 : 16,
            vertical: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isReply ? 16 : 18,
                backgroundImage: NetworkImage(comment.userAvatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.username,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isReply ? 12 : 13,
                            color: AppConstants.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment.timestamp != null
                              ? timeago.format(comment.timestamp!.toDate())
                              : 'Just now',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppConstants.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.text,
                      style: TextStyle(
                        fontSize: isReply ? 13 : 14,
                        color: AppConstants.textPrimaryColor.withOpacity(0.87),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => provider.toggleCommentLike(videoId, comment.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: Row(
                              children: [
                                Icon(
                                  hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                  size: 16,
                                  color: hasLiked
                                      ? AppConstants.primaryColor
                                      : AppConstants.textSecondaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${comment.likes}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasLiked
                                        ? AppConstants.primaryColor
                                        : AppConstants.textSecondaryColor,
                                    fontWeight:
                                        hasLiked ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => provider.toggleCommentDislike(videoId, comment.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: Row(
                              children: [
                                Icon(
                                  hasDisliked
                                      ? Icons.thumb_down
                                      : Icons.thumb_down_outlined,
                                  size: 16,
                                  color: hasDisliked
                                      ? AppConstants.primaryColor
                                      : AppConstants.textSecondaryColor,
                                ),
                                if (comment.dislikes > 0) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '${comment.dislikes}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: hasDisliked
                                          ? AppConstants.primaryColor
                                          : AppConstants.textSecondaryColor,
                                      fontWeight: hasDisliked
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (!isReply && onReplyTap != null)
                          InkWell(
                            onTap: onReplyTap,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: Text(
                                'Reply',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.textSecondaryColor,
                                ),
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
      },
    );
  }
}

