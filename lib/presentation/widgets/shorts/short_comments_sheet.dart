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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.commentsCount > 0 ? 'Comments ${widget.commentsCount}' : 'Comments',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: Colors.grey[800]),
          
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
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.comment_outlined, size: 48, color: Colors.grey[600]),
                            const SizedBox(height: 12),
                            Text(
                              'No comments yet',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to comment!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
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
              color: const Color(0xFF1E1E1E),
              border: Border(
                top: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
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
                          backgroundColor: Colors.grey[700],
                        ),
                    const SizedBox(width: 12),
                    Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      enableInteractiveSelection: true,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        filled: true,
                        fillColor: const Color(0xFF2A2A2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
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
                      icon: const Icon(Icons.send, color: Color(0xFF7B61FF), size: 20),
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

