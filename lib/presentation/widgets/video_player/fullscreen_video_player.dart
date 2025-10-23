import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onSpeedBoostStart;
  final VoidCallback onSpeedBoostEnd;
  final bool is2xSpeed;

  const FullScreenVideoPlayer({
    super.key,
    required this.controller,
    required this.onSpeedBoostStart,
    required this.onSpeedBoostEnd,
    required this.is2xSpeed,
  });

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  bool _showControls = true;
  bool _localIs2xSpeed = false;
  double _currentSpeed = 1.0;
  double _normalSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    // Set landscape and hide system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Get initial speed
    _currentSpeed = widget.controller.value.playbackSpeed;
    _normalSpeed = _currentSpeed;
    
    // Listen to controller to update UI
    widget.controller.addListener(() {
      if (mounted) {
        setState(() {
          _currentSpeed = widget.controller.value.playbackSpeed;
        });
      }
    });
  }
  
  void _enableLocalSpeedBoost() {
    if (!_localIs2xSpeed) {
      _normalSpeed = widget.controller.value.playbackSpeed;
      widget.onSpeedBoostStart();
      setState(() {
        _localIs2xSpeed = true;
      });
      print('🎬 FULLSCREEN: Saved speed $_normalSpeed, boosting to 2x');
    }
  }
  
  void _disableLocalSpeedBoost() {
    if (_localIs2xSpeed) {
      widget.onSpeedBoostEnd();
      setState(() {
        _localIs2xSpeed = false;
      });
      print('🎬 FULLSCREEN: Restored to $_normalSpeed');
    }
  }

  void _skipForward() {
    final currentPosition = widget.controller.value.position;
    final newPosition = currentPosition + const Duration(seconds: 10);
    final maxDuration = widget.controller.value.duration;
    
    if (newPosition < maxDuration) {
      widget.controller.seekTo(newPosition);
    } else {
      widget.controller.seekTo(maxDuration);
    }
  }

  void _skipBackward() {
    final currentPosition = widget.controller.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    
    if (newPosition > Duration.zero) {
      widget.controller.seekTo(newPosition);
    } else {
      widget.controller.seekTo(Duration.zero);
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
                      final isSelected = _currentSpeed == speed;
                      return InkWell(
                        onTap: () {
                          widget.controller.setPlaybackSpeed(speed);
                          setState(() {
                            _currentSpeed = speed;
                            _normalSpeed = speed; // Save as the new normal speed
                          });
                          Navigator.pop(context);
                          print('🎬 Speed set to $speed, saved as normal speed');
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

  @override
  void dispose() {
    // Restore portrait and system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        onLongPressStart: (_) {
          print('🎬 FULLSCREEN Long press START');
          _enableLocalSpeedBoost();
        },
        onLongPressEnd: (_) {
          print('🎬 FULLSCREEN Long press END');
          _disableLocalSpeedBoost();
        },
        onLongPressCancel: () {
          print('🎬 FULLSCREEN Long press CANCEL');
          _disableLocalSpeedBoost();
        },
        child: Center(
          child: AspectRatio(
            aspectRatio: widget.controller.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(widget.controller),
                
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
                        // Top bar with back button and settings
                        SafeArea(
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.settings, color: Colors.white),
                                onPressed: _showSpeedSettings,
                              ),
                            ],
                          ),
                        ),
                        
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
                                  widget.controller.value.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 64,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (widget.controller.value.isPlaying) {
                                      widget.controller.pause();
                                    } else {
                                      widget.controller.play();
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
                        
                        // Bottom progress bar
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Text(
                                  _formatDuration(widget.controller.value.position),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: widget.controller.value.position.inSeconds.toDouble(),
                                    max: widget.controller.value.duration.inSeconds.toDouble(),
                                    activeColor: Colors.red,
                                    inactiveColor: Colors.white30,
                                    onChanged: (value) {
                                      widget.controller.seekTo(Duration(seconds: value.toInt()));
                                    },
                                  ),
                                ),
                                Text(
                                  _formatDuration(widget.controller.value.duration),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // 2x Speed Indicator
                if (_localIs2xSpeed)
                  Positioned(
                    top: 60,
                    left: MediaQuery.of(context).size.width / 2 - 35,
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
                              color: Colors.red.withValues(alpha: 0.6),
                              blurRadius: 10,
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
      ),
    );
  }
}

