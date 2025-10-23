import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../data/models/playlist_model.dart';
import '../providers/playlist_provider.dart';
import '../../core/utils/snackbar_helper.dart';
import 'video_playing_screen.dart';
import 'shorts_screen_new.dart';

class PlaylistViewerScreen extends StatefulWidget {
  final PlaylistModel playlist;

  const PlaylistViewerScreen({super.key, required this.playlist});

  @override
  State<PlaylistViewerScreen> createState() => _PlaylistViewerScreenState();
}

class _PlaylistViewerScreenState extends State<PlaylistViewerScreen> {
  @override
  Widget build(BuildContext context) {
    print('=== Playlist "${widget.playlist.name}" ===');
    print('Total items: ${widget.playlist.videoIds.length}');
    print('Video IDs: ${widget.playlist.videoIds}');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.playlist.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Playlist Info Banner (Not clickable - just info!)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.red.withValues(alpha: 0.3), Colors.grey[900]!],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.red.withValues(alpha: 0.5),
                  width: 3,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Large centered icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.playlist_play,
                    size: 50,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),

                // Playlist name
                Text(
                  widget.playlist.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Description
                if (widget.playlist.description != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      widget.playlist.description!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Video count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Text(
                    '${widget.playlist.videoCount} ${widget.playlist.videoCount == 1 ? 'video' : 'videos'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // "Videos & Shorts" label
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '▼ VIDEOS & SHORTS ▼',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Videos List
          Expanded(
            child: widget.playlist.videoIds.isEmpty
                ? const Center(
                    child: Text(
                      'No videos in this playlist',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.playlist.videoIds.length,
                    itemBuilder: (context, index) {
                      final videoId = widget.playlist.videoIds[index];
                      return _buildPlaylistVideoItem(context, videoId);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Helper method to fetch from both videos and shorts collections
  Future<Map<String, dynamic>?> _fetchVideoOrShort(String id) async {
    try {
      print('Fetching item with ID: $id');

      // Try videos collection first
      final videoDoc = await FirebaseFirestore.instance
          .collection('videos')
          .doc(id)
          .get();
      if (videoDoc.exists) {
        final data = videoDoc.data() as Map<String, dynamic>;
        data['isShort'] = false;
        data['documentId'] = id;
        print('  ✓ Found VIDEO: ${data['title']}');
        return data;
      }

      // Try shorts collection
      final shortDoc = await FirebaseFirestore.instance
          .collection('shorts')
          .doc(id)
          .get();
      if (shortDoc.exists) {
        final data = shortDoc.data() as Map<String, dynamic>;
        data['isShort'] = true;
        data['documentId'] = id;
        print('  ✓ Found SHORT: ${data['title']}');
        return data;
      }

      print('  ✗ Item not found in videos or shorts collection!');
      return null;
    } catch (e) {
      print('  ✗ Error fetching video/short: $e');
      return null;
    }
  }

  void _removeFromPlaylist(BuildContext context, String videoId) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => TweenAnimationBuilder(
        duration: const Duration(milliseconds: 250),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (ctx, double value, child) {
          return Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: Opacity(
              opacity: value,
              child: AlertDialog(
                backgroundColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                content: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.withValues(alpha: 0.2),
                        Colors.grey[900]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Remove from Playlist?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This will remove the video from "${widget.playlist.name}"',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                final playlistProvider = context
                                    .read<PlaylistProvider>();
                                await playlistProvider.removeVideoFromPlaylist(
                                  widget.playlist.id,
                                  videoId,
                                );
                                Navigator.pop(dialogContext);
                                if (context.mounted) {
                                  SnackBarHelper.showSuccess(
                                    context,
                                    'Removed from playlist',
                                  );
                                  // Refresh the screen
                                  setState(() {});
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Remove',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistVideoItem(BuildContext context, String videoId) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchVideoOrShort(videoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 90,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900]!.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.red,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          print('Skipping invalid/non-existent item with ID: $videoId');
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;

        return TweenAnimationBuilder(
          duration: const Duration(milliseconds: 400),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 15 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.withValues(alpha: 0.08),
                        Colors.grey[900]!.withValues(alpha: 0.6),
                        Colors.grey[900]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () async {
                      print(
                        'Tapped on item: ${data['title']} (isShort: ${data['isShort']})',
                      );
                      try {
                        final isShort = data['isShort'] ?? false;

                        if (isShort) {
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const ShortsScreen(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                              ),
                            );
                          }
                        } else {
                          final videoQuery = await FirebaseFirestore.instance
                              .collection('videos')
                              .where(FieldPath.documentId, isEqualTo: videoId)
                              .limit(1)
                              .get();

                          if (videoQuery.docs.isNotEmpty) {
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => VideoPlayerScreen(
                                        video: videoQuery.docs.first,
                                      ),
                                  transitionsBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                ),
                              );
                            }
                          } else {
                            print('Video not found in query');
                          }
                        }
                      } catch (e) {
                        print('Error loading item: $e');
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Thumbnail with Play Overlay and Short Badge
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: data['thumbnailUrl'] ?? '',
                                  width: 120,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[800],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.grey[800],
                                        child: const Icon(
                                          Icons.error,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                              ),
                              // Play button overlay
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              // Short badge (top-left)
                              if (data['isShort'] == true)
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'SHORT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Video Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['title'] ?? 'Untitled',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  data['channelName'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[300],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Remove from playlist button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  _removeFromPlaylist(context, videoId),
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
