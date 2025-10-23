import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../data/models/playlist_model.dart';
import '../../providers/playlist_provider.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/format_utils.dart';
import '../home/video_playing_screen.dart';
import '../shorts/shorts_screen_new.dart';

/// Playlist viewer screen showing videos in a playlist
class PlaylistViewerScreen extends StatefulWidget {
  final PlaylistModel playlist;

  const PlaylistViewerScreen({super.key, required this.playlist});

  @override
  State<PlaylistViewerScreen> createState() => _PlaylistViewerScreenState();
}

class _PlaylistViewerScreenState extends State<PlaylistViewerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.playlist.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildPlaylistHeader(),
          const Divider(color: Colors.grey, height: 1),
          Expanded(child: _buildVideoList()),
        ],
      ),
    );
  }

  Widget _buildPlaylistHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.red.withValues(alpha: 0.3), Colors.grey[900]!],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.red.withValues(alpha: 0.5), width: 3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.playlist_play, size: 50, color: Colors.red),
          ),
          const SizedBox(height: 16),
          Text(
            widget.playlist.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (widget.playlist.description != null)
            Text(
              widget.playlist.description!,
              style: TextStyle(fontSize: 14, color: Colors.grey[300]),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${widget.playlist.videoIds.length} videos',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList() {
    if (widget.playlist.videoIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_add, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'No videos in this playlist',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.playlist.videoIds.length,
      itemBuilder: (context, index) {
        final videoId = widget.playlist.videoIds[index];
        return _buildPlaylistVideoItem(context, videoId, index);
      },
    );
  }

  Widget _buildPlaylistVideoItem(BuildContext context, String videoId, int index) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchVideoOrShort(videoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            color: Colors.transparent,
            child: SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final isShort = data['isShort'] == true;

        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: InkWell(
            onTap: () {
              if (isShort) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShortsScreen()),
                );
              } else {
                // Navigate to video player
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: data['thumbnailUrl'] ?? '',
                      width: 120,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.error, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] ?? 'Untitled',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['channelName'] ?? 'Unknown',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${FormatUtils.formatCount(data['views'] ?? 0)} views',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => _removeFromPlaylist(context, videoId),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchVideoOrShort(String id) async {
    try {
      var doc = await FirebaseFirestore.instance.collection('videos').doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['isShort'] = false;
        return data;
      }

      doc = await FirebaseFirestore.instance.collection('shorts').doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['isShort'] = true;
        return data;
      }

      return null;
    } catch (e) {
      print('Error fetching video/short: $e');
      return null;
    }
  }

  void _removeFromPlaylist(BuildContext context, String videoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Remove from Playlist?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This video will be removed from the playlist.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PlaylistProvider>().removeVideoFromPlaylist(
                    widget.playlist.id,
                    videoId,
                  );
              Navigator.pop(context);
              SnackBarHelper.showSuccess(context, 'Removed from playlist');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

