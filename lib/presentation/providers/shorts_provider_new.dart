import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/short_video_model.dart';
import '../../data/models/short_comment_model.dart';

class ShortsProviderNew extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Track likes/dislikes per short
  final Map<String, bool> _likedShorts = {};
  final Map<String, bool> _dislikedShorts = {};
  
  // Track comment likes/dislikes
  final Map<String, bool> _likedComments = {};
  final Map<String, bool> _dislikedComments = {};

  bool isShortLiked(String shortId) => _likedShorts[shortId] ?? false;
  bool isShortDisliked(String shortId) => _dislikedShorts[shortId] ?? false;

  // Load user preferences
  Future<void> loadShortPreferences(String shortId) async {
    final prefs = await SharedPreferences.getInstance();
    _likedShorts[shortId] = prefs.getBool('short_liked_$shortId') ?? false;
    _dislikedShorts[shortId] = prefs.getBool('short_disliked_$shortId') ?? false;
  }

  // Save preferences
  Future<void> _savePreferences(String shortId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('short_liked_$shortId', _likedShorts[shortId] ?? false);
    await prefs.setBool('short_disliked_$shortId', _dislikedShorts[shortId] ?? false);
  }

  // Toggle like
  Future<void> toggleLike(String shortId) async {
    final docRef = _firestore.collection('shorts').doc(shortId);
    final wasLiked = _likedShorts[shortId] ?? false;
    final wasDisliked = _dislikedShorts[shortId] ?? false;

    if (wasLiked) {
      await docRef.update({'likes': FieldValue.increment(-1)});
      _likedShorts[shortId] = false;
    } else {
      final updates = <String, dynamic>{'likes': FieldValue.increment(1)};
      if (wasDisliked) {
        updates['dislikes'] = FieldValue.increment(-1);
        _dislikedShorts[shortId] = false;
      }
      await docRef.update(updates);
      _likedShorts[shortId] = true;
    }

    await _savePreferences(shortId);
    notifyListeners();
  }

  // Toggle dislike
  Future<void> toggleDislike(String shortId) async {
    final docRef = _firestore.collection('shorts').doc(shortId);
    final wasLiked = _likedShorts[shortId] ?? false;
    final wasDisliked = _dislikedShorts[shortId] ?? false;

    if (wasDisliked) {
      await docRef.update({'dislikes': FieldValue.increment(-1)});
      _dislikedShorts[shortId] = false;
    } else {
      final updates = <String, dynamic>{'dislikes': FieldValue.increment(1)};
      if (wasLiked) {
        updates['likes'] = FieldValue.increment(-1);
        _likedShorts[shortId] = false;
      }
      await docRef.update(updates);
      _dislikedShorts[shortId] = true;
    }

    await _savePreferences(shortId);
    notifyListeners();
  }

  // Increment view count
  Future<void> incrementViews(String shortId) async {
    await _firestore.collection('shorts').doc(shortId).update({
      'views': FieldValue.increment(1),
    });
  }

  // Get shorts stream
  Stream<List<ShortVideo>> getShortsStream() {
    return _firestore
        .collection('shorts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ShortVideo.fromFirestore(doc)).toList());
  }

  // ==================== COMMENTS ====================

  // Post a comment
  Future<void> postComment({
    required String shortId,
    required String text,
    String? parentId,
    String? userId,
    String? userName,
    String? userAvatar,
  }) async {
    final comment = ShortComment(
      id: '',
      shortId: shortId,
      userId: userId ?? 'anonymous_user',
      userName: userName ?? 'Anonymous User',
      userAvatar: userAvatar ?? 'https://i.pravatar.cc/150?img=1',
      text: text,
      timestamp: DateTime.now(),
      parentId: parentId,
    );

    await _firestore.collection('shorts').doc(shortId).collection('comments').add(comment.toMap());

    // Increment comment count on the short
    await _firestore.collection('shorts').doc(shortId).update({
      'commentsCount': FieldValue.increment(1),
    });
  }

  // Get comments stream for a short
  Stream<List<ShortComment>> getCommentsStream(String shortId) {
    return _firestore
        .collection('shorts')
        .doc(shortId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShortComment.fromFirestore(doc))
            .toList());
  }

  // Toggle comment like
  Future<void> toggleCommentLike(String shortId, String commentId) async {
    final docRef = _firestore
        .collection('shorts')
        .doc(shortId)
        .collection('comments')
        .doc(commentId);

    final key = '${shortId}_$commentId';
    final wasLiked = _likedComments[key] ?? false;
    final wasDisliked = _dislikedComments[key] ?? false;

    if (wasLiked) {
      await docRef.update({'likes': FieldValue.increment(-1)});
      _likedComments[key] = false;
    } else {
      final updates = <String, dynamic>{'likes': FieldValue.increment(1)};
      if (wasDisliked) {
        updates['dislikes'] = FieldValue.increment(-1);
        _dislikedComments[key] = false;
      }
      await docRef.update(updates);
      _likedComments[key] = true;
    }

    notifyListeners();
  }

  // Toggle comment dislike
  Future<void> toggleCommentDislike(String shortId, String commentId) async {
    final docRef = _firestore
        .collection('shorts')
        .doc(shortId)
        .collection('comments')
        .doc(commentId);

    final key = '${shortId}_$commentId';
    final wasLiked = _likedComments[key] ?? false;
    final wasDisliked = _dislikedComments[key] ?? false;

    if (wasDisliked) {
      await docRef.update({'dislikes': FieldValue.increment(-1)});
      _dislikedComments[key] = false;
    } else {
      final updates = <String, dynamic>{'dislikes': FieldValue.increment(1)};
      if (wasLiked) {
        updates['likes'] = FieldValue.increment(-1);
        _likedComments[key] = false;
      }
      await docRef.update(updates);
      _dislikedComments[key] = true;
    }

    notifyListeners();
  }

  // Check if comment is liked
  bool isCommentLiked(String shortId, String commentId) {
    return _likedComments['${shortId}_$commentId'] ?? false;
  }

  // Check if comment is disliked
  bool isCommentDisliked(String shortId, String commentId) {
    return _dislikedComments['${shortId}_$commentId'] ?? false;
  }

  // Delete a comment
  Future<void> deleteComment(String shortId, String commentId) async {
    await _firestore
        .collection('shorts')
        .doc(shortId)
        .collection('comments')
        .doc(commentId)
        .delete();

    // Decrement comment count
    await _firestore.collection('shorts').doc(shortId).update({
      'commentsCount': FieldValue.increment(-1),
    });
  }
}


