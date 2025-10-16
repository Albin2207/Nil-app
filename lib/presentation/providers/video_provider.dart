import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/video_model.dart';

class VideoProvider extends ChangeNotifier {
  VideoModel? _currentVideo;
  bool _isLiked = false;
  bool _isDisliked = false;
  bool _isSubscribed = false;
  bool _isDescriptionExpanded = false;

  VideoModel? get currentVideo => _currentVideo;
  bool get isLiked => _isLiked;
  bool get isDisliked => _isDisliked;
  bool get isSubscribed => _isSubscribed;
  bool get isDescriptionExpanded => _isDescriptionExpanded;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize with video
  Future<void> initializeVideo(DocumentSnapshot videoDoc) async {
    _currentVideo = VideoModel.fromFirestore(videoDoc);
    await _loadUserPreferences();
    await _incrementViewCount();
    notifyListeners();
  }

  // Load user preferences from local storage
  Future<void> _loadUserPreferences() async {
    if (_currentVideo == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    _isLiked = prefs.getBool('liked_${_currentVideo!.id}') ?? false;
    _isDisliked = prefs.getBool('disliked_${_currentVideo!.id}') ?? false;
    _isSubscribed = prefs.getBool('subscribed_${_currentVideo!.channelName}') ?? false;
  }

  // Save user preferences
  Future<void> _saveUserPreferences() async {
    if (_currentVideo == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('liked_${_currentVideo!.id}', _isLiked);
    await prefs.setBool('disliked_${_currentVideo!.id}', _isDisliked);
    await prefs.setBool('subscribed_${_currentVideo!.channelName}', _isSubscribed);
  }

  // Increment view count
  Future<void> _incrementViewCount() async {
    if (_currentVideo == null) return;
    
    await _firestore
        .collection('videos')
        .doc(_currentVideo!.id)
        .update({'views': FieldValue.increment(1)});
  }

  // Toggle like
  Future<void> toggleLike() async {
    if (_currentVideo == null) return;

    final docRef = _firestore.collection('videos').doc(_currentVideo!.id);

    if (_isLiked) {
      await docRef.update({'likes': FieldValue.increment(-1)});
      _isLiked = false;
    } else {
      final updates = <String, dynamic>{'likes': FieldValue.increment(1)};
      if (_isDisliked) {
        updates['dislikes'] = FieldValue.increment(-1);
        _isDisliked = false;
      }
      await docRef.update(updates);
      _isLiked = true;
    }

    await _saveUserPreferences();
    notifyListeners();
  }

  // Toggle dislike
  Future<void> toggleDislike() async {
    if (_currentVideo == null) return;

    final docRef = _firestore.collection('videos').doc(_currentVideo!.id);

    if (_isDisliked) {
      await docRef.update({'dislikes': FieldValue.increment(-1)});
      _isDisliked = false;
    } else {
      final updates = <String, dynamic>{'dislikes': FieldValue.increment(1)};
      if (_isLiked) {
        updates['likes'] = FieldValue.increment(-1);
        _isLiked = false;
      }
      await docRef.update(updates);
      _isDisliked = true;
    }

    await _saveUserPreferences();
    notifyListeners();
  }

  // Toggle subscribe
  Future<void> toggleSubscribe() async {
    _isSubscribed = !_isSubscribed;
    await _saveUserPreferences();
    notifyListeners();
  }

  // Toggle description expansion
  void toggleDescriptionExpansion() {
    _isDescriptionExpanded = !_isDescriptionExpanded;
    notifyListeners();
  }
}

