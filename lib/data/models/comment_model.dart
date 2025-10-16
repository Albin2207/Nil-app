import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String text;
  final String username;
  final String userAvatar;
  final Timestamp? timestamp;
  final int likes;
  final int dislikes;
  final String? parentId;

  CommentModel({
    required this.id,
    required this.text,
    required this.username,
    required this.userAvatar,
    this.timestamp,
    required this.likes,
    required this.dislikes,
    this.parentId,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      text: data['text'] ?? '',
      username: data['username'] ?? 'Anonymous User',
      userAvatar: data['userAvatar'] ?? 'https://i.pravatar.cc/150?img=3',
      timestamp: data['timestamp'],
      likes: data['likes'] ?? 0,
      dislikes: data['dislikes'] ?? 0,
      parentId: data['parentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'username': username,
      'userAvatar': userAvatar,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
      'likes': likes,
      'dislikes': dislikes,
      'parentId': parentId,
    };
  }

  bool get isReply => parentId != null;
}

