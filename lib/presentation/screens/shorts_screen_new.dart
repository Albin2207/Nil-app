import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/short_video_model.dart';
import '../providers/shorts_provider_new.dart';
import '../providers/download_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/utils/format_helper.dart';
import '../../core/utils/snackbar_helper.dart';
import '../widgets/shorts/short_comments_sheet.dart';
import '../widgets/common/offline_widget.dart';
import 'creator_profile_screen.dart';

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
    _pageController = PageController(
      initialPage: 0,
      keepPage: true,
      viewportFraction: 1.0,
    );
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
    final connectivityService = context.watch<ConnectivityService>();
    
    // Show offline widget if no connection
    if (!connectivityService.isOnline) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: OfflineWidget(
          message: 'Connect to the internet to watch shorts',
          onRetry: () async {
            await connectivityService.refresh();
            if (mounted) setState(() {});
          },
        ),
      );
    }
    
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
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
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

class _ShortVideoPlayerState extends State<ShortVideoPlayer> with SingleTickerProviderStateMixin {
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
      _controller.setVolume(1.0);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        if (widget.isCurrentPage) {
          await _controller.play();
          _incrementViews();
        }
      }

      // Minimal state updates for smoother performance
      _controller.addListener(() {
        if (mounted && _controller.value.hasError) {
          setState(() {});
        }
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
      // This short became visible - play from where it was paused
      _controller.play();
      if (!_hasIncrementedView) {
        _incrementViews();
      }
    } else if (!widget.isCurrentPage && oldWidget.isCurrentPage) {
      // This short is no longer visible - just pause, don't reset
      _controller.pause();
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
        _showPlayPauseIconWithAnimation(isPause: true);
      } else {
        _controller.play();
        _showPlayPauseIconWithAnimation(isPause: false);
      }
    });
  }

  void _showPlayPauseIconWithAnimation({required bool isPause}) {
    setState(() {
      _showPlayPauseIcon = true;
    });
    
    _playPauseController.forward(from: 0.0);
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showPlayPauseIcon = false;
        });
      }
    });
  }

  void _openCommentsSheet(BuildContext context) {
    // Pause video when opening comments
    if (_controller.value.isPlaying) {
      _controller.pause();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      transitionAnimationController: null,
      builder: (context) => ShortCommentsSheet(
        shortId: widget.short.id,
        commentsCount: widget.short.commentsCount,
        videoOwnerId: widget.short.uploadedBy ?? '',
      ),
    ).then((_) {
      // Resume video when closing comments (only if this is the current page)
      if (widget.isCurrentPage && mounted) {
        _controller.play();
      }
    });
  }

  @override
  void dispose() {
    _playPauseController.dispose();
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
            RepaintBoundary(
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
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
            bottom: 80,
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
                  () => _openCommentsSheet(context),
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
                // Download button
                Consumer<DownloadProvider>(
                  builder: (context, downloadProvider, child) {
                    return FutureBuilder<bool>(
                      future: downloadProvider.isVideoDownloaded(widget.short.id),
                      builder: (context, snapshot) {
                        final isDownloaded = snapshot.data ?? false;
                        return _buildActionButton(
                          context,
                          isDownloaded ? Icons.download_done : Icons.download_outlined,
                          isDownloaded ? 'Saved' : 'Save',
                          isDownloaded
                              ? () {
                                  SnackBarHelper.showSuccess(
                                    context,
                                    'Already downloaded',
                                    icon: Icons.download_done,
                                  );
                                }
                              : () => _showShortQualityPicker(context),
                          isActive: isDownloaded,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Save to playlist button
                _buildActionButton(
                  context,
                  Icons.playlist_add,
                  'Playlist',
                  () => _showShortPlaylistPicker(context),
                ),
                const SizedBox(height: 24),
                // More/Settings button
                _buildActionButton(
                  context,
                  Icons.more_vert,
                  'More',
                  () => _showShortsSettings(context),
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
                    InkWell(
                      onTap: widget.short.uploadedBy != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreatorProfileScreen(
                                    creatorId: widget.short.uploadedBy!,
                                    creatorName: widget.short.channelName,
                                    creatorAvatar: widget.short.channelAvatar,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Text(
                        '@${widget.short.channelName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Consumer2<AuthProvider, SubscriptionProvider>(
                      builder: (context, authProvider, subscriptionProvider, child) {
                        final currentUserId = authProvider.firebaseUser?.uid;
                        final isOwnContent = currentUserId == widget.short.uploadedBy;
                        final isSubscribed = widget.short.uploadedBy != null
                            ? subscriptionProvider.isSubscribed(widget.short.uploadedBy!)
                            : false;

                        // Don't show subscribe button if it's user's own content or not logged in
                        if (isOwnContent || currentUserId == null || widget.short.uploadedBy == null) {
                          return const SizedBox.shrink();
                        }

                        return OutlinedButton(
                          onPressed: () async {
                            print('🎬 Subscribe button pressed - isSubscribed: $isSubscribed');
                            print('🎬 currentUserId: $currentUserId');
                            print('🎬 channelId: ${widget.short.uploadedBy}');
                            
                            if (isSubscribed) {
                              print('🎬 Calling unsubscribe...');
                              final success = await subscriptionProvider.unsubscribe(
                                userId: currentUserId,
                                channelId: widget.short.uploadedBy!,
                              );
                              
                              print('🎬 Unsubscribe result: $success');
                              
                              if (context.mounted) {
                                if (success) {
                                  SnackBarHelper.showInfo(
                                    context,
                                    'Unsubscribed',
                                    icon: Icons.notifications_off,
                                    color: Colors.orange,
                                  );
                                } else {
                                  SnackBarHelper.showError(
                                    context,
                                    'Failed to unsubscribe',
                                    icon: Icons.error_outline,
                                  );
                                }
                              }
                            } else {
                              print('🎬 Calling subscribe...');
                              final success = await subscriptionProvider.subscribe(
                                userId: currentUserId,
                                channelId: widget.short.uploadedBy!,
                                channelName: widget.short.channelName,
                                channelAvatar: widget.short.channelAvatar,
                              );
                              
                              print('🎬 Subscribe result: $success');
                              
                              if (context.mounted) {
                                if (success) {
                                  SnackBarHelper.showSuccess(
                                    context,
                                    'Subscribed to ${widget.short.channelName}',
                                    icon: Icons.notifications_active,
                                  );
                                } else {
                                  SnackBarHelper.showError(
                                    context,
                                    'Failed to subscribe. Check console for details.',
                                    icon: Icons.error_outline,
                                  );
                                }
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isSubscribed ? Colors.grey[300] : Colors.white,
                            backgroundColor: isSubscribed 
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.transparent,
                            side: BorderSide(
                              color: isSubscribed ? Colors.grey[300]! : Colors.white,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: Text(isSubscribed ? 'Subscribed' : 'Subscribe'),
                        );
                      },
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

          // Play/Pause Icon Overlay with Animation
          if (_showPlayPauseIcon)
            Center(
              child: AnimatedBuilder(
                animation: _playPauseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.5 + (_playPauseAnimation.value * 0.5),
                    child: Opacity(
                      opacity: 1.0 - _playPauseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          _controller.value.isPlaying ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                  );
                },
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

  void _showShortQualityPicker(BuildContext context) {
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),
            _QualityTile('360p', 'Small (~10 MB)', () => _startShortDownload(context, '360p')),
            _QualityTile('720p', 'Medium (~25 MB)', () => _startShortDownload(context, '720p'), recommended: true),
            _QualityTile('1080p', 'Large (~50 MB)', () => _startShortDownload(context, '1080p')),
          ],
        ),
      ),
    );
  }

  Future<void> _startShortDownload(BuildContext context, String quality) async {
    Navigator.pop(context);
    
    final downloadProvider = context.read<DownloadProvider>();
    if (await downloadProvider.isVideoDownloaded(widget.short.id)) {
      if (context.mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Already downloaded',
          icon: Icons.download_done,
        );
      }
      return;
    }

    // Show downloading progress dialog
    if (context.mounted) {
      _showDownloadProgressDialog(context, quality);
    }

    final success = await downloadProvider.downloadVideo(
      videoId: widget.short.id,
      videoUrl: widget.short.videoUrl,
      title: widget.short.title,
      thumbnailUrl: widget.short.thumbnailUrl,
      quality: quality,
      isShort: true,
      channelName: widget.short.channelName,
      description: widget.short.description,
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
            
            print('🎨 Short Dialog UI update: progress=${(progress * 100).toInt()}%, isDownloading=$isDownloading');
            
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
                    'Short downloaded successfully!',
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
                      progress > 0 ? 'Downloading Short...' : 'Preparing download...',
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

  void _showShortPlaylistPicker(BuildContext context) async {
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
            const Text(
              'Save to Playlist',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Consumer<PlaylistProvider>(
              builder: (context, provider, child) {
                if (provider.playlists.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No playlists yet.\nCreate one in Library tab.',
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
                    final isInPlaylist = playlist.videoIds.contains(widget.short.id);
                    
                    return ListTile(
                      leading: Icon(
                        Icons.playlist_play,
                        color: isInPlaylist ? Colors.red : Colors.grey,
                      ),
                      title: Text(
                        playlist.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: isInPlaylist
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () async {
                        Navigator.pop(context); // Close bottom sheet first
                        
                        if (isInPlaylist) {
                          await provider.removeVideoFromPlaylist(playlist.id, widget.short.id);
                          if (context.mounted) {
                            SnackBarHelper.showInfo(
                              context,
                              'Removed from playlist',
                              icon: Icons.playlist_remove,
                              color: Colors.orange,
                            );
                          }
                        } else {
                          await provider.addVideoToPlaylist(playlist.id, widget.short.id);
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

  void _showShortsSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'More Options',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description
                ListTile(
                  leading: const Icon(Icons.description, color: Colors.white),
                  title: const Text('Description', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(context);
                    _showDescription(context);
                  },
                ),
                
                // Captions
                ListTile(
                  leading: const Icon(Icons.closed_caption, color: Colors.white),
                  title: const Text('Captions', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(context);
                    SnackBarHelper.showInfo(context, 'Captions coming soon!', icon: Icons.info);
                  },
                ),
                
                // Quality
                ListTile(
                  leading: const Icon(Icons.high_quality, color: Colors.white),
                  title: const Text('Quality', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(context);
                    SnackBarHelper.showInfo(context, 'Quality settings coming soon!', icon: Icons.info);
                  },
                ),
                
                const Divider(color: Colors.grey),
                
                // Not Interested
                ListTile(
                  leading: const Icon(Icons.not_interested, color: Colors.white),
                  title: const Text('Not Interested', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    SnackBarHelper.showSuccess(context, 'We\'ll show you fewer shorts like this', icon: Icons.check);
                  },
                ),
                
                // Don't Recommend Channel
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.white),
                  title: const Text('Don\'t Recommend Channel', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _showConfirmDontRecommend(context);
                  },
                ),
                
                // Report
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.white),
                  title: const Text('Report', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(context);
                    _showReportOptions(context);
                  },
                ),
                
                // Send Feedback
                ListTile(
                  leading: const Icon(Icons.feedback, color: Colors.white),
                  title: const Text('Send Feedback', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/feedback');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDescription(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Text(
                    widget.short.description.isEmpty 
                        ? 'No description provided.' 
                        : widget.short.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmDontRecommend(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Don\'t Recommend Channel?', style: TextStyle(color: Colors.white)),
          content: Text(
            'You won\'t see shorts from ${widget.short.channelName} anymore.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                SnackBarHelper.showSuccess(
                  context,
                  'Channel blocked from recommendations',
                  icon: Icons.block,
                );
              },
              child: const Text('Confirm', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showReportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report Short',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _ReportTile(
                icon: Icons.copyright,
                title: 'Copyright Violation',
                onTap: () => _submitReport(context, 'Copyright Violation'),
              ),
              _ReportTile(
                icon: Icons.warning,
                title: 'Inappropriate Content',
                onTap: () => _submitReport(context, 'Inappropriate Content'),
              ),
              _ReportTile(
                icon: Icons.block,
                title: 'Spam or Misleading',
                onTap: () => _submitReport(context, 'Spam or Misleading'),
              ),
              _ReportTile(
                icon: Icons.sentiment_dissatisfied,
                title: 'Hate Speech or Harassment',
                onTap: () => _submitReport(context, 'Hate Speech or Harassment'),
              ),
              _ReportTile(
                icon: Icons.dangerous,
                title: 'Violence or Dangerous Content',
                onTap: () => _submitReport(context, 'Violence or Dangerous Content'),
              ),
              _ReportTile(
                icon: Icons.report_problem,
                title: 'Other',
                onTap: () => _submitReport(context, 'Other'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitReport(BuildContext context, String reason) async {
    Navigator.pop(context);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUserId = authProvider.firebaseUser?.uid;
      
      if (currentUserId == null) {
        SnackBarHelper.showError(context, 'Please log in to report', icon: Icons.error);
        return;
      }
      
      await FirebaseFirestore.instance.collection('reports').add({
        'type': 'short',
        'contentId': widget.short.id,
        'contentTitle': widget.short.title,
        'channelName': widget.short.channelName,
        'reason': reason,
        'reporterId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      
      if (context.mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Report submitted. We\'ll review it soon.',
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(
          context,
          'Failed to submit report',
          icon: Icons.error,
        );
      }
    }
  }
}

class _ReportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ReportTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _QualityTile extends StatelessWidget {
  final String quality;
  final String size;
  final VoidCallback onTap;
  final bool recommended;

  const _QualityTile(this.quality, this.size, this.onTap, {this.recommended = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(color: recommended ? Colors.red : Colors.grey, width: recommended ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.high_quality, color: recommended ? Colors.red : Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(quality, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: recommended ? Colors.red : Colors.white)),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                          child: const Text('Recommended', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(size, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}


