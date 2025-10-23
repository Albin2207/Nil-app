import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'fullscreen_video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
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

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    
    _controller.initialize().then((_) {
      setState(() {
        _isInitialized = true;
      });
      _controller.play(); // Auto-play
    });

    _controller.addListener(() {
      setState(() {});
    });
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

  void _showSpeedSettings() {
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

  void _openFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenVideoPlayer(
          controller: _controller,
          onSpeedBoostStart: _enableSpeedBoost,
          onSpeedBoostEnd: _disableSpeedBoost,
          is2xSpeed: _is2xSpeed,
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
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      onLongPressStart: (_) {
        print('🎬 Long press START');
        _enableSpeedBoost();
      },
      onLongPressEnd: (_) {
        print('🎬 Long press END');
        _disableSpeedBoost();
      },
      onLongPressCancel: () {
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
              
              // Controls overlay
              if (_showControls)
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
                              onPressed: _showSpeedSettings,
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
}
