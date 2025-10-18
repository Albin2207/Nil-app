import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:chewie/chewie.dart';
import '../providers/download_provider.dart';
import '../providers/playlist_provider.dart';
import '../../data/models/downloaded_video.dart';
import '../../data/models/playlist_model.dart';
import 'playlist_viewer_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DownloadProvider>().loadDownloads();
        context.read<PlaylistProvider>().loadPlaylists();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Library',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          labelColor: Colors.red,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Downloads'),
            Tab(text: 'Playlists'),
          ],
        ),
        actions: [
          Consumer<DownloadProvider>(
            builder: (context, provider, child) {
              return FutureBuilder<String>(
                future: provider.getTotalStorageUsed(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          snapshot.data!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDownloadsTab(),
          _buildPlaylistsTab(),
        ],
      ),
    );
  }

  Widget _buildDownloadsTab() {
    return Consumer<DownloadProvider>(
      builder: (context, provider, child) {
        if (provider.downloads.isEmpty) {
          return _buildEmptyState(
            icon: Icons.download_outlined,
            title: 'No Downloads Yet',
            subtitle: 'Download videos to watch offline',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: provider.downloads.length,
          itemBuilder: (context, index) {
            final download = provider.downloads[index];
            return _buildDownloadItem(download, provider);
          },
        );
      },
    );
  }

  Widget _buildPlaylistsTab() {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Create Playlist Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _showCreatePlaylistDialog(provider),
                icon: const Icon(Icons.add),
                label: const Text('Create Playlist'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Playlists List
            Expanded(
              child: provider.playlists.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.playlist_play,
                      title: 'No Playlists Yet',
                      subtitle: 'Create playlists to organize your videos',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = provider.playlists[index];
                        return _buildPlaylistItem(playlist, provider);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDownloadItem(DownloadedVideo download, DownloadProvider provider) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Play downloaded video locally
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _LocalVideoPlayerScreen(
                download: download,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: download.thumbnailUrl,
                  width: 120,
                  height: 70,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      download.title,
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
                      download.channelName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            download.quality,
                            style: const TextStyle(
                              fontSize: 10,
            color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          download.formattedSize,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeleteDialog(download, provider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistItem(PlaylistModel playlist, PlaylistProvider provider) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () {
          // Navigate to playlist viewer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistViewerScreen(playlist: playlist),
            ),
          );
        },
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.playlist_play, color: Colors.red, size: 32),
        ),
        title: Text(
          playlist.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (playlist.description != null) ...[
              const SizedBox(height: 4),
              Text(
                playlist.description!,
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              '${playlist.videoCount} videos',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _showDeletePlaylistDialog(playlist, provider);
            } else if (value == 'edit') {
              _showEditPlaylistDialog(playlist, provider);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: Colors.red),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(DownloadedVideo download, DownloadProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Download?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${download.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteDownload(download.videoId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(PlaylistProvider provider) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Create Playlist', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Name *',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await provider.createPlaylist(
                  name: nameController.text.trim(),
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Playlist created'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditPlaylistDialog(PlaylistModel playlist, PlaylistProvider provider) {
    final nameController = TextEditingController(text: playlist.name);
    final descController = TextEditingController(text: playlist.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Edit Playlist', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () {
              playlist.name = nameController.text.trim();
              playlist.description = descController.text.trim().isEmpty
                  ? null
                  : descController.text.trim();
              provider.updatePlaylist(playlist);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeletePlaylistDialog(PlaylistModel playlist, PlaylistProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Playlist?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deletePlaylist(playlist.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Local Video Player for downloaded videos
class _LocalVideoPlayerScreen extends StatefulWidget {
  final DownloadedVideo download;

  const _LocalVideoPlayerScreen({required this.download});

  @override
  State<_LocalVideoPlayerScreen> createState() => _LocalVideoPlayerScreenState();
}

class _LocalVideoPlayerScreenState extends State<_LocalVideoPlayerScreen> {
  late vp.VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = vp.VideoPlayerController.file(File(widget.download.localPath));
    await _videoPlayerController.initialize();
    
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      aspectRatio: 16 / 9,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.red,
        handleColor: Colors.red,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.white70,
      ),
    );

    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isInitialized && _chewieController != null
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Chewie(controller: _chewieController!),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.download.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.download.channelName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.download_done, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Downloaded • ${widget.download.quality} • ${widget.download.formattedSize}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.download.description.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            widget.download.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.red),
      ),
    );
  }
}
