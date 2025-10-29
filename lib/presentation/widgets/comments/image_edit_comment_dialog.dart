import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/image_comment_provider.dart';

class ImageEditCommentDialog extends StatefulWidget {
  final String commentId;
  final String imagePostId;
  final String initialText;

  const ImageEditCommentDialog({
    super.key,
    required this.commentId,
    required this.imagePostId,
    required this.initialText,
  });

  @override
  State<ImageEditCommentDialog> createState() => _ImageEditCommentDialogState();
}

class _ImageEditCommentDialogState extends State<ImageEditCommentDialog> {
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _saveEdit() {
    if (_editController.text.trim().isEmpty) return;

    final imageCommentProvider = context.read<ImageCommentProvider>();
    imageCommentProvider.editComment(
      widget.imagePostId,
      widget.commentId,
      _editController.text,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Edit Comment',
        style: TextStyle(
          color: AppConstants.textPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: TextField(
        controller: _editController,
        autofocus: true,
        maxLines: 3,
        style: const TextStyle(color: AppConstants.textPrimaryColor),
        decoration: InputDecoration(
          hintText: 'Edit your comment...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppConstants.primaryColor, width: 2),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _saveEdit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

