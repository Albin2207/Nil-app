import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../screens/image_viewer_screen.dart';
import '../screens/creator_profile_screen.dart';
import '../providers/image_post_provider.dart';
import 'image_comments_bottom_sheet.dart';

class ImagePostCard extends StatefulWidget {
  final QueryDocumentSnapshot imagePost;
  final VoidCallback? onMarkNotInterested;
  final VoidCallback? onBlockChannel;

  const ImagePostCard({
    super.key,
    required this.imagePost,
    this.onMarkNotInterested,
    this.onBlockChannel,
  });

  @override
  State<ImagePostCard> createState() => _ImagePostCardState();
}

class _ImagePostCardState extends State<ImagePostCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late PageController _pageController;
  int _currentPage = 0;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _pageController = PageController();

    // Start animation
    _animationController.forward();
    
    // Load user preferences using provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImagePostProvider>().loadUserPreferences(widget.imagePost.id);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final postTime = timestamp.toDate();
    final difference = now.difference(postTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _openImageViewer() {
    final data = widget.imagePost.data() as Map<String, dynamic>;
    final imageUrls = List<String>.from(data['imageUrls'] ?? []);
    final title = data['title'] ?? '';
    final channelName = data['channelName'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          imageUrls: imageUrls,
          initialIndex: _currentPage,
          title: title,
          channelName: channelName,
          timestamp: timestamp != null
              ? _formatTimestamp(timestamp)
              : 'Unknown time',
        ),
      ),
    );
  }

  void _shareImagePost() {
    final data = widget.imagePost.data() as Map<String, dynamic>;
    final title = data['title'] ?? '';
    final channelName = data['channelName'] ?? '';
    final imageUrls = List<String>.from(data['imageUrls'] ?? []);
    
    String shareText = 'Check out this image post by $channelName: $title';
    if (imageUrls.isNotEmpty) {
      shareText += '\n\nView the images: ${imageUrls.first}';
    }
    
    Share.share(shareText);
  }

  void _showCommentsBottomSheet() {
    final data = widget.imagePost.data() as Map<String, dynamic>;
    final uploadedBy = data['uploadedBy'] ?? '';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ImageCommentsBottomSheet(
        imagePostId: widget.imagePost.id,
        imagePostOwnerId: uploadedBy,
      ),
    );
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text(
                'Share',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _shareImagePost();
              },
            ),
            ListTile(
              leading: const Icon(Icons.thumb_down, color: Colors.white),
              title: const Text(
                'Not Interested',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onMarkNotInterested?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text(
                'Block Channel',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onBlockChannel?.call();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ImagePostProvider>(
      builder: (context, imagePostProvider, child) {
        return StreamBuilder<DocumentSnapshot>(
          stream: imagePostProvider.getPostStream(widget.imagePost.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              // Fallback to original data if stream fails
              return _buildImagePostCard(widget.imagePost.data() as Map<String, dynamic>, imagePostProvider);
            }
            
            final data = snapshot.data!.data() as Map<String, dynamic>;
            imagePostProvider.updatePostData(widget.imagePost.id, data);
            return _buildImagePostCard(data, imagePostProvider);
          },
        );
      },
    );
  }

  Widget _buildImagePostCard(Map<String, dynamic> data, ImagePostProvider provider) {
    final imageUrls = List<String>.from(data['imageUrls'] ?? []);
    final title = data['title'] ?? '';
    final description = data['description'] ?? '';
    final channelName = data['channelName'] ?? 'Unknown';

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value.dy * 50),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.withValues(alpha: 0.05),
                    Colors.grey[900]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Carousel with Overlay Actions
                  GestureDetector(
                    onTap: _openImageViewer,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Container(
                            height: 300,
                            width: double.infinity,
                            color: Colors.grey[900],
                            child: imageUrls.isNotEmpty
                                ? PageView.builder(
                                    controller: _pageController,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentPage = index;
                                      });
                                    },
                                    itemCount: imageUrls.length,
                                    itemBuilder: (context, index) {
                                      return CachedNetworkImage(
                                        imageUrl: imageUrls[index],
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: Colors.grey[800],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: Colors.grey[800],
                                          child: const Center(
                                            child: Icon(
                                              Icons.error_outline,
                                              size: 48,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[800],
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        // Page indicator
                        if (imageUrls.length > 1)
                          Positioned(
                            bottom: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_currentPage + 1} / ${imageUrls.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        // Action buttons overlay
                        Positioned(
                          right: 16,
                          top: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Like Button
                              _buildOverlayActionButton(
                                icon: provider.isPostLiked(widget.imagePost.id) ? Icons.thumb_up : Icons.thumb_up_outlined,
                                label: provider.formatCount(provider.getPostLikeCount(widget.imagePost.id)),
                                color: provider.isPostLiked(widget.imagePost.id) ? Colors.red : Colors.white,
                                onTap: () => provider.toggleLike(widget.imagePost.id),
                              ),
                              const SizedBox(height: 12),
                              // Dislike Button
                              _buildOverlayActionButton(
                                icon: provider.isPostDisliked(widget.imagePost.id) ? Icons.thumb_down : Icons.thumb_down_outlined,
                                label: provider.isPostDisliked(widget.imagePost.id) ? '' : provider.formatCount(provider.getPostDislikeCount(widget.imagePost.id)),
                                color: provider.isPostDisliked(widget.imagePost.id) ? Colors.red : Colors.white,
                                onTap: () => provider.toggleDislike(widget.imagePost.id),
                              ),
                              const SizedBox(height: 12),
                              // Comment Button
                              _buildOverlayActionButton(
                                icon: Icons.comment_outlined,
                                label: provider.formatCount(provider.getPostCommentCount(widget.imagePost.id)),
                                color: Colors.white,
                                onTap: () {
                                  _showCommentsBottomSheet();
                                },
                              ),
                              const SizedBox(height: 12),
                              // More Options Button
                              GestureDetector(
                                onTap: _showBottomSheet,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.0),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.0),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Channel Info and Description
                        Row(
                          children: [
                            // Channel Avatar
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreatorProfileScreen(
                                      creatorId: data['uploadedBy'] ?? '',
                                      creatorName: channelName,
                                      creatorAvatar: data['channelAvatar'] ?? '',
                                    ),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.red,
                                backgroundImage: data['channelAvatar'] != null && data['channelAvatar'].isNotEmpty
                                    ? NetworkImage(data['channelAvatar'])
                                    : null,
                                child: data['channelAvatar'] == null || data['channelAvatar'].isEmpty
                                    ? Text(
                                        channelName.isNotEmpty
                                            ? channelName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Description
                            Expanded(
                              child: description.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isDescriptionExpanded = !_isDescriptionExpanded;
                                        });
                                      },
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: description,
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (description.length > 50 && !_isDescriptionExpanded)
                                              TextSpan(
                                                text: ' more...',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            if (_isDescriptionExpanded)
                                              TextSpan(
                                                text: ' Show less',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                          ],
                                        ),
                                        maxLines: _isDescriptionExpanded ? null : 1,
                                        overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverlayActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.0),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.0),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
