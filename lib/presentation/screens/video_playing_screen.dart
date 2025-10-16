import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../data/models/video_model.dart';
import '../../core/constants/app_constants.dart';
import '../providers/video_provider.dart';
import '../widgets/video_player/video_player_widget.dart';
import '../widgets/video_player/video_info_widget.dart';
import '../widgets/video_player/action_buttons_widget.dart';
import '../widgets/video_player/channel_info_widget.dart';
import '../widgets/video_player/description_widget.dart';
import '../widgets/comments/comments_preview_widget.dart';
import '../widgets/video_player/related_videos_widget.dart';

class VideoPlayerScreen extends StatefulWidget {
  final QueryDocumentSnapshot video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoModel? _videoModel;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoModel = VideoModel.fromFirestore(widget.video);
    await context.read<VideoProvider>().initializeVideo(widget.video);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_videoModel == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppConstants.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Video Player
          SliverToBoxAdapter(
            child: VideoPlayerWidget(videoUrl: _videoModel!.videoUrl),
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

                // Action Buttons (Like, Dislike, Share, etc.)
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
                ),

                // Description
                DescriptionWidget(description: _videoModel!.description),

                const Divider(
                  height: 1,
                  thickness: 8,
                  color: Color(0xFFF5F5F5),
                ),

                // Comments Section (Collapsed)
                CommentsPreviewWidget(videoId: _videoModel!.id),

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
    );
  }
}

