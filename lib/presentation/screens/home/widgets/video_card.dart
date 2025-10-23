import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../video_playing_screen.dart';
import '../../../providers/download_provider.dart';
import '../../../providers/playlist_provider.dart';
import '../../../../core/utils/snackbar_helper.dart';
import 'video_thumbnail.dart';
import 'video_info_section.dart';

/// Video card widget for home screen feed
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
                    VideoThumbnail(
                      thumbnailUrl: data['thumbnailUrl'],
                      duration: data['duration'],
                    ),
                    VideoInfoSection(
                      data: data,
                      onMoreOptions: () => _showBottomSheet(context, widget.video, data),
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
                        onTap: () => Navigator.pop(sheetContext),
                      ),
                      _buildBottomSheetItem(
                        icon: Icons.not_interested_outlined,
                        title: 'Not interested',
                        onTap: () => Navigator.pop(sheetContext),
                      ),
                      _buildBottomSheetItem(
                        icon: Icons.block_outlined,
                        title: 'Don\'t recommend channel',
                        onTap: () => Navigator.pop(sheetContext),
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
                      'Downloading video...',
                      style: TextStyle(color: Colors.grey[300], fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.grey[800],
                      color: const Color(0xFF7B61FF),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${progress.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

