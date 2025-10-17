import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/upload_provider.dart';
import '../providers/auth_provider.dart';

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
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );
      
      if (video != null) {
        setState(() {
          _selectedVideo = File(video.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (image != null) {
        setState(() {
          _selectedThumbnail = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking thumbnail: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadVideo() async {
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final uploadProvider = context.read<UploadProvider>();
    
    final user = authProvider.firebaseUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to upload'),
          backgroundColor: Colors.red,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload successful!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reset form
        setState(() {
          _selectedVideo = null;
          _selectedThumbnail = null;
          _titleController.clear();
          _descriptionController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uploadProvider.errorMessage ?? 'Upload failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Content',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Consumer<UploadProvider>(
        builder: (context, uploadProvider, child) {
          if (uploadProvider.isUploading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: uploadProvider.uploadProgress,
                    strokeWidth: 6,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Uploading... ${(uploadProvider.uploadProgress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please wait while we upload your content',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Upload Type Selector
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Video'),
                        selected: _uploadType == UploadType.video,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _uploadType = UploadType.video);
                          }
                        },
                        selectedColor: Colors.red,
                        labelStyle: TextStyle(
                          color: _uploadType == UploadType.video
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Short'),
                        selected: _uploadType == UploadType.short,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _uploadType = UploadType.short);
                          }
                        },
                        selectedColor: Colors.red,
                        labelStyle: TextStyle(
                          color: _uploadType == UploadType.short
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Video Picker
                GestureDetector(
                  onTap: _pickVideo,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedVideo != null
                            ? Colors.red
                            : Colors.grey[300]!,
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
                                    const Icon(
                                      Icons.video_library,
                                      size: 60,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Video selected',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    setState(() => _selectedVideo = null);
                                  },
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.video_call_outlined,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to select video',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Thumbnail Picker (Optional)
                GestureDetector(
                  onTap: _pickThumbnail,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedThumbnail != null
                            ? Colors.red
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: _selectedThumbnail != null
                        ? Stack(
                            children: [
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.image,
                                      size: 30,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Thumbnail selected',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    setState(() => _selectedThumbnail = null);
                                  },
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 30,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add thumbnail (optional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title Input
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Enter video title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 16),

                // Description Input
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter video description (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),
                const SizedBox(height: 24),

                // Upload Button
                ElevatedButton(
                  onPressed: _uploadVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Upload',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
