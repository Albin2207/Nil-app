import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/format_helper.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../providers/video_provider.dart';
import '../../providers/download_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../../data/models/video_model.dart';

class ActionButtonsWidget extends StatefulWidget {
  final String videoId;
  final int initialLikes;
  final String videoTitle;
  final String videoUrl;

  const ActionButtonsWidget({
    super.key,
    required this.videoId,
    required this.initialLikes,
    required this.videoTitle,
    required this.videoUrl,
  });

  @override
  State<ActionButtonsWidget> createState() => _ActionButtonsWidgetState();
}

class _ActionButtonsWidgetState extends State<ActionButtonsWidget> {
  void _showQualityPicker(BuildContext context) async {
    final videoDoc = await FirebaseFirestore.instance
        .collection(AppConstants.videosCollection)
        .doc(widget.videoId)
        .get();
    
    final videoData = videoDoc.data();
    if (videoData == null || !context.mounted) return;

    final VideoModel video = VideoModel.fromFirestore(videoDoc);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Download Quality',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _QualityOption(
              quality: '360p',
              size: 'Small (~20 MB)',
              onTap: () => _startDownload(context, video, '360p'),
            ),
            _QualityOption(
              quality: '720p',
              size: 'Medium (~50 MB)',
              recommended: true,
              onTap: () => _startDownload(context, video, '720p'),
            ),
            _QualityOption(
              quality: '1080p',
              size: 'Large (~100 MB)',
              onTap: () => _startDownload(context, video, '1080p'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDownload(BuildContext context, VideoModel video, String quality) async {
    Navigator.pop(context); // Close quality picker
    
    final downloadProvider = context.read<DownloadProvider>();
    
    // Check if already downloaded
    if (await downloadProvider.isVideoDownloaded(widget.videoId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video already downloaded'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show downloading overlay with progress
    if (context.mounted) {
      _showDownloadProgressDialog(context, quality);
    }

    final success = await downloadProvider.downloadVideo(
      videoId: widget.videoId,
      videoUrl: widget.videoUrl,
      title: widget.videoTitle,
      thumbnailUrl: video.thumbnailUrl,
      quality: quality,
      isShort: false,
      channelName: video.channelName,
      description: video.description,
    );

    if (context.mounted) {
      Navigator.pop(context); // Close progress dialog
      if (success) {
        SnackBarHelper.showSuccess(
          context,
          'Download complete!',
          icon: Icons.download_done,
        );
      } else {
        SnackBarHelper.showError(
          context,
          'Download failed',
          icon: Icons.error_outline,
        );
      }
    }
  }

  void _showDownloadProgressDialog(BuildContext context, String quality) {
    bool wasDownloading = true; // Track if download was in progress
    bool dialogClosed = false; // Prevent multiple close attempts
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: Consumer<DownloadProvider>(
          builder: (context, provider, child) {
            final progress = provider.downloadProgress;
            final isDownloading = provider.isDownloading;
            
            print('🎨 Dialog UI update: progress=${(progress * 100).toInt()}%, isDownloading=$isDownloading');
            
            // Auto-close dialog when download completes
            // Close when download stops (was downloading, now not)
            if (wasDownloading && !isDownloading && !dialogClosed) {
              dialogClosed = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(dialogContext)) {
                  Navigator.of(dialogContext).pop();
                  
                  // Show success message
                  SnackBarHelper.showSuccess(
                    context,
                    'Download completed!',
                    icon: Icons.download_done,
                  );
                }
              });
            }
            
            wasDownloading = isDownloading;
            
            return Dialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.download_outlined,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      progress > 0 ? 'Downloading...' : 'Preparing download...',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quality: $quality',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Progress bar
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please wait, do not close the app',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
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

  void _showPlaylistPicker(BuildContext context) async {
    final playlistProvider = context.read<PlaylistProvider>();
    await playlistProvider.loadPlaylists();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Save to Playlist',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _createNewPlaylist(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<PlaylistProvider>(
              builder: (context, provider, child) {
                if (provider.playlists.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No playlists yet.\nCreate one to save videos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = provider.playlists[index];
                    final isInPlaylist = playlist.videoIds.contains(widget.videoId);
                    
                    return ListTile(
                      leading: Icon(
                        Icons.playlist_play,
                        color: isInPlaylist ? Colors.red : Colors.grey,
                      ),
                      title: Text(
                        playlist.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${playlist.videoCount} videos',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      trailing: isInPlaylist
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () async {
                        Navigator.pop(context); // Close the bottom sheet
                        
                        if (isInPlaylist) {
                          await provider.removeVideoFromPlaylist(playlist.id, widget.videoId);
                          if (context.mounted) {
                            SnackBarHelper.showInfo(
                              context,
                              'Removed from playlist',
                              icon: Icons.playlist_remove,
                              color: Colors.orange,
                            );
                          }
                        } else {
                          await provider.addVideoToPlaylist(playlist.id, widget.videoId);
                          if (context.mounted) {
                            SnackBarHelper.showSuccess(
                              context,
                              'Added to playlist',
                              icon: Icons.playlist_add_check,
                            );
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createNewPlaylist(BuildContext context) {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Playlist name',
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final playlistProvider = context.read<PlaylistProvider>();
                final playlist = await playlistProvider.createPlaylist(name: nameController.text.trim());
                if (playlist != null && context.mounted) {
                  await playlistProvider.addVideoToPlaylist(playlist.id, widget.videoId);
                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Playlist created and video added'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.smallPadding),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Like Button with Real-time Count
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.videosCollection)
                  .doc(widget.videoId)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final currentLikes = data?['likes'] as int? ?? widget.initialLikes;
                
                return Consumer<VideoProvider>(
                  builder: (context, provider, child) {
                    return _ActionButton(
                      icon: provider.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      label: FormatHelper.formatCount(currentLikes),
                      onTap: () => provider.toggleLike(),
                      isActive: provider.isLiked,
                    );
                  },
                );
              },
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Consumer<VideoProvider>(
              builder: (context, provider, child) {
                return _ActionButton(
                  icon: provider.isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                  label: 'Dislike',
                  onTap: () => provider.toggleDislike(),
                  isActive: provider.isDisliked,
                );
              },
            ),
            const SizedBox(width: AppConstants.smallPadding),
            _ActionButton(
              icon: Icons.share_outlined,
              label: 'Share',
              onTap: () {
                // ignore: deprecated_member_use
                Share.share(
                  'Check out this video: ${widget.videoTitle}\n${widget.videoUrl}',
                  subject: widget.videoTitle,
                );
              },
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Consumer<DownloadProvider>(
              builder: (context, downloadProvider, child) {
                return FutureBuilder<bool>(
                  future: downloadProvider.isVideoDownloaded(widget.videoId),
                  builder: (context, snapshot) {
                    final isDownloaded = snapshot.data ?? false;
                    return _ActionButton(
                      icon: isDownloaded ? Icons.download_done : Icons.download_outlined,
                      label: isDownloaded ? 'Downloaded' : 'Download',
                      onTap: isDownloaded
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Already downloaded'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          : () => _showQualityPicker(context),
                      isActive: isDownloaded,
                    );
                  },
                );
              },
            ),
            const SizedBox(width: AppConstants.smallPadding),
            _ActionButton(
              icon: Icons.playlist_add,
              label: 'Save',
              onTap: () => _showPlaylistPicker(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: AppConstants.iconSizeMedium,
              color: isActive ? AppConstants.primaryColor : AppConstants.textPrimaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? AppConstants.primaryColor : AppConstants.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QualityOption extends StatelessWidget {
  final String quality;
  final String size;
  final bool recommended;
  final VoidCallback onTap;

  const _QualityOption({
    required this.quality,
    required this.size,
    this.recommended = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: recommended ? Colors.red : Colors.grey[300]!,
            width: recommended ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.high_quality,
              color: recommended ? Colors.red : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        quality,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: recommended ? Colors.red : Colors.white,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Recommended',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    size,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

