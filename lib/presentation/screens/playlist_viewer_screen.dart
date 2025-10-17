import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/playlist_model.dart';
import 'video_playing_screen.dart';

class PlaylistViewerScreen extends StatelessWidget {
  final PlaylistModel playlist;

  const PlaylistViewerScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
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
          // Playlist Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.playlist_play,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (playlist.description != null)
                        Text(
                          playlist.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${playlist.videoCount} videos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('videos').doc(videoId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final video = snapshot.data!;
        final data = video.data() as Map<String, dynamic>;

        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () async {
              // Fetch as QueryDocumentSnapshot for VideoPlayerScreen
              final videoQuery = await FirebaseFirestore.instance
                  .collection('videos')
                  .where(FieldPath.documentId, isEqualTo: videoId)
                  .limit(1)
                  .get();
              
              if (videoQuery.docs.isNotEmpty && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(video: videoQuery.docs.first),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // Index
                  Container(
                    width: 30,
                    alignment: Alignment.center,
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Thumbnail
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.error, color: Colors.grey),
                      ),
                    ),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['channelName'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Play Icon
                  const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

