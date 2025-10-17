import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/short_video_model.dart';

class ShortsProviderNew extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Track likes/dislikes per short
  final Map<String, bool> _likedShorts = {};
  final Map<String, bool> _dislikedShorts = {};

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
}


