import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nil_app/presentation/screens/home_screen.dart';
import '../widgets/image_post_card.dart';

class MixedFeedWidget extends StatefulWidget {
  final Set<String> notInterestedVideos;
  final Set<String> blockedChannels;
  final Function(String) onMarkNotInterested;
  final Function(String) onBlockChannel;

  const MixedFeedWidget({
    super.key,
    required this.notInterestedVideos,
    required this.blockedChannels,
    required this.onMarkNotInterested,
    required this.onBlockChannel,
  });

  @override
  State<MixedFeedWidget> createState() => _MixedFeedWidgetState();
}

class _MixedFeedWidgetState extends State<MixedFeedWidget> {
  List<QueryDocumentSnapshot> _mixedContent = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMixedContent();
  }

  Future<void> _loadMixedContent() async {
    try {
      // Get both videos and image posts
      final videosSnapshot = await FirebaseFirestore.instance
          .collection('videos')
          .orderBy('timestamp', descending: true)
          .get();

      final imagePostsSnapshot = await FirebaseFirestore.instance
          .collection('image_posts')
          .orderBy('timestamp', descending: true)
          .get();

      // Combine and sort by timestamp
      final allContent = <QueryDocumentSnapshot>[];
      
      // Add videos with type marker
      for (final doc in videosSnapshot.docs) {
        allContent.add(doc);
      }
      
      // Add image posts with type marker
      for (final doc in imagePostsSnapshot.docs) {
        allContent.add(doc);
      }

      // Sort by timestamp (newest first)
      allContent.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aTimestamp = aData['timestamp'] as Timestamp?;
        final bTimestamp = bData['timestamp'] as Timestamp?;
        
        if (aTimestamp == null && bTimestamp == null) return 0;
        if (aTimestamp == null) return 1;
        if (bTimestamp == null) return -1;
        
        return bTimestamp.compareTo(aTimestamp);
      });

      // Randomly intersperse content (like YouTube)
      _mixedContent = _randomlyIntersperseContent(allContent);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading mixed content: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<QueryDocumentSnapshot> _randomlyIntersperseContent(List<QueryDocumentSnapshot> content) {
    final List<QueryDocumentSnapshot> result = [];
    final List<QueryDocumentSnapshot> videos = [];
    final List<QueryDocumentSnapshot> imagePosts = [];

    // Separate videos and image posts
    for (final doc in content) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['type'] == 'image_post') {
        imagePosts.add(doc);
      } else {
        videos.add(doc);
      }
    }

    // Randomly intersperse (70% videos, 30% image posts)
    int videoIndex = 0;
    int imagePostIndex = 0;
    
    while (videoIndex < videos.length || imagePostIndex < imagePosts.length) {
      // Add video
      if (videoIndex < videos.length) {
        result.add(videos[videoIndex]);
        videoIndex++;
      }
      
      // Sometimes add another video (70% chance)
      if (videoIndex < videos.length && 
          (imagePostIndex >= imagePosts.length || 
           (DateTime.now().millisecondsSinceEpoch % 100) < 70)) {
        result.add(videos[videoIndex]);
        videoIndex++;
      }
      
      // Add image post
      if (imagePostIndex < imagePosts.length) {
        result.add(imagePosts[imagePostIndex]);
        imagePostIndex++;
      }
    }

    return result;
  }

  bool _shouldShowContent(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;
    final uploadedBy = data['uploadedBy'] ?? '';
    
    // Filter out not interested content
    if (widget.notInterestedVideos.contains(docId)) {
      return false;
    }
    
    // Filter out content from blocked channels
    if (widget.blockedChannels.contains(uploadedBy)) {
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (_mixedContent.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No content yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Filter content based on preferences
    final filteredContent = _mixedContent.where(_shouldShowContent).toList();

    if (filteredContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No content to show',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'All available content is filtered',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredContent.length,
      itemBuilder: (context, index) {
        final doc = filteredContent[index];
        final data = doc.data() as Map<String, dynamic>;
        
        // Determine if it's an image post or video
        if (data['type'] == 'image_post') {
          return ImagePostCard(
            imagePost: doc,
            onMarkNotInterested: () => widget.onMarkNotInterested(doc.id),
            onBlockChannel: () => widget.onBlockChannel(data['uploadedBy'] ?? ''),
          );
        } else {
          return VideoCard(
            video: doc,
            onMarkNotInterested: (videoId) => widget.onMarkNotInterested(videoId),
            onBlockChannel: (channelId) => widget.onBlockChannel(channelId),
          );
        }
      },
    );
  }
}
