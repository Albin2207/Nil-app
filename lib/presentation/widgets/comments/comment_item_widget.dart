import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../data/models/comment_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/comment_utils.dart';
import '../../../core/services/report_service.dart';
import '../../providers/comment_provider.dart';
import '../../providers/auth_provider.dart';
import 'comment_actions_menu.dart';
import 'report_comment_dialog.dart';
import 'edit_comment_dialog.dart';

class CommentItemWidget extends StatefulWidget {
  final String videoId;
  final CommentModel comment;
  final bool isReply;
  final String videoOwnerId;
  final VoidCallback? onReplyTap;
  final VoidCallback? onDeleteTap;
  final Function(String parentId, String parentUsername)? onReply;

  const CommentItemWidget({
    super.key,
    required this.videoId,
    required this.comment,
    required this.videoOwnerId,
    this.isReply = false,
    this.onReplyTap,
    this.onDeleteTap,
    this.onReply,
  });

  @override
  State<CommentItemWidget> createState() => _CommentItemWidgetState();
}

class _CommentItemWidgetState extends State<CommentItemWidget> {
  bool _showReplies = false;
  List<CommentModel> _replies = [];
  int _replyCount = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.isReply) {
      _loadReplyCount();
    }
  }

  Future<void> _loadReplyCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.videoId)
          .collection('comments')
          .where('parentId', isEqualTo: widget.comment.id)
          .get();
      
      if (mounted) {
        setState(() {
          _replyCount = snapshot.docs.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading reply count: $e');
    }
  }

  Future<void> _loadReplies() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.videoId)
          .collection('comments')
          .where('parentId', isEqualTo: widget.comment.id)
          .orderBy('timestamp', descending: false)
          .get();
      
      if (mounted) {
        setState(() {
          _replies = snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();
          _showReplies = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading replies: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load replies. Deploy Firebase index first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CommentProvider, AuthProvider>(
      builder: (context, provider, authProvider, child) {
        final hasLiked = provider.isCommentLiked(widget.comment.id);
        final hasDisliked = provider.isCommentDisliked(widget.comment.id);
        final currentUserId = authProvider.firebaseUser?.uid ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main comment
            Padding(
              padding: EdgeInsets.only(
                left: widget.isReply ? 48 : 16,
                right: 16,
                top: 12,
                bottom: 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: widget.isReply ? 14 : 18,
                    backgroundImage: NetworkImage(widget.comment.userAvatar),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Text(
                              widget.comment.username,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: widget.isReply ? 12 : 13,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.comment.timestamp != null
                                  ? timeago.format(widget.comment.timestamp!.toDate())
                                  : 'Just now',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            const Spacer(),
                            CommentActionsMenu(
                              commentId: widget.comment.id,
                              commentText: widget.comment.text,
                              commentUserId: widget.comment.userId,
                              currentUserId: currentUserId,
                              videoOwnerId: widget.videoOwnerId,
                              videoId: widget.videoId,
                              isPinned: widget.comment.isPinned,
                              onEdit: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => EditCommentDialog(
                                    commentId: widget.comment.id,
                                    videoId: widget.videoId,
                                    initialText: widget.comment.text,
                                    isShort: false,
                                  ),
                                );
                              },
                              onDelete: () {
                                CommentUtils.showDeleteDialog(
                                  context: context,
                                  onConfirm: () {
                                    if (widget.onDeleteTap != null) widget.onDeleteTap!();
                                  },
                                );
                              },
                              onReport: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => ReportCommentDialog(
                                    commentId: widget.comment.id,
                                    onReport: (reason) async {
                                      await ReportService().reportComment(
                                        reporterId: currentUserId,
                                        reportedUserId: widget.comment.userId,
                                        commentId: widget.comment.id,
                                        videoId: widget.videoId,
                                        reason: reason,
                                        commentText: widget.comment.text,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        
                        // Reply context
                        if (widget.comment.replyToUsername != null) ...[
                          Text(
                            '@${widget.comment.replyToUsername}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7B61FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        
                        // Comment text
                        Text(
                          widget.comment.text,
                          style: TextStyle(
                            fontSize: widget.isReply ? 13 : 14,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Action buttons
                        Row(
                          children: [
                            // Like
                            InkWell(
                              onTap: () => provider.toggleCommentLike(widget.videoId, widget.comment.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                      size: 16,
                                      color: hasLiked ? AppConstants.primaryColor : Colors.grey[500],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${widget.comment.likes}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: hasLiked ? AppConstants.primaryColor : Colors.grey[500],
                                        fontWeight: hasLiked ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Dislike
                            InkWell(
                              onTap: () => provider.toggleCommentDislike(widget.videoId, widget.comment.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: Icon(
                                  hasDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                                  size: 16,
                                  color: hasDisliked ? AppConstants.primaryColor : Colors.grey[500],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Reply
                            InkWell(
                              onTap: () {
                                if (widget.onReply != null) {
                                  widget.onReply!(
                                    widget.isReply ? (widget.comment.parentId ?? widget.comment.id) : widget.comment.id,
                                    widget.comment.username,
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: Text(
                                  'Reply',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[400],
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
            ),
            
            // View replies button
            if (!widget.isReply && _replyCount > 0 && !_showReplies)
              Padding(
                padding: const EdgeInsets.only(left: 60, right: 16, top: 4, bottom: 8),
                child: GestureDetector(
                  onTap: _loadReplies,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B61FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 2,
                          color: const Color(0xFF7B61FF),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '$_replyCount ${_replyCount == 1 ? 'reply' : 'replies'}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7B61FF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: Color(0xFF7B61FF),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Display replies
            if (_showReplies && _replies.isNotEmpty)
              Column(
                children: [
                  for (var reply in _replies)
                    CommentItemWidget(
                      videoId: widget.videoId,
                      comment: reply,
                      videoOwnerId: widget.videoOwnerId,
                      isReply: true,
                      onReply: widget.onReply,
                      onDeleteTap: () {
                        provider.deleteComment(widget.videoId, reply.id);
                        setState(() {
                          _replies.remove(reply);
                          _replyCount--;
                        });
                      },
                    ),
                  // Hide replies
                  Padding(
                    padding: const EdgeInsets.only(left: 60, top: 4, bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showReplies = false;
                          _replies.clear();
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 20, height: 2, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Hide replies',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_up, size: 18, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
