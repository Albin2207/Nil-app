import 'dart:io';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/downloaded_video.dart';

class DownloadRepository {
  static const String _boxName = 'downloads';
  final Dio _dio = Dio();

  Future<Box<DownloadedVideo>> _getBox() async {
    return await Hive.openBox<DownloadedVideo>(_boxName);
  }

  // Download video
  Future<DownloadedVideo?> downloadVideo({
    required String videoId,
    required String videoUrl,
    required String title,
    required String thumbnailUrl,
    required String quality,
    required bool isShort,
    required String channelName,
    required String description,
    required Function(double) onProgress,
  }) async {
    try {
      // Get app directory
      final appDir = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${appDir.path}/videos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${videoId}_${quality}_$timestamp.mp4';
      final filePath = '${videoDir.path}/$fileName';

      // Download with progress
      await _dio.download(
        videoUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      // Get file size
      final file = File(filePath);
      final fileSize = await file.length();

      // Create download record
      final download = DownloadedVideo(
        videoId: videoId,
        title: title,
        thumbnailUrl: thumbnailUrl,
        localPath: filePath,
        quality: quality,
        fileSize: fileSize,
        downloadDate: DateTime.now(),
        isShort: isShort,
        channelName: channelName,
        description: description,
      );

      // Save to Hive
      final box = await _getBox();
      await box.put(videoId, download);

      return download;
    } catch (e) {
      throw 'Download failed: ${e.toString()}';
    }
  }

  // Get all downloads
  Future<List<DownloadedVideo>> getAllDownloads() async {
    final box = await _getBox();
    return box.values.toList();
  }

  // Get download by videoId
  Future<DownloadedVideo?> getDownload(String videoId) async {
    final box = await _getBox();
    return box.get(videoId);
  }

  // Check if video is downloaded
  Future<bool> isVideoDownloaded(String videoId) async {
    final box = await _getBox();
    return box.containsKey(videoId);
  }

  // Delete download
  Future<void> deleteDownload(String videoId) async {
    final box = await _getBox();
    final download = box.get(videoId);
    
    if (download != null) {
      // Delete file
      final file = File(download.localPath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Remove from Hive
      await box.delete(videoId);
    }
  }

  // Get total storage used
  Future<int> getTotalStorageUsed() async {
    final downloads = await getAllDownloads();
    return downloads.fold<int>(0, (sum, download) => sum + download.fileSize);
  }

  // Cancel download (if needed)
  void cancelDownload() {
    _dio.close(force: true);
  }
}

