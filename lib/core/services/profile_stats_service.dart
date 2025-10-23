import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to handle profile statistics and engagement metrics
class ProfileStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get engagement statistics for a user (views, likes, comments, shares)
  Future<Map<String, int>> getEngagementStats(String? userId) async {
    if (userId == null) {
      return _emptyStats();
    }

    try {
      int totalViews = 0;
      int totalLikes = 0;
      int totalComments = 0;
      int totalShares = 0;

      // Get all videos by this user
      final videosSnapshot = await _firestore
          .collection('videos')
          .where('uploaderId', isEqualTo: userId)
          .get();

      for (var doc in videosSnapshot.docs) {
        final data = doc.data();
        totalViews += (data['viewsCount'] as int? ?? 0);
        totalLikes += (data['likesCount'] as int? ?? 0);
        totalShares += (data['sharesCount'] as int? ?? 0);

        // Count comments for this video
        final commentsSnapshot = await _firestore
            .collection('comments')
            .where('videoId', isEqualTo: doc.id)
            .get();
        totalComments += commentsSnapshot.docs.length;
      }

      // Get all shorts by this user
      final shortsSnapshot = await _firestore
          .collection('shorts')
          .where('uploaderId', isEqualTo: userId)
          .get();

      for (var doc in shortsSnapshot.docs) {
        final data = doc.data();
        totalViews += (data['viewsCount'] as int? ?? 0);
        totalLikes += (data['likesCount'] as int? ?? 0);
        totalShares += (data['sharesCount'] as int? ?? 0);

        // Count comments for this short
        final commentsSnapshot = await _firestore
            .collection('comments')
            .where('videoId', isEqualTo: doc.id)
            .get();
        totalComments += commentsSnapshot.docs.length;
      }

      return {
        'views': totalViews,
        'likes': totalLikes,
        'comments': totalComments,
        'shares': totalShares,
      };
    } catch (e) {
      print('Error getting engagement stats: $e');
      return _emptyStats();
    }
  }

  /// Fix negative counts in user's content
  Future<void> fixNegativeCounts() async {
    try {
      // Fix videos
      final videosSnapshot = await _firestore.collection('videos').get();
      final batch = _firestore.batch();

      for (var doc in videosSnapshot.docs) {
        final data = doc.data();
        final Map<String, dynamic> updates = {};

        if ((data['viewsCount'] as int? ?? 0) < 0) {
          updates['viewsCount'] = 0;
        }
        if ((data['likesCount'] as int? ?? 0) < 0) {
          updates['likesCount'] = 0;
        }
        if ((data['sharesCount'] as int? ?? 0) < 0) {
          updates['sharesCount'] = 0;
        }

        if (updates.isNotEmpty) {
          batch.update(doc.reference, updates);
        }
      }

      // Fix shorts
      final shortsSnapshot = await _firestore.collection('shorts').get();

      for (var doc in shortsSnapshot.docs) {
        final data = doc.data();
        final Map<String, dynamic> updates = {};

        if ((data['viewsCount'] as int? ?? 0) < 0) {
          updates['viewsCount'] = 0;
        }
        if ((data['likesCount'] as int? ?? 0) < 0) {
          updates['likesCount'] = 0;
        }
        if ((data['sharesCount'] as int? ?? 0) < 0) {
          updates['sharesCount'] = 0;
        }

        if (updates.isNotEmpty) {
          batch.update(doc.reference, updates);
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error fixing negative counts: $e');
      rethrow;
    }
  }

  /// Delete a video or short
  Future<void> deleteContent(String id, String type) async {
    try {
      final collection = type == 'video' ? 'videos' : 'shorts';
      await _firestore.collection(collection).doc(id).delete();

      // Delete associated comments
      final commentsSnapshot = await _firestore
          .collection('comments')
          .where('videoId', isEqualTo: id)
          .get();

      final batch = _firestore.batch();
      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting content: $e');
      rethrow;
    }
  }

  Map<String, int> _emptyStats() {
    return {
      'views': 0,
      'likes': 0,
      'comments': 0,
      'shares': 0,
    };
  }
}

