import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/comment_model.dart';

class ImageCommentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Track comment likes/dislikes locally
  final Map<String, bool> _commentLikes = {};
  final Map<String, bool> _commentDislikes = {};

  bool isCommentLiked(String commentId) => _commentLikes[commentId] ?? false;
  bool isCommentDisliked(String commentId) => _commentDislikes[commentId] ?? false;

  // Post a new comment
  Future<void> postComment({
    required String imagePostId,
    required String text,
    String? parentId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? replyToUsername,
  }) async {
    if (text.trim().isEmpty) return;

    // Use batch write to update both comment and main post
    final batch = _firestore.batch();
    
    // Add comment to subcollection
    final commentRef = _firestore
        .collection('image_posts')
        .doc(imagePostId)
        .collection('comments')
        .doc();
    
    batch.set(commentRef, {
      'text': text.trim(),
      'username': userName ?? 'Anonymous User',
      'userAvatar': userAvatar ?? 'https://i.pravatar.cc/150?img=1',
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'dislikes': 0,
      'parentId': parentId,
      'replyToUsername': replyToUsername,
      'isPinned': false,
    });
    
    // Update comment count in main post (only for top-level comments)
    if (parentId == null) {
      final postRef = _firestore.collection('image_posts').doc(imagePostId);
      batch.update(postRef, {'comments': FieldValue.increment(1)});
    }
    
    await batch.commit();
  }

  // Toggle comment like
  Future<void> toggleCommentLike(String imagePostId, String commentId) async {
    final wasLiked = _commentLikes[commentId] ?? false;
    final wasDisliked = _commentDislikes[commentId] ?? false;

    final docRef = _firestore
        .collection('image_posts')
        .doc(imagePostId)
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
  Future<void> toggleCommentDislike(String imagePostId, String commentId) async {
    final wasLiked = _commentLikes[commentId] ?? false;
    final wasDisliked = _commentDislikes[commentId] ?? false;

    final docRef = _firestore
        .collection('image_posts')
        .doc(imagePostId)
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
  Stream<List<CommentModel>> getCommentsStream(String imagePostId) {
    return _firestore
        .collection('image_posts')
        .doc(imagePostId)
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
    return allComments.where((comment) => comment.parentId == parentId).toList();
  }

  // Delete comment
  Future<void> deleteComment(String imagePostId, String commentId) async {
    // First get the comment to check if it's a top-level comment
    final commentDoc = await _firestore
        .collection('image_posts')
        .doc(imagePostId)
        .collection('comments')
        .doc(commentId)
        .get();
    
    if (!commentDoc.exists) return;
    
    final commentData = commentDoc.data() as Map<String, dynamic>;
    final isTopLevelComment = commentData['parentId'] == null;
    
    // Use batch write to delete comment and update count
    final batch = _firestore.batch();
    
    // Delete the comment
    batch.delete(commentDoc.reference);
    
    // Decrement comment count in main post (only for top-level comments)
    if (isTopLevelComment) {
      final postRef = _firestore.collection('image_posts').doc(imagePostId);
      batch.update(postRef, {'comments': FieldValue.increment(-1)});
    }
    
    await batch.commit();
    notifyListeners();
  }

  // Edit comment
  Future<void> editComment(String imagePostId, String commentId, String newText) async {
    await _firestore
        .collection('image_posts')
        .doc(imagePostId)
        .collection('comments')
        .doc(commentId)
        .update({'text': newText.trim()});
    notifyListeners();
  }

  // Toggle pin comment
  Future<void> togglePinComment(String imagePostId, String commentId, bool isPinned) async {
    await _firestore
        .collection('image_posts')
        .doc(imagePostId)
        .collection('comments')
        .doc(commentId)
        .update({'isPinned': !isPinned});
    notifyListeners();
  }
}
