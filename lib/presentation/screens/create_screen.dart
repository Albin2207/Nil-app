import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/upload_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/utils/snackbar_helper.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _selectedVideo;
  File? _selectedThumbnail;
  UploadType _uploadType = UploadType.video;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        setState(() {
          _selectedVideo = File(video.path);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error picking video: $e');
      }
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedThumbnail = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error picking thumbnail: $e');
      }
    }
  }

  Future<void> _uploadVideo() async {
    if (_selectedVideo == null) {
      SnackBarHelper.showInfo(
        context,
        'Please select a video first',
        color: Colors.orange,
        icon: Icons.video_library_outlined,
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      SnackBarHelper.showInfo(
        context,
        'Please enter a title',
        color: Colors.orange,
        icon: Icons.title,
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final uploadProvider = context.read<UploadProvider>();

    final user = authProvider.firebaseUser;
    if (user == null) {
      SnackBarHelper.showError(context, 'Please login to upload');
      return;
    }

    final userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';

    final success = await uploadProvider.uploadVideo(
      videoFile: _selectedVideo!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      userId: user.uid,
      userName: userName,
      uploadType: _uploadType,
      thumbnailFile: _selectedThumbnail,
    );

    if (mounted) {
      if (success) {
        SnackBarHelper.showSuccess(
          context,
          '${_uploadType == UploadType.video ? 'Video' : 'Short'} uploaded successfully!',
          icon: Icons.cloud_upload,
        );
        // Reset form
        setState(() {
          _selectedVideo = null;
          _selectedThumbnail = null;
          _titleController.clear();
          _descriptionController.clear();
        });
      } else {
        SnackBarHelper.showError(
          context,
          uploadProvider.errorMessage ?? 'Upload failed',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Create Content',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: Consumer<UploadProvider>(
        builder: (context, uploadProvider, child) {
          if (uploadProvider.isUploading) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.red.withValues(alpha: 0.1), Colors.black],
                ),
              ),
              child: Center(
                child: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: 0.9 + (0.1 * value),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          margin: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.red.withValues(alpha: 0.15),
                                Colors.grey[900]!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: CircularProgressIndicator(
                                      value: uploadProvider.uploadProgress,
                                      strokeWidth: 8,
                                      color: Colors.red,
                                      backgroundColor: Colors.grey[800],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.cloud_upload,
                                    size: 40,
                color: Colors.red,
              ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              Text(
                                'Uploading...',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
            ),
            const SizedBox(height: 12),
            Text(
                                '${(uploadProvider.uploadProgress * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Please wait while we upload your content',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
              textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Upload Type Selector with Animation
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 400),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upload Type',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    child: InkWell(
                                      onTap: () {
                                        setState(
                                          () => _uploadType = UploadType.video,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient:
                                              _uploadType == UploadType.video
                                              ? LinearGradient(
                                                  colors: [
                                                    Colors.red.withValues(
                                                      alpha: 0.9,
                                                    ),
                                                    Colors.red.withValues(
                                                      alpha: 0.7,
                                                    ),
                                                  ],
                                                )
                                              : LinearGradient(
                                                  colors: [
                                                    Colors.grey[800]!,
                                                    Colors.grey[850]!,
                                                  ],
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color:
                                                _uploadType == UploadType.video
                                                ? Colors.red
                                                : Colors.grey[600]!,
                                            width: 2,
                                          ),
                                          boxShadow:
                                              _uploadType == UploadType.video
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.red
                                                        .withValues(alpha: 0.4),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.videocam,
                                              color:
                                                  _uploadType ==
                                                      UploadType.video
                                                  ? Colors.white
                                                  : Colors.grey[400],
                                              size: 22,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Video',
                                              style: TextStyle(
                                                color:
                                                    _uploadType ==
                                                        UploadType.video
                                                    ? Colors.white
                                                    : Colors.grey[400],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    child: InkWell(
                                      onTap: () {
                                        setState(
                                          () => _uploadType = UploadType.short,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient:
                                              _uploadType == UploadType.short
                                              ? LinearGradient(
                                                  colors: [
                                                    Colors.red.withValues(
                                                      alpha: 0.9,
                                                    ),
                                                    Colors.red.withValues(
                                                      alpha: 0.7,
                                                    ),
                                                  ],
                                                )
                                              : LinearGradient(
                                                  colors: [
                                                    Colors.grey[800]!,
                                                    Colors.grey[850]!,
                                                  ],
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color:
                                                _uploadType == UploadType.short
                                                ? Colors.red
                                                : Colors.grey[600]!,
                                            width: 2,
                                          ),
                                          boxShadow:
                                              _uploadType == UploadType.short
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.red
                                                        .withValues(alpha: 0.4),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.phonelink,
                                              color:
                                                  _uploadType ==
                                                      UploadType.short
                                                  ? Colors.white
                                                  : Colors.grey[400],
                                              size: 22,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Short',
                                              style: TextStyle(
                                                color:
                                                    _uploadType ==
                                                        UploadType.short
                                                    ? Colors.white
                                                    : Colors.grey[400],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
            ),
          ],
        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Video Picker with Glassy Effect
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: GestureDetector(
                          onTap: _pickVideo,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 220,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _selectedVideo != null
                                    ? [
                                        Colors.red.withValues(alpha: 0.15),
                                        Colors.grey[900]!,
                                      ]
                                    : [Colors.grey[850]!, Colors.grey[900]!],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedVideo != null
                                    ? Colors.red.withValues(alpha: 0.5)
                                    : Colors.grey[700]!,
                                width: 2,
                              ),
                              boxShadow: _selectedVideo != null
                                  ? [
                                      BoxShadow(
                                        color: Colors.red.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: _selectedVideo != null
                                ? Stack(
                                    children: [
                                      Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(
                                                  alpha: 0.2,
                                                ),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.red
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 20,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.video_library,
                                                size: 50,
                                                color: Colors.red,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Video selected ✓',
                                              style: TextStyle(
                                                fontSize: 17,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Tap to change',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              setState(
                                                () => _selectedVideo = null,
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(
                                                  alpha: 0.2,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.video_call_outlined,
                                        size: 70,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Tap to select ${_uploadType == UploadType.video ? 'video' : 'short'}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey[700]!,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.touch_app,
                                              size: 16,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'From Gallery',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Thumbnail Picker with Glassy Effect
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: GestureDetector(
                          onTap: _pickThumbnail,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 110,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _selectedThumbnail != null
                                    ? [
                                        Colors.red.withValues(alpha: 0.1),
                                        Colors.grey[900]!,
                                      ]
                                    : [Colors.grey[850]!, Colors.grey[900]!],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _selectedThumbnail != null
                                    ? Colors.red.withValues(alpha: 0.4)
                                    : Colors.grey[700]!,
                                width: 1.5,
                              ),
                            ),
                            child: _selectedThumbnail != null
                                ? Stack(
                                    children: [
                                      Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(
                                                  alpha: 0.15,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.image,
                                                size: 28,
                                                color: Colors.red,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Thumbnail selected ✓',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              setState(
                                                () => _selectedThumbnail = null,
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(
                                                  alpha: 0.15,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 32,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Add thumbnail (optional)',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Title Input with Glassy Style
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 700),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Title *',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            hintText:
                                'Enter ${_uploadType == UploadType.video ? 'video' : 'short'} title',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.title,
                              color: Colors.red,
                            ),
                          ),
                          maxLength: 100,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Description Input with Glassy Style
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: TextField(
                          controller: _descriptionController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Description (optional)',
                            labelStyle: TextStyle(color: Colors.grey[400]),
                            hintText: 'Describe your content...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.description,
                              color: Colors.red,
                            ),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 4,
                          maxLength: 500,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Upload Button with Glowing Effect
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 900),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: 0.95 + (0.05 * value),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.red.withValues(alpha: 0.95),
                                Colors.red.withValues(alpha: 0.75),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.5),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _uploadVideo,
                            icon: const Icon(Icons.cloud_upload, size: 24),
                            label: const Text(
                              'Upload Content',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
