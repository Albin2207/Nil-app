
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'video_playing_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/download_provider.dart';
import '../providers/playlist_provider.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/watch_later_service.dart';
import '../../core/services/content_preferences_service.dart';
import '../../core/utils/snackbar_helper.dart';
import '../widgets/common/offline_widget.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final connectivityService = context.watch<ConnectivityService>();
    
    // Show offline widget if no connection
    if (!connectivityService.isOnline) {
    return Scaffold(
        backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.red.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.red, size: 24),
              ),
            const SizedBox(width: 8),
            const Text(
                'NIL',
              style: TextStyle(
                  color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                ),
              ),
            ],
          ),
        ),
        body: OfflineWidget(
          onRetry: () async {
            await connectivityService.refresh();
            if (mounted) setState(() {});
          },
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/nil_app_icon-removebg-preview.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withValues(alpha: 0.3),
                            Colors.red.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                      child: const Icon(Icons.play_circle_filled, color: Colors.red, size: 20),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'NIL',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cast, color: Colors.grey, size: 20),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_outlined, color: Colors.grey, size: 20),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, color: Colors.grey, size: 20),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final firebaseUser = authProvider.firebaseUser;
                  final user = authProvider.currentUser;
                  
                  // Get user's profile picture or first letter of name
                  final photoUrl = user?.photoUrl ?? firebaseUser?.photoURL;
                  final displayName = user?.name ?? firebaseUser?.displayName ?? 'U';
                  
                  return InkWell(
                    onTap: () {
                      // Navigate to profile screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
            child: CircleAvatar(
              radius: 16,
                      backgroundColor: Colors.red,
                      backgroundImage: photoUrl != null 
                          ? NetworkImage(photoUrl) 
                          : null,
                      child: photoUrl == null
                          ? Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, Set<String>>>(
        future: Future.wait([
          ContentPreferencesService.getNotInterestedVideos(),
          ContentPreferencesService.getBlockedChannels(),
        ]).then((results) => {
          'notInterested': results[0],
          'blockedChannels': results[1],
        }),
        builder: (context, prefsSnapshot) {
          if (!prefsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          final notInterestedVideos = prefsSnapshot.data!['notInterested']!;
          final blockedChannels = prefsSnapshot.data!['blockedChannels']!;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('videos')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.red));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No videos yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              // Filter out not interested videos and videos from blocked channels
              final allVideos = snapshot.data!.docs;
              final filteredVideos = allVideos.where((video) {
                final data = video.data() as Map<String, dynamic>;
                final videoId = video.id;
                final uploadedBy = data['uploadedBy'] ?? '';
                
                // Filter out not interested videos
                if (notInterestedVideos.contains(videoId)) {
                  return false;
                }
                
                // Filter out videos from blocked channels
                if (blockedChannels.contains(uploadedBy)) {
                  return false;
                }
                
                return true;
              }).toList();

              if (filteredVideos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No videos to show',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All available videos are filtered',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredVideos.length,
                itemBuilder: (context, index) {
                  return VideoCard(video: filteredVideos[index]);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class VideoCard extends StatefulWidget {
  final QueryDocumentSnapshot video;

  const VideoCard({required this.video, super.key});

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds.remainder(60);
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.video.data() as Map<String, dynamic>;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
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
              child: InkWell(
      onTap: () {
        Navigator.push(
          context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          VideoPlayerScreen(video: widget.video),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
          ),
        );
      },
                borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Stack(
            children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Container(
                width: double.infinity,
                height: 220,
                            color: Colors.grey[900],
                child: data['thumbnailUrl'] != null
                    ? Image.network(
                        data['thumbnailUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.error_outline,
                                          size: 48,
                                          color: Colors.grey[600],
                                        ),
                          );
                        },
                      )
                                : Center(
                                    child: Icon(
                                      Icons.play_circle_outline,
                                      size: 64,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                          ),
                        ),
                        // Duration badge with glassy effect
              if (data['duration'] != null)
                Positioned(
                            bottom: 10,
                            right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                    ),
                    decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.8),
                                    Colors.black.withValues(alpha: 0.6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 0.5,
                                ),
                    ),
                    child: Text(
                      _formatDuration(data['duration']),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                                  fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Video Info
          Padding(
                      padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                          // Channel Avatar with glassy border
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 20,
                  backgroundImage: NetworkImage(
                    data['channelAvatar'] ?? 'https://i.pravatar.cc/150?img=2',
                              ),
                  ),
                ),
                const SizedBox(width: 12),

                // Video Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Untitled Video',
                        style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                          height: 1.3,
                                    color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data['channelName'] ?? 'Unknown Channel',
                        style: TextStyle(
                          fontSize: 13,
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.visibility,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_formatCount(data['views'] ?? 0)} views',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        data['timestamp'] != null
                                            ? timeago.format((data['timestamp'] as Timestamp).toDate())
                                            : 'Recently',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                      ),
                    ],
                  ),
                ),

                          // More options button with glassy effect
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.more_vert,
                                size: 20,
                                color: Colors.grey[400],
                              ),
                  onPressed: () {
                                _showBottomSheet(context, widget.video, data);
                  },
                              padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBottomSheet(BuildContext context, QueryDocumentSnapshot video, Map<String, dynamic> data) {
    final videoId = video.id;
    final videoTitle = data['title'] ?? 'Untitled';
    final videoUrl = data['videoUrl'] ?? '';
    final thumbnailUrl = data['thumbnailUrl'] ?? '';
    final channelName = data['channelName'] ?? 'Unknown';
    final description = data['description'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[900]!,
                Colors.black,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Download
              _buildBottomSheetItem(
                icon: Icons.download_outlined,
                title: 'Download video',
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          final downloadProvider = context.read<DownloadProvider>();
                          final isDownloaded = await downloadProvider.isVideoDownloaded(videoId);
                          if (isDownloaded) {
                            if (context.mounted) {
                              SnackBarHelper.showSuccess(context, 'Already downloaded', icon: Icons.download_done);
                            }
                          } else {
                            if (context.mounted) {
                              _showQualityPicker(context, videoId, videoTitle, videoUrl, thumbnailUrl, channelName, description);
                            }
                          }
                        },
                      ),
                      // Save to playlist
                      _buildBottomSheetItem(
                        icon: Icons.playlist_add,
                        title: 'Save to playlist',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _showPlaylistPicker(context, videoId);
                        },
                      ),
                      // Share
              _buildBottomSheetItem(
                icon: Icons.share_outlined,
                title: 'Share',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          Share.share(
                            'Check out this video: $videoTitle\n$videoUrl',
                            subject: videoTitle,
                          );
                        },
                      ),
                      _buildBottomSheetItem(
                        icon: Icons.watch_later_outlined,
                        title: 'Save to Watch Later',
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          final wasAdded = await WatchLaterService.addToWatchLater(
                            contentId: videoId,
                            contentType: 'video',
                            title: videoTitle,
                            thumbnailUrl: thumbnailUrl,
                            channelName: channelName,
                            channelAvatar: data['channelAvatar'] ?? '',
                          );
                          if (context.mounted) {
                            if (wasAdded) {
                              SnackBarHelper.showSuccess(context, 'Added to Watch Later', icon: Icons.watch_later);
                            } else {
                              SnackBarHelper.showInfo(context, 'Already in Watch Later', icon: Icons.watch_later);
                            }
                          }
                        },
              ),
              _buildBottomSheetItem(
                icon: Icons.not_interested_outlined,
                title: 'Not interested',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final success = await ContentPreferencesService.markVideoNotInterested(videoId);
                  if (context.mounted) {
                    if (success) {
                      SnackBarHelper.showSuccess(context, 'Video marked as not interested', icon: Icons.not_interested);
                      // Refresh the page
                      if (mounted) setState(() {});
                    } else {
                      SnackBarHelper.showError(context, 'Failed to mark video', icon: Icons.error);
                    }
                  }
                },
              ),
              _buildBottomSheetItem(
                icon: Icons.block_outlined,
                title: 'Don\'t recommend channel',
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final success = await ContentPreferencesService.dontRecommendChannel(
                    data['uploadedBy'] ?? '',
                    channelName,
                  );
                  if (context.mounted) {
                    if (success) {
                      SnackBarHelper.showSuccess(context, 'Channel blocked from recommendations', icon: Icons.block);
                      // Refresh the page
                      if (mounted) setState(() {});
                    } else {
                      SnackBarHelper.showError(context, 'Failed to block channel', icon: Icons.error);
                    }
                  }
                },
              ),
              _buildBottomSheetItem(
                icon: Icons.flag_outlined,
                title: 'Report',
                        onTap: () => Navigator.pop(sheetContext),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final color = iconColor ?? Colors.red;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showQualityPicker(BuildContext context, String videoId, String title, String url, String thumbnail, String channelName, String description) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Download Quality', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            ...[
              ('360p', 'Small (~15 MB)', '360p'),
              ('720p', 'Medium (~40 MB)', '720p'),
              ('1080p', 'Large (~80 MB)', '1080p'),
            ].map((q) => ListTile(
              title: Text(q.$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(q.$2, style: TextStyle(color: Colors.grey[400])),
              trailing: q.$1 == '720p' 
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF7B61FF), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Best', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () async {
                Navigator.pop(ctx);
                if (context.mounted) {
                  _showDownloadProgress(context);
                  final success = await context.read<DownloadProvider>().downloadVideo(
                    videoId: videoId, title: title, videoUrl: url, thumbnailUrl: thumbnail,
                    quality: q.$3, isShort: false, channelName: channelName, description: description,
                  );
                  if (context.mounted) {
                    Navigator.pop(context); // Close progress dialog
                    if (success) {
                      SnackBarHelper.showSuccess(context, 'Download complete!', icon: Icons.download_done);
                    } else {
                      SnackBarHelper.showError(context, 'Download failed', icon: Icons.error);
                    }
                  }
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showPlaylistPicker(BuildContext context, String videoId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Consumer<PlaylistProvider>(
        builder: (ctx, provider, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Save to Playlist', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              if (provider.playlists.isEmpty)
                Text('No playlists yet', style: TextStyle(color: Colors.grey[400]))
              else
                ...provider.playlists.map((p) => ListTile(
                  leading: Icon(Icons.playlist_play, color: Colors.grey[600]),
                  title: Text(p.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${p.videoIds.length} videos', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  onTap: () async {
                    await provider.addVideoToPlaylist(p.id, videoId);
                    if (sheetCtx.mounted) {
                      Navigator.pop(sheetCtx);
                      SnackBarHelper.showSuccess(context, 'Added to ${p.name}', icon: Icons.playlist_add_check);
                    }
                  },
                )),
            ],
          ),
        ),
      ),
    );
  }

  void _showDownloadProgress(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Consumer<DownloadProvider>(
          builder: (context, provider, child) {
            final progress = provider.downloadProgress;
            return Dialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.download_outlined, size: 48, color: Color(0xFF7B61FF)),
                    const SizedBox(height: 16),
                    Text(
                      progress > 0 ? 'Downloading...' : 'Preparing...',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    CircularProgressIndicator(
                      value: progress > 0 ? progress : null,
                      color: const Color(0xFF7B61FF),
                      backgroundColor: Colors.grey[800],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}