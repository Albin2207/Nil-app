import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String text;
  final String userId;
  final String username;
  final String userAvatar;
  final Timestamp? timestamp;
  final int likes;
  final int dislikes;
  final String? parentId;
  final String? replyToUsername; // For nested replies context
  final bool isPinned;

  CommentModel({
    required this.id,
    required this.text,
    required this.userId,
    required this.username,
    required this.userAvatar,
    this.timestamp,
    required this.likes,
    required this.dislikes,
    this.parentId,
    this.replyToUsername,
    this.isPinned = false,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      text: data['text'] ?? '',
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Anonymous User',
      userAvatar: data['userAvatar'] ?? 'https://i.pravatar.cc/150?img=3',
      timestamp: data['timestamp'],
      likes: data['likes'] ?? 0,
      dislikes: data['dislikes'] ?? 0,
      parentId: data['parentId'],
      replyToUsername: data['replyToUsername'],
      isPinned: data['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'timestamp': timestamp ?? FieldValue.serverTimestamp(),
      'likes': likes,
      'dislikes': dislikes,
      'parentId': parentId,
      'replyToUsername': replyToUsername,
      'isPinned': isPinned,
    };
  }

  bool get isReply => parentId != null;
}

