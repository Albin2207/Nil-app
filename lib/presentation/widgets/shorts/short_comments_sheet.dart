import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/short_comment_model.dart';
import '../../providers/shorts_provider_new.dart';
import '../../providers/auth_provider.dart';
import 'short_comment_item.dart';
import 'short_reply_dialog.dart';

class ShortCommentsSheet extends StatefulWidget {
  final String shortId;
  final int commentsCount;

  const ShortCommentsSheet({
    super.key,
    required this.shortId,
    required this.commentsCount,
  });

  @override
  State<ShortCommentsSheet> createState() => _ShortCommentsSheetState();
}

class _ShortCommentsSheetState extends State<ShortCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final text = _commentController.text.trim();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.firebaseUser;
    
    // Use Firebase Auth data directly (always available)
    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Anonymous User';
    final userAvatar = user?.photoURL ?? 'https://ui-avatars.com/api/?name=$userName&background=random';

    // Post comment first
    await context.read<ShortsProviderNew>().postComment(
          shortId: widget.shortId,
          text: text,
          userId: user?.uid,
          userName: userName,
          userAvatar: userAvatar,
        );
    
    // THEN clear and dismiss keyboard
    _commentController.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _showReplyDialog(ShortComment comment) {
    showDialog(
      context: context,
      builder: (context) => ShortReplyDialog(
        shortId: widget.shortId,
        parentComment: comment,
      ),
    );
  }

  Future<void> _deleteComment(String commentId) async {
    // Completely remove focus from all text fields
    FocusManager.instance.primaryFocus?.unfocus();
    _commentController.clear();
    
    try {
      await context.read<ShortsProviderNew>().deleteComment(widget.shortId, commentId);
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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments ${widget.commentsCount > 0 ? '(${widget.commentsCount})' : ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.black),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Comments list
          Expanded(
            child: StreamBuilder<List<ShortComment>>(
              stream: context.read<ShortsProviderNew>().getCommentsStream(widget.shortId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.comment_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to comment!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allComments = snapshot.data!;
                final topLevelComments = allComments
                    .where((comment) => comment.parentId == null)
                    .toList();

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: topLevelComments.length,
                  itemBuilder: (context, index) {
                    final comment = topLevelComments[index];
                    final replies = allComments
                        .where((c) => c.parentId == comment.id)
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top-level comment
                        ShortCommentItem(
                          key: ValueKey(comment.id),
                          comment: comment,
                          shortId: widget.shortId,
                          onReply: () async {
                            FocusManager.instance.primaryFocus?.unfocus();
                            await Future.delayed(const Duration(milliseconds: 200));
                            if (context.mounted) {
                              _showReplyDialog(comment);
                            }
                          },
                          onDelete: () async {
                            FocusManager.instance.primaryFocus?.unfocus();
                            _commentController.clear();
                            await Future.delayed(const Duration(milliseconds: 100));
                            if (context.mounted) {
                              await _deleteComment(comment.id);
                            }
                          },
                          replies: const [], // Don't pass replies here
                        ),
                        
                        // Render replies separately with their own delete callbacks
                        ...replies.map((reply) => Padding(
                          padding: const EdgeInsets.only(left: 48.0),
                          child: ShortCommentItem(
                            key: ValueKey(reply.id),
                            comment: reply,
                            shortId: widget.shortId,
                            onReply: () {}, // No reply to reply
                            onDelete: () async {
                              FocusManager.instance.primaryFocus?.unfocus();
                              _commentController.clear();
                              await _deleteComment(reply.id); // Use reply's ID!
                            },
                            replies: const [],
                          ),
                        )),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          
          const Divider(height: 1),
          
          // Comment input - Fixed to bottom
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final user = authProvider.firebaseUser;
                    final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
                    final userAvatar = user?.photoURL ?? 'https://ui-avatars.com/api/?name=$userName&background=random';
                    
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(userAvatar),
                          backgroundColor: Colors.grey[300],
                        ),
                    const SizedBox(width: 12),
                    Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.black),
                      enableInteractiveSelection: true,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) async {
                        await _postComment();
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                    ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        await _postComment();
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      icon: const Icon(Icons.send, color: Colors.blue),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
              ],
            ),
          ),
        );
      },
    );
  }
}

