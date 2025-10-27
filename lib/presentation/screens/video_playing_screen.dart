import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../data/models/video_model.dart';
import '../providers/video_provider.dart';
import '../widgets/video_player/video_player_widget.dart';
import '../widgets/video_player/video_info_widget.dart';
import '../widgets/video_player/action_buttons_widget.dart';
import '../widgets/video_player/channel_info_widget.dart';
import '../widgets/video_player/description_widget.dart';
import '../widgets/comments/comments_preview_widget.dart';
import '../widgets/video_player/related_videos_widget.dart';

class VideoPlayerScreen extends StatefulWidget {
  final DocumentSnapshot video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with TickerProviderStateMixin {
  VideoModel? _videoModel;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideo();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeVideo() async {
    _videoModel = VideoModel.fromFirestore(widget.video);
    await context.read<VideoProvider>().initializeVideo(widget.video);
    setState(() {});
  }


  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoModel == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.red,
            strokeWidth: 3,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                slivers: [
                  // Video Player
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        VideoPlayerWidget(
                          videoUrl: _videoModel!.videoUrl,
                          videoId: _videoModel!.id,
                          title: _videoModel!.title,
                          thumbnailUrl: _videoModel!.thumbnailUrl,
                          channelName: _videoModel!.channelName,
                          channelAvatar: _videoModel!.channelAvatar,
                        ),
                        
                        // Back Button
                        Positioned(
                          top: 40,
                          left: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Content
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Video Title and Info
                        VideoInfoWidget(
                          videoId: _videoModel!.id,
                          title: _videoModel!.title,
                          views: _videoModel!.views,
                          timestamp: _videoModel!.timestamp,
                        ),

                        // Description
                        DescriptionWidget(
                          description: _videoModel!.description,
                          likes: _videoModel!.likes,
                          views: _videoModel!.views,
                          timestamp: _videoModel!.timestamp,
                        ),

                        // Action Buttons
                        ActionButtonsWidget(
                          videoId: _videoModel!.id,
                          initialLikes: _videoModel!.likes,
                          videoTitle: _videoModel!.title,
                          videoUrl: _videoModel!.videoUrl,
                        ),

                        const Divider(height: 32, thickness: 1),

                        // Channel Info
                        ChannelInfoWidget(
                          channelName: _videoModel!.channelName,
                          channelAvatar: _videoModel!.channelAvatar,
                          subscribers: _videoModel!.subscribers,
                          channelId: _videoModel!.uploadedBy,
                        ),

                        const SizedBox(height: 16),

                        Divider(
                          height: 1,
                          thickness: 8,
                          color: Colors.grey[900],
                        ),

                        // Comments Section
                        CommentsPreviewWidget(
                          videoId: _videoModel!.id,
                          videoOwnerId: _videoModel!.uploadedBy ?? '',
                        ),

                        const Divider(
                          height: 1,
                          thickness: 8,
                          color: Color(0xFFF5F5F5),
                        ),

                        // Related Videos
                        RelatedVideosWidget(currentVideoId: _videoModel!.id),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

