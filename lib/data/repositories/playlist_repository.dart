import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/playlist_model.dart';

class PlaylistRepository {
  static const String _boxName = 'playlists';
  final _uuid = const Uuid();

  Future<Box<PlaylistModel>> _getBox() async {
    return await Hive.openBox<PlaylistModel>(_boxName);
  }

  // Create playlist
  Future<PlaylistModel> createPlaylist({
    required String name,
    String? description,
  }) async {
    final playlist = PlaylistModel(
      id: _uuid.v4(),
      name: name,
      description: description,
      videoIds: [],
      createdDate: DateTime.now(),
    );

    final box = await _getBox();
    await box.put(playlist.id, playlist);
    return playlist;
  }

  // Get all playlists
  Future<List<PlaylistModel>> getAllPlaylists() async {
    final box = await _getBox();
    return box.values.toList();
  }

  // Get playlist by id
  Future<PlaylistModel?> getPlaylist(String id) async {
    final box = await _getBox();
    return box.get(id);
  }

  // Add video to playlist
  Future<void> addVideoToPlaylist(String playlistId, String videoId) async {
    final box = await _getBox();
    final playlist = box.get(playlistId);
    
    if (playlist != null && !playlist.videoIds.contains(videoId)) {
      playlist.videoIds.add(videoId);
      await box.put(playlistId, playlist);
    }
  }

  // Remove video from playlist
  Future<void> removeVideoFromPlaylist(String playlistId, String videoId) async {
    final box = await _getBox();
    final playlist = box.get(playlistId);
    
    if (playlist != null) {
      playlist.videoIds.remove(videoId);
      await box.put(playlistId, playlist);
    }
  }

  // Update playlist
  Future<void> updatePlaylist(PlaylistModel playlist) async {
    final box = await _getBox();
    await box.put(playlist.id, playlist);
  }

  // Delete playlist
  Future<void> deletePlaylist(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  // Check if video is in playlist
  Future<bool> isVideoInPlaylist(String playlistId, String videoId) async {
    final playlist = await getPlaylist(playlistId);
    return playlist?.videoIds.contains(videoId) ?? false;
  }

  // Get playlists containing video
  Future<List<PlaylistModel>> getPlaylistsForVideo(String videoId) async {
    final allPlaylists = await getAllPlaylists();
    return allPlaylists.where((playlist) => playlist.videoIds.contains(videoId)).toList();
  }
}

