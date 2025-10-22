import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/comment_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/comment_provider.dart';
import '../../providers/auth_provider.dart';
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
  final FocusNode _textFieldFocusNode = FocusNode();

  @override
  void dispose() {
    _commentController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    final commentText = _commentController.text;
    final commentProvider = context.read<CommentProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.firebaseUser;
    
    // Use Firebase Auth data directly (always available)
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Anonymous User';
    final userAvatar = user?.photoURL ?? 'https://ui-avatars.com/api/?name=$userName&background=random';
    
    // Post comment first
    await commentProvider.postComment(
      videoId: widget.videoId,
      text: commentText,
      userId: user?.uid,
      userName: userName,
      userAvatar: userAvatar,
    );
    
    // THEN clear and dismiss keyboard
    _commentController.clear();
    _textFieldFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
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

  Future<void> _deleteComment(CommentProvider provider, String commentId) async {
    // Completely remove focus from all text fields
    FocusManager.instance.primaryFocus?.unfocus();
    _commentController.clear();
    
    try {
      await provider.deleteComment(widget.videoId, commentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting comment: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.6, 0.95],
      builder: (context, scrollController) {
        return AnimatedPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121212), // Dark background like YouTube
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar - more prominent
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding, vertical: 8),
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
                              topLevelCount > 0 ? 'Comments $topLevelCount' : 'Comments',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.grey[800]),

              // Add Comment Section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[800]!, width: 1),
                  ),
                ),
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final user = authProvider.firebaseUser;
                    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
                    final userAvatar = user?.photoURL ?? 'https://ui-avatars.com/api/?name=$userName&background=random';
                    
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(userAvatar),
                          backgroundColor: Colors.grey[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            focusNode: _textFieldFocusNode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                    color: AppConstants.primaryColor, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.send,
                                    color: AppConstants.primaryColor, size: 20),
                                onPressed: _postComment,
                              ),
                            ),
                            maxLines: 3,
                            minLines: 1,
                            onSubmitted: (_) => _postComment(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

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
                                  key: ValueKey(comment.id),
                                  videoId: widget.videoId,
                                  comment: comment,
                                  onReplyTap: () async {
                                    FocusManager.instance.primaryFocus?.unfocus();
                                    await Future.delayed(const Duration(milliseconds: 200));
                                    if (context.mounted) {
                                      _showReplyDialog(comment.id, comment.username);
                                    }
                                  },
                                  onDeleteTap: () async {
                                    // Ensure keyboard is completely dismissed
                                    _textFieldFocusNode.unfocus();
                                    FocusManager.instance.primaryFocus?.unfocus();
                                    _commentController.clear();
                                    // Wait for everything to settle
                                    await Future.delayed(const Duration(milliseconds: 100));
                                    if (context.mounted) {
                                      await _deleteComment(provider, comment.id);
                                    }
                                  },
                                ),
                                // Show replies
                                ...provider
                                    .getReplies(snapshot.data!, comment.id)
                                    .map((reply) => Padding(
                                          padding: const EdgeInsets.only(left: 48),
                                          child: CommentItemWidget(
                                            key: ValueKey(reply.id),
                                            videoId: widget.videoId,
                                            comment: reply,
                                            isReply: true,
                                            onDeleteTap: () async {
                                              // Ensure keyboard is completely dismissed
                                              _textFieldFocusNode.unfocus();
                                              FocusManager.instance.primaryFocus?.unfocus();
                                              _commentController.clear();
                                              // Wait for everything to settle
                                              await Future.delayed(const Duration(milliseconds: 100));
                                              if (context.mounted) {
                                                await _deleteComment(provider, reply.id);
                                              }
                                            },
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
          Icon(Icons.comment_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
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

