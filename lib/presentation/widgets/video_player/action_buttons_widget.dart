import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/format_helper.dart';
import '../../providers/video_provider.dart';

class ActionButtonsWidget extends StatelessWidget {
  final String videoId;
  final int initialLikes;
  final String videoTitle;
  final String videoUrl;

  const ActionButtonsWidget({
    super.key,
    required this.videoId,
    required this.initialLikes,
    required this.videoTitle,
    required this.videoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.smallPadding),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Like Button with Real-time Count
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.videosCollection)
                  .doc(videoId)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final currentLikes = data?['likes'] ?? initialLikes;
                
                return Consumer<VideoProvider>(
                  builder: (context, provider, child) {
                    return _ActionButton(
                      icon: provider.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      label: FormatHelper.formatCount(currentLikes),
                      onTap: () => provider.toggleLike(),
                      isActive: provider.isLiked,
                    );
                  },
                );
              },
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Consumer<VideoProvider>(
              builder: (context, provider, child) {
                return _ActionButton(
                  icon: provider.isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                  label: 'Dislike',
                  onTap: () => provider.toggleDislike(),
                  isActive: provider.isDisliked,
                );
              },
            ),
            const SizedBox(width: AppConstants.smallPadding),
            _ActionButton(
              icon: Icons.share_outlined,
              label: 'Share',
              onTap: () => Share.share(
                'Check out this video: $videoTitle\n$videoUrl',
                subject: videoTitle,
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            _ActionButton(
              icon: Icons.download_outlined,
              label: 'Download',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download feature coming soon')),
                );
              },
            ),
            const SizedBox(width: AppConstants.smallPadding),
            _ActionButton(
              icon: Icons.playlist_add,
              label: 'Save',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved to Watch Later')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: AppConstants.iconSizeMedium,
              color: isActive ? AppConstants.primaryColor : AppConstants.textPrimaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? AppConstants.primaryColor : AppConstants.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

