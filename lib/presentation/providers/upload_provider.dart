import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UploadType { video, short }

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

      // Upload thumbnail if provided, otherwise use Cloudinary auto-generated
      String thumbnailUrl;
      if (thumbnailFile != null) {
        final CloudinaryResponse thumbnailResponse = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            thumbnailFile.path,
            resourceType: CloudinaryResourceType.Image,
            folder: 'thumbnails',
          ),
        );
        thumbnailUrl = thumbnailResponse.secureUrl;
      } else {
        // Use Cloudinary video thumbnail
        final publicId = videoResponse.publicId;
        thumbnailUrl = 'https://res.cloudinary.com/dzfepmtdw/video/upload/$publicId.jpg';
      }

      _uploadProgress = 0.8;
      notifyListeners();

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
        'duration': '0:00', // You can calculate this if needed
      });

      _uploadProgress = 1.0;
      notifyListeners();

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
}

