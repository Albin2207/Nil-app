import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nil_app/presentation/providers/upload_provider.dart' show UploadProvider, UploadType;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../providers/auth_provider.dart';

import 'widgets/upload_progress_widget.dart';
import 'widgets/upload_type_selector.dart';

/// Create/Upload screen for videos and shorts
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
        setState(() => _selectedVideo = File(video.path));
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
        setState(() => _selectedThumbnail = File(image.path));
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
            return UploadProgressWidget(progress: uploadProvider.uploadProgress);
          }

          return _buildUploadForm();
        },
      ),
    );
  }

  Widget _buildUploadForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UploadTypeSelector(
            selectedType: _uploadType,
            onTypeChanged: (type) => setState(() => _uploadType = type),
          ),
          const SizedBox(height: 28),
          _buildVideoPicker(),
          if (_selectedVideo != null) ...[
            const SizedBox(height: 20),
            _buildThumbnailPicker(),
            const SizedBox(height: 24),
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 32),
            _buildUploadButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoPicker() {
    return GestureDetector(
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
        ),
        child: _selectedVideo != null
            ? Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
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
                          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
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
                        onTap: () => setState(() => _selectedVideo = null),
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.red, size: 20),
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
                    color: Colors.grey[600],
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
                  Text(
                    _uploadType == UploadType.video
                        ? 'Maximum 15 minutes'
                        : 'Maximum 60 seconds',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildThumbnailPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thumbnail',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickThumbnail,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: _selectedThumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedThumbnail!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 40, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text(
                          'Select thumbnail',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Title *',
        labelStyle: const TextStyle(color: Colors.grey),
        hintText: 'Enter video title',
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      style: const TextStyle(color: Colors.white),
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'Description',
        labelStyle: const TextStyle(color: Colors.grey),
        hintText: 'Tell viewers about your video',
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return ElevatedButton(
      onPressed: _uploadVideo,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        shadowColor: Colors.red.withValues(alpha: 0.5),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload, color: Colors.white),
          SizedBox(width: 12),
          Text(
            'Upload',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

