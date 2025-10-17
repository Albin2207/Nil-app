import 'package:hive/hive.dart';

part 'downloaded_video.g.dart';

@HiveType(typeId: 0)
class DownloadedVideo extends HiveObject {
  @HiveField(0)
  final String videoId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String thumbnailUrl;

  @HiveField(3)
  final String localPath;

  @HiveField(4)
  final String quality;

  @HiveField(5)
  final int fileSize;

  @HiveField(6)
  final DateTime downloadDate;

  @HiveField(7)
  final bool isShort;

  @HiveField(8)
  final String channelName;

  @HiveField(9)
  final String description;

  DownloadedVideo({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.localPath,
    required this.quality,
    required this.fileSize,
    required this.downloadDate,
    required this.isShort,
    required this.channelName,
    required this.description,
  });

  // Format file size to human-readable
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

