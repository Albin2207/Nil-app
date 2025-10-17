import 'package:hive/hive.dart';

part 'playlist_model.g.dart';

@HiveType(typeId: 1)
class PlaylistModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  List<String> videoIds;

  @HiveField(4)
  final DateTime createdDate;

  @HiveField(5)
  String? coverImage;

  PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    required this.videoIds,
    required this.createdDate,
    this.coverImage,
  });

  int get videoCount => videoIds.length;
}

