import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/short_video_model.dart';
import '../providers/shorts_provider_new.dart';
import '../../core/utils/format_helper.dart';

class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  List<ShortVideo> _cachedShorts = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: StreamBuilder<List<ShortVideo>>(
        stream: context.read<ShortsProviderNew>().getShortsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _cachedShorts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          // Update cached shorts if we have new data
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            _cachedShorts = snapshot.data!;
          }

          if (_cachedShorts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_outline,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No Shorts yet',
                    style: TextStyle(color: Colors.grey[400], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add shorts to see them here',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: _cachedShorts.length,
                onPageChanged: _onPageChanged,
                physics: const ClampingScrollPhysics(), // Better scroll physics
                itemBuilder: (context, index) {
                  final short = _cachedShorts[index];
                  return ShortVideoPlayer(
                    key: ValueKey(short.id),
                    short: short,
                    isCurrentPage: index == _currentIndex,
                  );
                },
              ),
              
              // Page indicator (shows current position)
              if (_cachedShorts.length > 1)
                Positioned(
                  right: 8,
                  top: MediaQuery.of(context).padding.top + 60,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${_cachedShorts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

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

class _ShortVideoPlayerState extends State<ShortVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isMuted = false;
  bool _isInitialized = false;
  bool _hasIncrementedView = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.short.videoUrl),
      );

      await _controller.initialize();
      _controller.setLooping(true);
      _controller.setVolume(1.0);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        if (widget.isCurrentPage) {
          _controller.play();
          _incrementViews();
        }
      }

      _controller.addListener(() {
        if (mounted) setState(() {});
      });
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void didUpdateWidget(ShortVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (!_isInitialized) return;
    
    if (widget.isCurrentPage && !oldWidget.isCurrentPage) {
      // This short became visible
      _controller.play();
      if (!_hasIncrementedView) {
        _incrementViews();
      }
    } else if (!widget.isCurrentPage && oldWidget.isCurrentPage) {
      // This short is no longer visible
      _controller.pause();
      _controller.seekTo(Duration.zero); // Reset to beginning
    }
  }

  Future<void> _incrementViews() async {
    if (_hasIncrementedView) return;
    _hasIncrementedView = true;
    await context.read<ShortsProviderNew>().incrementViews(widget.short.id);
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Player
          if (_isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
            ),

          // Gradient overlays for better text visibility
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top Bar (Shorts logo)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Row(
              children: [
                const Icon(Icons.play_circle_filled, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Shorts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Mute/Unmute button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: IconButton(
              icon: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _toggleMute,
            ),
          ),

          // Right side action buttons
          Positioned(
            right: 12,
            bottom: 100,
            child: Column(
              children: [
                _buildActionButton(
                  context,
                  Icons.thumb_up_outlined,
                  FormatHelper.formatCount(widget.short.likes),
                  () => context.read<ShortsProviderNew>().toggleLike(widget.short.id),
                  isActive: context.watch<ShortsProviderNew>().isShortLiked(widget.short.id),
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  context,
                  Icons.thumb_down_outlined,
                  'Dislike',
                  () => context.read<ShortsProviderNew>().toggleDislike(widget.short.id),
                  isActive: context.watch<ShortsProviderNew>().isShortDisliked(widget.short.id),
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  context,
                  Icons.comment_outlined,
                  FormatHelper.formatCount(widget.short.commentsCount),
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Comments coming soon!')),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  context,
                  Icons.share_outlined,
                  'Share',
                  () {
                    Share.share(
                      'Check out this short: ${widget.short.title}\n${widget.short.videoUrl}',
                      subject: widget.short.title,
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Channel Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(widget.short.channelAvatar),
                  backgroundColor: Colors.grey[800],
                ),
              ],
            ),
          ),

          // Bottom Info
          Positioned(
            left: 16,
            right: 80,
            bottom: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel Name
                Row(
                  children: [
                    Text(
                      '@${widget.short.channelName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Subscribe'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Title/Description
                Text(
                  widget.short.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.short.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.short.description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Video progress bar (thin line at bottom)
          if (_isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: false,
                colors: const VideoProgressColors(
                  playedColor: Colors.red,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.transparent,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: isActive ? Colors.red : Colors.white,
            size: 32,
          ),
          onPressed: onTap,
          padding: EdgeInsets.zero,
        ),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.red : Colors.white,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}


