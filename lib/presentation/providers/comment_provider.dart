import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/comment_model.dart';

class CommentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Track comment likes/dislikes locally
  final Map<String, bool> _commentLikes = {};
  final Map<String, bool> _commentDislikes = {};

  bool isCommentLiked(String commentId) => _commentLikes[commentId] ?? false;
  bool isCommentDisliked(String commentId) => _commentDislikes[commentId] ?? false;

  // Post a new comment
  Future<void> postComment({
    required String videoId,
    required String text,
    String? parentId,
  }) async {
    if (text.trim().isEmpty) return;

    await _firestore
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .add({
      'text': text.trim(),
      'username': 'Anonymous User', // TODO: Replace with actual user
      'userAvatar': 'https://i.pravatar.cc/150?img=1',
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'dislikes': 0,
      'parentId': parentId,
    });
  }

  // Toggle comment like
  Future<void> toggleCommentLike(String videoId, String commentId) async {
    final wasLiked = _commentLikes[commentId] ?? false;
    final wasDisliked = _commentDislikes[commentId] ?? false;

    final docRef = _firestore
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .doc(commentId);

    if (wasLiked) {
      // Unlike
      await docRef.update({'likes': FieldValue.increment(-1)});
      _commentLikes[commentId] = false;
    } else {
      // Like
      final updates = <String, dynamic>{'likes': FieldValue.increment(1)};
      if (wasDisliked) {
        updates['dislikes'] = FieldValue.increment(-1);
        _commentDislikes[commentId] = false;
      }
      await docRef.update(updates);
      _commentLikes[commentId] = true;
    }

    notifyListeners();
  }

  // Toggle comment dislike
  Future<void> toggleCommentDislike(String videoId, String commentId) async {
    final wasLiked = _commentLikes[commentId] ?? false;
    final wasDisliked = _commentDislikes[commentId] ?? false;

    final docRef = _firestore
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .doc(commentId);

    if (wasDisliked) {
      // Remove dislike
      await docRef.update({'dislikes': FieldValue.increment(-1)});
      _commentDislikes[commentId] = false;
    } else {
      // Dislike
      final updates = <String, dynamic>{'dislikes': FieldValue.increment(1)};
      if (wasLiked) {
        updates['likes'] = FieldValue.increment(-1);
        _commentLikes[commentId] = false;
      }
      await docRef.update(updates);
      _commentDislikes[commentId] = true;
    }

    notifyListeners();
  }

  // Get comments stream
  Stream<List<CommentModel>> getCommentsStream(String videoId) {
    return _firestore
        .collection('videos')
        .doc(videoId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList());
  }

  // Get top-level comments (no parent)
  List<CommentModel> getTopLevelComments(List<CommentModel> allComments) {
    return allComments.where((comment) => !comment.isReply).toList();
  }

  // Get replies for a specific comment
  List<CommentModel> getReplies(List<CommentModel> allComments, String parentId) {
    return allComments
        .where((comment) => comment.parentId == parentId)
        .toList();
  }
}

