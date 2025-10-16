import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/comment_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/comment_provider.dart';
import 'comment_item_widget.dart';
import 'reply_dialog.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String videoId;

  const CommentsBottomSheet({
    super.key,
    required this.videoId,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _postComment() {
    final provider = context.read<CommentProvider>();
    provider.postComment(
      videoId: widget.videoId,
      text: _commentController.text,
    );
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  void _showReplyDialog(String parentId, String username) {
    showDialog(
      context: context,
      builder: (context) => ReplyDialog(
        videoId: widget.videoId,
        parentId: parentId,
        username: username,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Consumer<CommentProvider>(
                      builder: (context, provider, child) {
                        return StreamBuilder<List<CommentModel>>(
                          stream: provider.getCommentsStream(widget.videoId),
                          builder: (context, snapshot) {
                            final topLevelCount = snapshot.hasData
                                ? provider
                                    .getTopLevelComments(snapshot.data!)
                                    .length
                                : 0;
                            return Text(
                              'Comments $topLevelCount',
                              style: AppConstants.titleTextStyle,
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Add Comment Section
              Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(AppConstants.defaultUserAvatar),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(
                          color: AppConstants.textPrimaryColor,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                                color: AppConstants.primaryColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send,
                                color: AppConstants.primaryColor),
                            onPressed: _postComment,
                          ),
                        ),
                        onSubmitted: (_) => _postComment(),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Comments List
              Expanded(
                child: Consumer<CommentProvider>(
                  builder: (context, provider, child) {
                    return StreamBuilder<List<CommentModel>>(
                      stream: provider.getCommentsStream(widget.videoId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: AppConstants.primaryColor),
                          );
                        }

                        if (!snapshot.hasData) {
                          return _buildEmptyState();
                        }

                        final topLevelComments =
                            provider.getTopLevelComments(snapshot.data!);

                        if (topLevelComments.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: topLevelComments.length,
                          itemBuilder: (context, index) {
                            final comment = topLevelComments[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CommentItemWidget(
                                  videoId: widget.videoId,
                                  comment: comment,
                                  onReplyTap: () => _showReplyDialog(
                                      comment.id, comment.username),
                                ),
                                // Show replies
                                ...provider
                                    .getReplies(snapshot.data!, comment.id)
                                    .map((reply) => Padding(
                                          padding: const EdgeInsets.only(left: 48),
                                          child: CommentItemWidget(
                                            videoId: widget.videoId,
                                            comment: reply,
                                            isReply: true,
                                          ),
                                        )),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.comment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to comment!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

