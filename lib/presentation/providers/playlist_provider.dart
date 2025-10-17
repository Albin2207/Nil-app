import 'package:flutter/material.dart';
import '../../data/models/playlist_model.dart';
import '../../data/repositories/playlist_repository.dart';

class PlaylistProvider extends ChangeNotifier {
  final PlaylistRepository _repository = PlaylistRepository();

  List<PlaylistModel> _playlists = [];
  String? _errorMessage;

  List<PlaylistModel> get playlists => _playlists;
  String? get errorMessage => _errorMessage;

  // Load all playlists
  Future<void> loadPlaylists() async {
    try {
      _playlists = await _repository.getAllPlaylists();
      _playlists.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load playlists: $e';
      notifyListeners();
    }
  }

  // Create playlist
  Future<PlaylistModel?> createPlaylist({
    required String name,
    String? description,
  }) async {
    try {
      final playlist = await _repository.createPlaylist(
        name: name,
        description: description,
      );
      _playlists.insert(0, playlist);
      notifyListeners();
      return playlist;
    } catch (e) {
      _errorMessage = 'Failed to create playlist: $e';
      notifyListeners();
      return null;
    }
  }

  // Add video to playlist
  Future<void> addVideoToPlaylist(String playlistId, String videoId) async {
    try {
      await _repository.addVideoToPlaylist(playlistId, videoId);
      await loadPlaylists(); // Reload to get updated data
    } catch (e) {
      _errorMessage = 'Failed to add video: $e';
      notifyListeners();
    }
  }

  // Remove video from playlist
  Future<void> removeVideoFromPlaylist(String playlistId, String videoId) async {
    try {
      await _repository.removeVideoFromPlaylist(playlistId, videoId);
      await loadPlaylists();
    } catch (e) {
      _errorMessage = 'Failed to remove video: $e';
      notifyListeners();
    }
  }

  // Update playlist
  Future<void> updatePlaylist(PlaylistModel playlist) async {
    try {
      await _repository.updatePlaylist(playlist);
      await loadPlaylists();
    } catch (e) {
      _errorMessage = 'Failed to update playlist: $e';
      notifyListeners();
    }
  }

  // Delete playlist
  Future<void> deletePlaylist(String id) async {
    try {
      await _repository.deletePlaylist(id);
      _playlists.removeWhere((playlist) => playlist.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete playlist: $e';
      notifyListeners();
    }
  }

  // Check if video is in playlist
  Future<bool> isVideoInPlaylist(String playlistId, String videoId) async {
    return await _repository.isVideoInPlaylist(playlistId, videoId);
  }

  // Get playlists containing video
  Future<List<PlaylistModel>> getPlaylistsForVideo(String videoId) async {
    return await _repository.getPlaylistsForVideo(videoId);
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

