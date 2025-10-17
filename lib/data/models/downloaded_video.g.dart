// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'downloaded_video.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadedVideoAdapter extends TypeAdapter<DownloadedVideo> {
  @override
  final int typeId = 0;

  @override
  DownloadedVideo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadedVideo(
      videoId: fields[0] as String,
      title: fields[1] as String,
      thumbnailUrl: fields[2] as String,
      localPath: fields[3] as String,
      quality: fields[4] as String,
      fileSize: fields[5] as int,
      downloadDate: fields[6] as DateTime,
      isShort: fields[7] as bool,
      channelName: fields[8] as String,
      description: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadedVideo obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.videoId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.thumbnailUrl)
      ..writeByte(3)
      ..write(obj.localPath)
      ..writeByte(4)
      ..write(obj.quality)
      ..writeByte(5)
      ..write(obj.fileSize)
      ..writeByte(6)
      ..write(obj.downloadDate)
      ..writeByte(7)
      ..write(obj.isShort)
      ..writeByte(8)
      ..write(obj.channelName)
      ..writeByte(9)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadedVideoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
