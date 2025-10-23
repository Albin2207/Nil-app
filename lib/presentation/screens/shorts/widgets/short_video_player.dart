import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../data/models/short_video_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/download_provider.dart';
import '../../../providers/playlist_provider.dart';
import '../../../widgets/shorts/short_comments_sheet.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/snackbar_helper.dart';

/// Short video player widget with actions
class ShortVideoPlayer extends StatefulWidget {
  final ShortVideo short;
  final bool isCurrentPage;

  const ShortVideoPlayer({
    super.key,
    required this.short,
    required this.isCurrentPage,
  });

  @override
  State<ShortVideoPlayer> createState() => _ShortVideoPlayerState();
}

class _ShortVideoPlayerState extends State<ShortVideoPlayer>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _playPauseController;
  late Animation<double> _playPauseAnimation;
  bool _isMuted = false;
  bool _isInitialized = false;
  bool _hasIncrementedView = false;
  bool _showPlayPauseIcon = false;

  @override
  void initState() {
    super.initState();
    _playPauseController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _playPauseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _playPauseController, curve: Curves.easeOut),
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.short.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      await _controller.initialize();
      _controller.setLooping(true);

      if (widget.isCurrentPage) {
        await _controller.play();
        _incrementViews();
      }

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  Future<void> _incrementViews() async {
    if (_hasIncrementedView) return;
    _hasIncrementedView = true;

    try {
      await FirebaseFirestore.instance
          .collection('shorts')
          .doc(widget.short.id)
          .update({'views': FieldValue.increment(1)});
    } catch (e) {
      print('Error incrementing views: $e');
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      _showPlayPauseIconWithAnimation(isPause: true);
    } else {
      _controller.play();
      _showPlayPauseIconWithAnimation(isPause: false);
    }
  }

  void _showPlayPauseIconWithAnimation({required bool isPause}) {
    setState(() => _showPlayPauseIcon = true);
    _playPauseController.forward(from: 0.0);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showPlayPauseIcon = false);
      }
    });
  }

  void _openCommentsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ShortCommentsSheet(
        shortId: widget.short.id,
        commentsCount: widget.short.commentsCount,
        videoOwnerId: widget.short.uploadedBy ?? '',
      ),
    );
  }

  @override
  void didUpdateWidget(ShortVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentPage && !oldWidget.isCurrentPage) {
      if (_isInitialized && !_controller.value.isPlaying) {
        _controller.play();
      }
    } else if (!widget.isCurrentPage && oldWidget.isCurrentPage) {
      if (_isInitialized && _controller.value.isPlaying) {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _playPauseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitialized)
            GestureDetector(
              onTap: _togglePlayPause,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.red)),

          // Gradient overlays
          _buildGradients(),

          // Play/Pause icon animation
          if (_showPlayPauseIcon) _buildPlayPauseIcon(),

          // Right action buttons
          _buildActionButtons(context),

          // Video info (bottom left)
          _buildVideoInfo(context),

          // Mute button
          _buildMuteButton(),
        ],
      ),
    );
  }

  Widget _buildGradients() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.4),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.2, 0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildPlayPauseIcon() {
    return Center(
      child: FadeTransition(
        opacity: _playPauseAnimation,
        child: ScaleTransition(
          scale: _playPauseAnimation,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _controller.value.isPlaying ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Positioned(
      right: 12,
      bottom: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            icon: Icons.thumb_up_outlined,
            label: FormatUtils.formatCount(widget.short.likes),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            icon: Icons.thumb_down_outlined,
            label: FormatUtils.formatCount(widget.short.dislikes),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            icon: Icons.comment_outlined,
            label: FormatUtils.formatCount(widget.short.commentsCount),
            onTap: () => _openCommentsSheet(context),
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () {
              Share.share('Check out this short: ${widget.short.title}');
            },
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            icon: Icons.more_vert,
            label: '',
            onTap: () => _showOptionsMenu(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoInfo(BuildContext context) {
    return Positioned(
      left: 16,
      right: 80,
      bottom: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: widget.short.channelAvatar.isNotEmpty
                    ? NetworkImage(widget.short.channelAvatar)
                    : null,
                child: widget.short.channelAvatar.isEmpty
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                widget.short.channelName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.short.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.short.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.short.description,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
                shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMuteButton() {
    return Positioned(
      top: 50,
      right: 12,
      child: InkWell(
        onTap: _toggleMute,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isMuted ? Icons.volume_off : Icons.volume_up,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.download_outlined, color: Colors.red),
            title: const Text('Download', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showShortQualityPicker(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add, color: Colors.red),
            title: const Text('Save to playlist', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showShortPlaylistPicker(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Colors.red),
            title: const Text('Report', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showShortQualityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Download Quality',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            ...[('360p', 'Small', '360p'), ('720p', 'Medium', '720p'), ('1080p', 'Large', '1080p')]
                .map((q) => ListTile(
                      title: Text(q.$1, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(q.$2, style: TextStyle(color: Colors.grey[400])),
                      onTap: () {
                        Navigator.pop(ctx);
                        _startShortDownload(context, q.$3);
                      },
                    )),
          ],
        ),
      ),
    );
  }

  Future<void> _startShortDownload(BuildContext context, String quality) async {
    final provider = context.read<DownloadProvider>();
    final success = await provider.downloadVideo(
      videoId: widget.short.id,
      title: widget.short.title,
      videoUrl: widget.short.videoUrl,
      thumbnailUrl: widget.short.thumbnailUrl,
      quality: quality,
      isShort: true,
      channelName: widget.short.channelName,
      description: widget.short.description,
    );

    if (context.mounted) {
      if (success) {
        SnackBarHelper.showSuccess(context, 'Download complete!', icon: Icons.download_done);
      } else {
        SnackBarHelper.showError(context, 'Download failed');
      }
    }
  }

  Future<void> _showShortPlaylistPicker(BuildContext context) async {
    final provider = context.read<PlaylistProvider>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Save to Playlist',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            if (provider.playlists.isEmpty)
              Text('No playlists yet', style: TextStyle(color: Colors.grey[400]))
            else
              ...provider.playlists.map((p) => ListTile(
                    leading: const Icon(Icons.playlist_play, color: Colors.grey),
                    title: Text(p.name, style: const TextStyle(color: Colors.white)),
                    onTap: () async {
                      await provider.addVideoToPlaylist(p.id, widget.short.id);
                      if (sheetCtx.mounted) {
                        Navigator.pop(sheetCtx);
                        SnackBarHelper.showSuccess(
                          context,
                          'Added to ${p.name}',
                          icon: Icons.playlist_add_check,
                        );
                      }
                    },
                  )),
          ],
        ),
      ),
    );
  }
}

