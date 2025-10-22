import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/comment_model.dart';
import '../../providers/comment_provider.dart';
import 'comments_bottom_sheet.dart';

class CommentsPreviewWidget extends StatelessWidget {
  final String videoId;

  const CommentsPreviewWidget({
    super.key,
    required this.videoId,
  });

  void _openCommentsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      transitionAnimationController: null,
      builder: (context) => CommentsBottomSheet(videoId: videoId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommentProvider>(
      builder: (context, provider, child) {
        return StreamBuilder<List<CommentModel>>(
          stream: provider.getCommentsStream(videoId),
          builder: (context, snapshot) {
            final commentCount = snapshot.hasData
                ? provider.getTopLevelComments(snapshot.data!).length
                : 0;

            return InkWell(
              onTap: () => _openCommentsBottomSheet(context),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$commentCount',
                      style: AppConstants.captionTextStyle,
                    ),
                    const Spacer(),
                    Icon(Icons.expand_more, color: Colors.grey[600]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

