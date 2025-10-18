import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/playlist_model.dart';
import 'video_playing_screen.dart';
import 'shorts_screen_new.dart';

class PlaylistViewerScreen extends StatelessWidget {
  final PlaylistModel playlist;

  const PlaylistViewerScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    // Debug: Print playlist contents
    print('=== Playlist "${playlist.name}" ===');
    print('Total items: ${playlist.videoIds.length}');
    print('Video IDs: ${playlist.videoIds}');
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          playlist.name,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Playlist Info Banner (Not clickable - just info!)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.withValues(alpha: 0.3),
                  Colors.grey[900]!,
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.red.withValues(alpha: 0.5),
                  width: 3,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Large centered icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.playlist_play,
                    size: 50,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Playlist name
                Text(
                  playlist.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Description
                if (playlist.description != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      playlist.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[300],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                
                // Video count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Text(
                    '${playlist.videoCount} ${playlist.videoCount == 1 ? 'video' : 'videos'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // "Videos & Shorts" label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '▼ VIDEOS & SHORTS ▼',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Videos List
          Expanded(
            child: playlist.videoIds.isEmpty
                ? const Center(
                    child: Text(
                      'No videos in this playlist',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: playlist.videoIds.length,
                    itemBuilder: (context, index) {
                      final videoId = playlist.videoIds[index];
                      return _buildPlaylistVideoItem(context, videoId, index + 1);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistVideoItem(BuildContext context, String videoId, int index) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchVideoOrShort(videoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            color: Colors.transparent,
            child: SizedBox(height: 86, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))),
          );
        }

        // If item doesn't exist in either collection, skip it (filters out invalid IDs)
        if (!snapshot.hasData || snapshot.data == null) {
          print('Skipping invalid/non-existent item with ID: $videoId');
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;

        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () async {
              print('Tapped on item: ${data['title']} (isShort: ${data['isShort']})');
              try {
                final isShort = data['isShort'] ?? false;
                
                if (isShort) {
                  // Navigate to shorts screen
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShortsScreen(),
                      ),
                    );
                  }
                } else {
                  // Fetch as QueryDocumentSnapshot for VideoPlayerScreen
                  final videoQuery = await FirebaseFirestore.instance
                      .collection('videos')
                      .where(FieldPath.documentId, isEqualTo: videoId)
                      .limit(1)
                      .get();
                  
                  if (videoQuery.docs.isNotEmpty) {
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerScreen(video: videoQuery.docs.first),
                        ),
                      );
                    }
                  } else {
                    print('Video not found in query');
                  }
                }
              } catch (e) {
                print('Error loading item: $e');
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Index
                  Container(
                    width: 24,
                    alignment: Alignment.center,
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Thumbnail with Play Overlay and Short Badge
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: data['thumbnailUrl'] ?? '',
                          width: 120,
                          height: 70,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.error, color: Colors.grey),
                          ),
                        ),
                      ),
                      // Play button overlay
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      // Short badge (top-left)
                      if (data['isShort'] == true)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SHORT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Video Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? 'Untitled',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data['channelName'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[600],
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to fetch from both videos and shorts collections
  Future<Map<String, dynamic>?> _fetchVideoOrShort(String id) async {
    try {
      print('Fetching item with ID: $id');
      
      // Try videos collection first
      final videoDoc = await FirebaseFirestore.instance.collection('videos').doc(id).get();
      if (videoDoc.exists) {
        final data = videoDoc.data() as Map<String, dynamic>;
        data['isShort'] = false;
        data['documentId'] = id;
        print('  ✓ Found VIDEO: ${data['title']}');
        return data;
      }

      // Try shorts collection
      final shortDoc = await FirebaseFirestore.instance.collection('shorts').doc(id).get();
      if (shortDoc.exists) {
        final data = shortDoc.data() as Map<String, dynamic>;
        data['isShort'] = true;
        data['documentId'] = id;
        print('  ✓ Found SHORT: ${data['title']}');
        return data;
      }

      print('  ✗ Item not found in videos or shorts collection!');
      return null;
    } catch (e) {
      print('  ✗ Error fetching video/short: $e');
      return null;
    }
  }
}

