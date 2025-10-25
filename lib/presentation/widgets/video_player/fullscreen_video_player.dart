import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../core/utils/video_quality_helper.dart';


class FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onSpeedBoostStart;
  final VoidCallback onSpeedBoostEnd;
  final bool is2xSpeed;
  final String originalVideoUrl;
  final String currentQuality;
  final bool isLooping;
  final double normalSpeed;
  final Function(String) onQualityChanged;
  final Function(bool) onLoopChanged;
  final Function(double) onSpeedChanged;

  const FullScreenVideoPlayer({
    super.key,
    required this.controller,
    required this.onSpeedBoostStart,
    required this.onSpeedBoostEnd,
    required this.is2xSpeed,
    required this.originalVideoUrl,
    required this.currentQuality,
    required this.isLooping,
    required this.normalSpeed,
    required this.onQualityChanged,
    required this.onLoopChanged,
    required this.onSpeedChanged,
  });

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  bool _showControls = true;
  bool _localIs2xSpeed = false;
  double _currentSpeed = 1.0;
  double _normalSpeed = 1.0;
  bool _isScreenLocked = false;
  bool _isMuted = false;
  late bool _localIsLooping;

  @override
  void initState() {
    super.initState();
    // Set landscape and hide system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Get initial speed and loop state
    _currentSpeed = widget.controller.value.playbackSpeed;
    _normalSpeed = _currentSpeed;
    _localIsLooping = widget.isLooping;
    
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
  
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      widget.controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _showSpeedSettings() {
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
                        '${widget.controller.value.playbackSpeed}x',
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
                        widget.currentQuality,
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
                      value: _localIsLooping,
                      activeThumbColor: Colors.red,
                      onChanged: (value) {
                        print('🔄 Loop toggle tapped (fullscreen): $value');
                        widget.controller.setLooping(value);
                        widget.onLoopChanged(value);
                        setState(() {
                          _localIsLooping = value;
                        });
                        setModalState(() {
                          _localIsLooping = value;
                        });
                        print('✅ Loop set on controller (fullscreen): $value');
                      },
                    ),
                    
                    // Screen Lock
                    ListTile(
                      leading: const Icon(Icons.lock, color: Colors.white),
                      title: const Text('Lock Screen', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Prevent accidental touches', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _isScreenLocked = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Screen locked. Tap the lock icon to unlock.'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    
                    // Sleep Timer
                    ListTile(
                      leading: const Icon(Icons.bedtime, color: Colors.white),
                      title: const Text('Sleep Timer', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Auto-pause after set time', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
  
  void _showSleepTimerMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sleep Timer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...[5, 10, 15, 30, 45, 60].map((minutes) {
                    return ListTile(
                      leading: const Icon(Icons.timer, color: Colors.white),
                      title: Text(
                        '$minutes minutes',
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _setSleepTimer(minutes);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _setSleepTimer(int minutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Video will pause in $minutes minutes'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Cancel',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
    
    Future.delayed(Duration(minutes: minutes), () {
      if (mounted && widget.controller.value.isPlaying) {
        widget.controller.pause();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sleep timer ended - Video paused'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
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
                      final isSelected = _currentSpeed == speed;
                      return InkWell(
                        onTap: () {
                          widget.controller.setPlaybackSpeed(speed);
                          widget.onSpeedChanged(speed);
                          setState(() {
                            _currentSpeed = speed;
                            _normalSpeed = speed;
                          });
                          Navigator.pop(context);
                          print('🎬 FULLSCREEN: Speed set to $speed');
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
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
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
                    final isSelected = widget.currentQuality == quality;
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
                        if (isSelected) {
                          Navigator.pop(context); // Already this quality
                          return;
                        }
                        
                        Navigator.pop(context); // Close quality menu
                        Navigator.pop(context); // Exit fullscreen to avoid controller issues
                        
                        // Change quality in parent (portrait mode is safer)
                        widget.onQualityChanged(quality);
                        
                        // Show a helpful message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('Changing to $quality...'),
                              ],
                            ),
                            backgroundColor: Colors.black87,
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'Fullscreen',
                              textColor: Colors.red,
                              onPressed: () {
                                // User can quickly go back to fullscreen
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
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
        onTap: _isScreenLocked ? null : () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        onLongPressStart: _isScreenLocked ? null : (_) {
          print('🎬 FULLSCREEN Long press START');
          _enableLocalSpeedBoost();
        },
        onLongPressEnd: _isScreenLocked ? null : (_) {
          print('🎬 FULLSCREEN Long press END');
          _disableLocalSpeedBoost();
        },
        onLongPressCancel: _isScreenLocked ? null : () {
          print('🎬 FULLSCREEN Long press CANCEL');
          _disableLocalSpeedBoost();
        },
        child: Center(
          child: AspectRatio(
            aspectRatio: widget.controller.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(widget.controller),
                
                // Screen lock indicator (small, top-right)
                if (_isScreenLocked)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
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
                    top: MediaQuery.of(context).padding.top + 16,
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
                                icon: const Icon(Icons.closed_caption, color: Colors.white),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Captions feature coming soon!'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                },
                              ),
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

