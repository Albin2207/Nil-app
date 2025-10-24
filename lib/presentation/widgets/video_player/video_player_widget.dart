import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/utils/video_quality_helper.dart';
import '../../../core/services/watch_history_service.dart';
import 'fullscreen_video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? videoId;
  final String? title;
  final String? thumbnailUrl;
  final String? channelName;
  final String? channelAvatar;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.videoId,
    this.title,
    this.thumbnailUrl,
    this.channelName,
    this.channelAvatar,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _is2xSpeed = false;
  double _normalSpeed = 1.0;
  bool _showControls = true;
  String _currentQuality = VideoQuality.auto;
  String _originalVideoUrl = '';
  bool _isLooping = false;
  bool _isScreenLocked = false;
  bool _isMuted = false;
  bool _hasTrackedWatchHistory = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _originalVideoUrl = widget.videoUrl;
    
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(VideoQualityHelper.getQualityUrl(_originalVideoUrl, _currentQuality)),
    );
    
    _controller.initialize().then((_) {
      setState(() {
        _isInitialized = true;
      });
      _controller.setLooping(_isLooping); // Set loop mode
      _controller.play(); // Auto-play
    });

    _controller.addListener(() {
      setState(() {});
      _trackWatchHistory();
    });
  }

  Future<void> _changeQuality(String quality) async {
    if (quality == _currentQuality) return;
    
    // Save current position and playing state
    final currentPosition = _controller.value.position;
    final wasPlaying = _controller.value.isPlaying;
    final currentSpeed = _controller.value.playbackSpeed;
    
    // Dispose old controller
    await _controller.dispose();
    
    // Create new controller with quality URL
    _currentQuality = quality;
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(VideoQualityHelper.getQualityUrl(_originalVideoUrl, quality)),
    );
    
    await _controller.initialize();
    
    // IMPORTANT: Re-add listener to keep UI updating
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    
    // Restore all states
    _controller.setLooping(_isLooping);
    _controller.setPlaybackSpeed(currentSpeed);
    _controller.setVolume(_isMuted ? 0.0 : 1.0);
    
    // Restore position and state
    await _controller.seekTo(currentPosition);
    if (wasPlaying) {
      await _controller.play();
    }
    
    // Force rebuild to update aspect ratio
    if (mounted) {
      setState(() {});
    }
    
    print('🎬 Quality changed to $quality');
  }

  void _enableSpeedBoost() {
    if (!_is2xSpeed) {
      _normalSpeed = _controller.value.playbackSpeed; // Save current speed
      _controller.setPlaybackSpeed(2.0);
      setState(() {
        _is2xSpeed = true;
      });
      print('🎬 Speed boost ON - saved normal speed: $_normalSpeed');
    }
  }

  void _disableSpeedBoost() {
    if (_is2xSpeed) {
      _controller.setPlaybackSpeed(_normalSpeed); // Restore saved speed
      setState(() {
        _is2xSpeed = false;
      });
      print('🎬 Speed boost OFF - restored to: $_normalSpeed');
    }
  }
  
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _skipForward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition + const Duration(seconds: 10);
    final maxDuration = _controller.value.duration;
    
    if (newPosition < maxDuration) {
      _controller.seekTo(newPosition);
    } else {
      _controller.seekTo(maxDuration);
    }
  }

  void _skipBackward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    
    if (newPosition > Duration.zero) {
      _controller.seekTo(newPosition);
    } else {
      _controller.seekTo(Duration.zero);
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Header
                    const Text(
                      'Video Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Playback Speed
                    ListTile(
                      leading: const Icon(Icons.speed, color: Colors.white),
                      title: const Text('Playback Speed', style: TextStyle(color: Colors.white)),
                      trailing: Text(
                        '${_controller.value.playbackSpeed}x',
                        style: const TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showSpeedMenu();
                      },
                    ),
                    
                    // Quality
                    ListTile(
                      leading: const Icon(Icons.high_quality, color: Colors.white),
                      title: const Text('Quality', style: TextStyle(color: Colors.white)),
                      trailing: Text(
                        _currentQuality,
                        style: const TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showQualityMenu();
                      },
                    ),
                    
                    // Loop Video
                    SwitchListTile(
                      secondary: const Icon(Icons.repeat, color: Colors.white),
                      title: const Text('Loop Video', style: TextStyle(color: Colors.white)),
                      value: _isLooping,
                      activeColor: Colors.red,
                      onChanged: (value) {
                        print('🔄 Loop toggle tapped (portrait): $value');
                        setModalState(() {
                          _isLooping = value;
                        });
                        setState(() {
                          _isLooping = value;
                          _controller.setLooping(value);
                        });
                        print('✅ Loop set on controller: $value');
                      },
                    ),
                    
                    // Screen Lock
                    SwitchListTile(
                      secondary: const Icon(Icons.lock, color: Colors.white),
                      title: const Text('Lock Screen', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Prevent accidental touches', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      value: _isScreenLocked,
                      activeColor: Colors.red,
                      onChanged: (value) {
                        setModalState(() {
                          _isScreenLocked = value;
                        });
                        setState(() {
                          _isScreenLocked = value;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    
                    // Sleep Timer
                    ListTile(
                      leading: const Icon(Icons.timer, color: Colors.white),
                      title: const Text('Sleep Timer', style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        Navigator.pop(context);
                        _showSleepTimerMenu();
                      },
                    ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSpeedMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Playback Speed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0, 4.0, 5.0].map((speed) {
                      final isSelected = _controller.value.playbackSpeed == speed;
                      return InkWell(
                        onTap: () {
                          _controller.setPlaybackSpeed(speed);
                          Navigator.pop(context);
                          setState(() {
                            _normalSpeed = speed;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.red : Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${speed}x',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQualityMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Video Quality',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...VideoQuality.allQualities.map((quality) {
                final isSelected = _currentQuality == quality;
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? Colors.red : Colors.white,
                  ),
                  title: Text(
                    VideoQualityHelper.getQualityLabel(quality),
                    style: TextStyle(
                      color: isSelected ? Colors.red : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _changeQuality(quality);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showSleepTimerMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Sleep Timer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.timer, color: Colors.white),
                title: const Text('15 minutes', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _setSleepTimer(15);
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer, color: Colors.white),
                title: const Text('30 minutes', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _setSleepTimer(30);
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer, color: Colors.white),
                title: const Text('1 hour', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _setSleepTimer(60);
                },
              ),
              ListTile(
                leading: const Icon(Icons.stop_circle, color: Colors.white),
                title: const Text('End of video', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _setSleepTimer(-1); // Special: pause at end
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _setSleepTimer(int minutes) {
    if (minutes == -1) {
      // Pause at end of video
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video will pause at the end'),
          backgroundColor: Colors.red,
        ),
      );
      // Will be handled by controller listener
    } else {
      Future.delayed(Duration(minutes: minutes), () {
        if (mounted && _controller.value.isPlaying) {
          _controller.pause();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sleep timer ended - Video paused'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sleep timer set for $minutes minutes'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenVideoPlayer(
          controller: _controller,
          onSpeedBoostStart: _enableSpeedBoost,
          onSpeedBoostEnd: _disableSpeedBoost,
          is2xSpeed: _is2xSpeed,
          originalVideoUrl: _originalVideoUrl,
          currentQuality: _currentQuality,
          isLooping: _isLooping,
          normalSpeed: _normalSpeed,
          onQualityChanged: (quality) {
            _changeQuality(quality);
          },
          onLoopChanged: (value) {
            setState(() {
              _isLooping = value;
              _controller.setLooping(value);
            });
          },
          onSpeedChanged: (speed) {
            _controller.setPlaybackSpeed(speed);
            setState(() {
              _normalSpeed = speed;
            });
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.red),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _isScreenLocked ? null : () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      onLongPressStart: _isScreenLocked ? null : (_) {
        print('🎬 Long press START');
        _enableSpeedBoost();
      },
      onLongPressEnd: _isScreenLocked ? null : (_) {
        print('🎬 Long press END');
        _disableSpeedBoost();
      },
      onLongPressCancel: _isScreenLocked ? null : () {
        print('🎬 Long press CANCEL');
        _disableSpeedBoost();
      },
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              VideoPlayer(_controller),
              
              // Screen lock indicator (small, top-right)
              if (_isScreenLocked)
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isScreenLocked = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, color: Colors.red, size: 24),
                          SizedBox(height: 4),
                          Text(
                            'Locked',
                            style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Volume/Mute button (top-left)
              if (_showControls && !_isScreenLocked)
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                    ),
                    onPressed: _toggleMute,
                  ),
                ),
              
              // Controls overlay
              if (_showControls && !_isScreenLocked)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(height: 50),
                      
                      // Center controls with skip buttons
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Skip backward 10s
                            IconButton(
                              icon: const Icon(
                                Icons.replay_10,
                                color: Colors.white,
                                size: 48,
                              ),
                              onPressed: _skipBackward,
                            ),
                            
                            const SizedBox(width: 32),
                            
                            // Play/Pause
                            IconButton(
                              icon: Icon(
                                _controller.value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: Colors.white,
                                size: 64,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_controller.value.isPlaying) {
                                    _controller.pause();
                                  } else {
                                    _controller.play();
                                  }
                                });
                              },
                            ),
                            
                            const SizedBox(width: 32),
                            
                            // Skip forward 10s
                            IconButton(
                              icon: const Icon(
                                Icons.forward_10,
                                color: Colors.white,
                                size: 48,
                              ),
                              onPressed: _skipForward,
                            ),
                          ],
                        ),
                      ),
                      
                      // Bottom controls
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Text(
                              _formatDuration(_controller.value.position),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            Expanded(
                              child: Slider(
                                value: _controller.value.position.inSeconds.toDouble(),
                                max: _controller.value.duration.inSeconds.toDouble(),
                                activeColor: Colors.red,
                                inactiveColor: Colors.white30,
                                onChanged: (value) {
                                  _controller.seekTo(Duration(seconds: value.toInt()));
                                },
                              ),
                            ),
                            Text(
                              _formatDuration(_controller.value.duration),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            // Settings button
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                              onPressed: _showSettings,
                            ),
                            // Fullscreen button
                            IconButton(
                              icon: const Icon(Icons.fullscreen, color: Colors.white),
                              onPressed: _openFullscreen,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Captions button (top right, below 2x indicator)
              if (_showControls && !_isScreenLocked)
                Positioned(
                  top: 60,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.closed_caption, color: Colors.white, size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Captions feature coming soon!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                  ),
                ),
              
              // 2x Speed Indicator
              if (_is2xSpeed)
                Positioned(
                  top: 16,
                  right: 16,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fast_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '2x',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _trackWatchHistory() {
    if (!_isInitialized || 
        widget.videoId == null || 
        widget.title == null || 
        widget.thumbnailUrl == null || 
        widget.channelName == null || 
        widget.channelAvatar == null) {
      return;
    }

    final position = _controller.value.position;
    final duration = _controller.value.duration;
    
    // Only track if video has been playing for at least 5 seconds
    if (position.inSeconds >= 5) {
      if (!_hasTrackedWatchHistory) {
        // First time tracking - add to watch history
        WatchHistoryService.addToWatchHistory(
          contentId: widget.videoId!,
          contentType: 'video',
          title: widget.title!,
          thumbnailUrl: widget.thumbnailUrl!,
          channelName: widget.channelName!,
          channelAvatar: widget.channelAvatar!,
          watchDuration: position,
          totalDuration: duration,
        );
        _hasTrackedWatchHistory = true;
      } else {
        // Update existing watch history
        WatchHistoryService.updateWatchProgress(
          contentId: widget.videoId!,
          watchDuration: position,
          totalDuration: duration,
        );
      }
    }
  }
}
