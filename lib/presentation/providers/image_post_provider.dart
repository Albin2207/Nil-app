import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImagePostProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Track user interactions for each post
  final Map<String, bool> _postLikes = {};
  final Map<String, bool> _postDislikes = {};
  
  // Track like/dislike counts for each post
  final Map<String, int> _postLikeCounts = {};
  final Map<String, int> _postDislikeCounts = {};
  final Map<String, int> _postCommentCounts = {};

  bool isPostLiked(String postId) => _postLikes[postId] ?? false;
  bool isPostDisliked(String postId) => _postDislikes[postId] ?? false;
  int getPostLikeCount(String postId) => _postLikeCounts[postId] ?? 0;
  int getPostDislikeCount(String postId) => _postDislikeCounts[postId] ?? 0;
  int getPostCommentCount(String postId) => _postCommentCounts[postId] ?? 0;

  // Load user preferences from SharedPreferences
  Future<void> loadUserPreferences(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    _postLikes[postId] = prefs.getBool('image_liked_$postId') ?? false;
    _postDislikes[postId] = prefs.getBool('image_disliked_$postId') ?? false;
    notifyListeners();
  }

  // Save user preferences to SharedPreferences
  Future<void> saveUserPreferences(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('image_liked_$postId', _postLikes[postId] ?? false);
    await prefs.setBool('image_disliked_$postId', _postDislikes[postId] ?? false);
  }

  // Update post data from Firestore
  void updatePostData(String postId, Map<String, dynamic> data) {
    _postLikeCounts[postId] = data['likes'] ?? 0;
    _postDislikeCounts[postId] = data['dislikes'] ?? 0;
    _postCommentCounts[postId] = data['comments'] ?? 0;
    notifyListeners();
  }

  // Toggle like for a post
  Future<void> toggleLike(String postId) async {
    try {
      final docRef = _firestore.collection('image_posts').doc(postId);
      
      if (_postLikes[postId] == true) {
        // Remove like
        await docRef.update({'likes': FieldValue.increment(-1)});
        _postLikes[postId] = false;
      } else {
        // Add like, remove dislike if exists
        final updates = <String, dynamic>{'likes': FieldValue.increment(1)};
        if (_postDislikes[postId] == true) {
          updates['dislikes'] = FieldValue.increment(-1);
          _postDislikes[postId] = false;
        }
        await docRef.update(updates);
        _postLikes[postId] = true;
      }

      await saveUserPreferences(postId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  // Toggle dislike for a post
  Future<void> toggleDislike(String postId) async {
    try {
      final docRef = _firestore.collection('image_posts').doc(postId);
      
      if (_postDislikes[postId] == true) {
        // Remove dislike
        await docRef.update({'dislikes': FieldValue.increment(-1)});
        _postDislikes[postId] = false;
      } else {
        // Add dislike, remove like if exists
        final updates = <String, dynamic>{'dislikes': FieldValue.increment(1)};
        if (_postLikes[postId] == true) {
          updates['likes'] = FieldValue.increment(-1);
          _postLikes[postId] = false;
        }
        await docRef.update(updates);
        _postDislikes[postId] = true;
      }

      await saveUserPreferences(postId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling dislike: $e');
    }
  }

  // Get stream for a specific post
  Stream<DocumentSnapshot> getPostStream(String postId) {
    return _firestore.collection('image_posts').doc(postId).snapshots();
  }

  // Format count for display
  String formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}

