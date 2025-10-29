import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/comment_model.dart';
import '../providers/image_comment_provider.dart';
import '../providers/auth_provider.dart';
import 'comments/image_comment_item_widget.dart';
import 'comments/image_reply_dialog.dart';

class ImageCommentsBottomSheet extends StatefulWidget {
  final String imagePostId;
  final String imagePostOwnerId;

  const ImageCommentsBottomSheet({
    super.key,
    required this.imagePostId,
    required this.imagePostOwnerId,
  });

  @override
  State<ImageCommentsBottomSheet> createState() => _ImageCommentsBottomSheetState();
}

class _ImageCommentsBottomSheetState extends State<ImageCommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  late ScrollController _scrollController;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _textFieldFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || _isPostingComment) return;

    setState(() {
      _isPostingComment = true;
    });

    try {
      final commentText = _commentController.text;
      final imageCommentProvider = context.read<ImageCommentProvider>();
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.firebaseUser;
      
      // Use Firebase Auth data directly (always available)
      final userName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Anonymous User';
      final userAvatar = user?.photoURL ?? 'https://ui-avatars.com/api/?name=$userName&background=random';
      
      // Post comment first
      await imageCommentProvider.postComment(
        imagePostId: widget.imagePostId,
        text: commentText,
        userId: user?.uid,
        userName: userName,
        userAvatar: userAvatar,
      );
      
      // Clear text field and unfocus only after successful post
      _commentController.clear();
      _textFieldFocusNode.unfocus();
      
      // New comments appear at top automatically (newest first from Firestore)
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPostingComment = false;
        });
      }
    }
  }

  void _showReplyDialog(String parentId, String username) {
    showDialog(
      context: context,
      builder: (context) => ImageReplyDialog(
        imagePostId: widget.imagePostId,
        parentId: parentId,
        username: username,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.firebaseUser;
    final isLoggedIn = user != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Comments List
          Expanded(
            child: Consumer<ImageCommentProvider>(
              builder: (context, provider, child) {
                return StreamBuilder<List<CommentModel>>(
                  stream: provider.getCommentsStream(widget.imagePostId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.red),
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
                      controller: _scrollController,
                      itemCount: topLevelComments.length,
                      itemBuilder: (context, index) {
                        // Comments are already sorted newest first from Firestore
                        final comment = topLevelComments[index];
                        return ImageCommentItemWidget(
                          key: ValueKey(comment.id),
                          imagePostId: widget.imagePostId,
                          imagePostOwnerId: widget.imagePostOwnerId,
                          comment: comment,
                          onReply: (parentId, parentUsername) async {
                            FocusManager.instance.primaryFocus?.unfocus();
                            await Future.delayed(const Duration(milliseconds: 200));
                            if (context.mounted) {
                              _showReplyDialog(parentId, parentUsername);
                            }
                          },
                          onDeleteTap: () async {
                            _textFieldFocusNode.unfocus();
                            FocusManager.instance.primaryFocus?.unfocus();
                            _commentController.clear();
                            await Future.delayed(const Duration(milliseconds: 100));
                            if (context.mounted) {
                              provider.deleteComment(widget.imagePostId, comment.id);
                            }
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          
          // Comment Input - Fixed at bottom
          if (isLoggedIn)
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                border: Border(
                  top: BorderSide(color: Colors.grey[800]!, width: 1),
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
                          enabled: !_isPostingComment,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: _isPostingComment ? 'Posting...' : 'Add a comment...',
                            hintStyle: TextStyle(
                              color: _isPostingComment ? Colors.grey[400] : Colors.grey[500],
                            ),
                            filled: true,
                            fillColor: _isPostingComment 
                                ? const Color(0xFF1A1A1A) 
                                : const Color(0xFF2A2A2A),
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
                                  color: Colors.red, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            suffixIcon: _isPostingComment
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.send,
                                        color: Colors.red, size: 20),
                                    onPressed: _isPostingComment ? null : _postComment,
                                  ),
                          ),
                          maxLines: 3,
                          minLines: 1,
                          onSubmitted: _isPostingComment ? null : (_) => _postComment(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}