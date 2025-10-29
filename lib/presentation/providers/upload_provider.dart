import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

enum UploadType { video, short, image }

class UploadProvider extends ChangeNotifier {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get errorMessage => _errorMessage;

  final cloudinary = CloudinaryPublic(
    'dzfepmtdw',
    'nilappstreaming',
    cache: false,
  );

  Future<bool> uploadVideo({
    required File videoFile,
    required String title,
    required String description,
    required String userId,
    required String userName,
    required UploadType uploadType,
    File? thumbnailFile,
  }) async {
    _isUploading = true;
    _uploadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      // Upload video to Cloudinary
      _uploadProgress = 0.3;
      notifyListeners();

      final CloudinaryResponse videoResponse = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          videoFile.path,
          resourceType: CloudinaryResourceType.Video,
          folder: uploadType == UploadType.video ? 'videos' : 'shorts',
        ),
      );

      _uploadProgress = 0.6;
      notifyListeners();

      // Upload thumbnail
      String thumbnailUrl;
      if (thumbnailFile != null) {
        // User provided a custom thumbnail
        final CloudinaryResponse thumbnailResponse = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            thumbnailFile.path,
            resourceType: CloudinaryResourceType.Image,
            folder: 'thumbnails',
          ),
        );
        thumbnailUrl = thumbnailResponse.secureUrl;
      } else {
        // Auto-generate thumbnail from video
        print('🎬 Generating thumbnail from video...');
        final generatedThumbnail = await _generateThumbnail(videoFile.path);
        
        if (generatedThumbnail != null) {
          print('✅ Thumbnail generated successfully');
          final CloudinaryResponse thumbnailResponse = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              generatedThumbnail.path,
              resourceType: CloudinaryResourceType.Image,
              folder: 'thumbnails',
            ),
          );
          thumbnailUrl = thumbnailResponse.secureUrl;
          
          // Clean up temporary thumbnail file
          try {
            await generatedThumbnail.delete();
          } catch (e) {
            print('⚠️ Could not delete temp thumbnail: $e');
          }
        } else {
          print('⚠️ Thumbnail generation failed, using Cloudinary fallback');
          // Fallback to Cloudinary auto-generated thumbnail
          final publicId = videoResponse.publicId;
          thumbnailUrl = 'https://res.cloudinary.com/dzfepmtdw/video/upload/$publicId.jpg';
        }
      }

      _uploadProgress = 0.8;
      notifyListeners();

      // Get video duration
      print('📊 Extracting video duration...');
      final int videoDuration = await _getVideoDuration(videoFile.path);

      // Save metadata to Firestore
      final collection = uploadType == UploadType.video ? 'videos' : 'shorts';
      final docRef = FirebaseFirestore.instance.collection(collection).doc();

      await docRef.set({
        'title': title,
        'description': description,
        'videoUrl': videoResponse.secureUrl,
        'thumbnailUrl': thumbnailUrl,
        'uploadedBy': userId,
        'uploaderName': userName,
        'channelName': userName,
        'channelAvatar': 'https://ui-avatars.com/api/?name=$userName&background=random',
        'views': 0,
        'likes': 0,
        'dislikes': 0,
        'timestamp': FieldValue.serverTimestamp(),
        'duration': videoDuration, // Automatically calculated duration
      });

      // Update user's upload count
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      if (uploadType == UploadType.video) {
        await userRef.update({
          'uploadedVideosCount': FieldValue.increment(1),
        });
      } else {
        await userRef.update({
          'uploadedShortsCount': FieldValue.increment(1),
        });
      }

      _uploadProgress = 1.0;
      notifyListeners();

      // Send notifications to all users in background
      await _sendNotificationToUsers(
        uploadType: uploadType,
        title: title,
        userName: userName,
        videoId: docRef.id,
        userId: userId,
      );

      await Future.delayed(const Duration(milliseconds: 500));
      _isUploading = false;
      _uploadProgress = 0.0;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Upload failed: ${e.toString()}';
      _isUploading = false;
      _uploadProgress = 0.0;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _isUploading = false;
    _uploadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();
  }

  /// Generate thumbnail from video file
  Future<File?> _generateThumbnail(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 720, // High quality thumbnail
        quality: 85,
        timeMs: 1000, // Capture frame at 1 second
      );

      if (thumbnailPath != null) {
        return File(thumbnailPath);
      }
      return null;
    } catch (e) {
      print('❌ Error generating thumbnail: $e');
      return null;
    }
  }

  /// Get video duration in seconds
  Future<int> _getVideoDuration(String videoPath) async {
    try {
      print('⏱️ Calculating video duration...');
      final VideoPlayerController controller = VideoPlayerController.file(File(videoPath));
      
      await controller.initialize();
      final duration = controller.value.duration.inSeconds;
      
      await controller.dispose();
      
      print('✅ Video duration: $duration seconds');
      return duration;
    } catch (e) {
      print('❌ Error getting video duration: $e');
      return 0; // Fallback to 0 if duration extraction fails
    }
  }

  /// Store notification in Firestore for users to see
  Future<void> _sendNotificationToUsers({
    required UploadType uploadType,
    required String title,
    required String userName,
    required String videoId,
    required String userId,
  }) async {
    try {
      // Get all users from Firestore
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      if (usersSnapshot.docs.isEmpty) return;
      
      // Create notification for each user
      final batch = FirebaseFirestore.instance.batch();
      
      for (final userDoc in usersSnapshot.docs) {
        final notificationRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc();
        
        batch.set(notificationRef, {
          'type': uploadType == UploadType.video ? 'video_upload' : 'short_upload',
          'title': uploadType == UploadType.video 
              ? '🎬 New Video Uploaded!' 
              : '⚡ New Short Available!',
          'body': '$title by $userName',
          'contentType': uploadType == UploadType.video ? 'video' : 'short',
          'contentId': videoId,
          'channelId': userId,
          'channelName': userName,
          'videoTitle': title,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
      
      await batch.commit();
      print('✅ Notifications created for ${usersSnapshot.docs.length} users');
    } catch (e) {
      print('⚠️ Failed to create notifications: $e');
      // Don't fail the upload if notification fails
    }
  }

  /// Upload image post to Cloudinary and Firestore
  Future<bool> uploadImagePost({
    required List<File> imageFiles,
    required String title,
    required String description,
    required String userId,
    required String userName,
  }) async {
    
    _isUploading = true;
    _uploadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      // Upload images to Cloudinary
      _uploadProgress = 0.2;
      notifyListeners();

      final List<String> imageUrls = [];
      final int totalImages = imageFiles.length;
      
      for (int i = 0; i < imageFiles.length; i++) {
        final CloudinaryResponse imageResponse = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            imageFiles[i].path,
            resourceType: CloudinaryResourceType.Image,
            folder: 'image_posts',
          ),
        );
        imageUrls.add(imageResponse.secureUrl);
        
        // Update progress
        _uploadProgress = 0.2 + (0.6 * (i + 1) / totalImages);
        notifyListeners();
      }

      _uploadProgress = 0.8;
      notifyListeners();

      // Store in Firestore
      final imagePostRef = FirebaseFirestore.instance.collection('image_posts').doc();
      final imagePostId = imagePostRef.id;

      await imagePostRef.set({
        'id': imagePostId,
        'title': title,
        'description': description,
        'imageUrls': imageUrls,
        'imageCount': imageUrls.length,
        'uploadedBy': userId,
        'channelName': userName,
        'channelAvatar': FirebaseAuth.instance.currentUser?.photoURL ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'dislikes': 0,
        'comments': 0,
        'shares': 0,
        'type': 'image_post',
      });

      // Update user's image posts count
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'uploadedImagePostsCount': FieldValue.increment(1),
      });

      _uploadProgress = 0.9;
      notifyListeners();

      // Send notifications to users
      await _sendImagePostNotificationToUsers(
        title: title,
        userName: userName,
        imagePostId: imagePostId,
        userId: userId,
      );

      _uploadProgress = 1.0;
      notifyListeners();

      print('✅ Image post uploaded successfully');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to upload image post: $e';
      print('❌ Error uploading image post: $e');
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Store image post notification in Firestore for users to see
  Future<void> _sendImagePostNotificationToUsers({
    required String title,
    required String userName,
    required String imagePostId,
    required String userId,
  }) async {
    try {
      // Get all users from Firestore
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      if (usersSnapshot.docs.isEmpty) return;
      
      // Create notification for each user
      final batch = FirebaseFirestore.instance.batch();
      
      for (final userDoc in usersSnapshot.docs) {
        final notificationRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc();
        
        batch.set(notificationRef, {
          'type': 'image_post',
          'title': '📸 New Image Post!',
          'body': '$title by $userName',
          'contentType': 'image_post',
          'contentId': imagePostId,
          'channelId': userId,
          'channelName': userName,
          'postTitle': title,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
      
      await batch.commit();
      print('✅ Image post notifications sent to ${usersSnapshot.docs.length} users');
    } catch (e) {
      print('❌ Error sending image post notifications: $e');
    }
  }
}
