import 'package:flutter/material.dart';
import '../../data/models/downloaded_video.dart';
import '../../data/repositories/download_repository.dart';

class DownloadProvider extends ChangeNotifier {
  final DownloadRepository _repository = DownloadRepository();

  List<DownloadedVideo> _downloads = [];
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _currentDownloadId;
  String? _errorMessage;

  List<DownloadedVideo> get downloads => _downloads;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String? get currentDownloadId => _currentDownloadId;
  String? get errorMessage => _errorMessage;

  // Load all downloads
  Future<void> loadDownloads() async {
    try {
      _downloads = await _repository.getAllDownloads();
      _downloads.sort((a, b) => b.downloadDate.compareTo(a.downloadDate));
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load downloads: $e';
      notifyListeners();
    }
  }

  // Check if video is downloaded
  Future<bool> isVideoDownloaded(String videoId) async {
    return await _repository.isVideoDownloaded(videoId);
  }

  // Download video
  Future<bool> downloadVideo({
    required String videoId,
    required String videoUrl,
    required String title,
    required String thumbnailUrl,
    required String quality,
    required bool isShort,
    required String channelName,
    required String description,
  }) async {
    // Check if already downloaded
    if (await isVideoDownloaded(videoId)) {
      _errorMessage = 'Video already downloaded';
      notifyListeners();
      return false;
    }

    _isDownloading = true;
    _currentDownloadId = videoId;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();
    
    print('🚀 DownloadProvider: Starting download for $title');

    try {
      final download = await _repository.downloadVideo(
        videoId: videoId,
        videoUrl: videoUrl,
        title: title,
        thumbnailUrl: thumbnailUrl,
        quality: quality,
        isShort: isShort,
        channelName: channelName,
        description: description,
        onProgress: (progress) {
          _downloadProgress = progress;
          print('📈 DownloadProvider: Progress updated to ${(progress * 100).toInt()}%');
          notifyListeners();
        },
      );

      if (download != null) {
        _downloads.insert(0, download);
        _isDownloading = false;
        _currentDownloadId = null;
        _downloadProgress = 0.0;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isDownloading = false;
      _currentDownloadId = null;
      _downloadProgress = 0.0;
      notifyListeners();
      return false;
    }
  }

  // Delete download
  Future<void> deleteDownload(String videoId) async {
    try {
      await _repository.deleteDownload(videoId);
      _downloads.removeWhere((download) => download.videoId == videoId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete: $e';
      notifyListeners();
    }
  }

  // Get download by videoId
  Future<DownloadedVideo?> getDownload(String videoId) async {
    return await _repository.getDownload(videoId);
  }

  // Get total storage used
  Future<String> getTotalStorageUsed() async {
    final bytes = await _repository.getTotalStorageUsed();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Cancel download
  void cancelDownload() {
    _repository.cancelDownload();
    _isDownloading = false;
    _currentDownloadId = null;
    _downloadProgress = 0.0;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

