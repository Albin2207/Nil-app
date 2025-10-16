import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/format_helper.dart';

class VideoInfoWidget extends StatelessWidget {
  final String videoId;
  final String title;
  final int views;
  final Timestamp timestamp;

  const VideoInfoWidget({
    super.key,
    required this.videoId,
    required this.title,
    required this.views,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.videosCollection)
          .doc(videoId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final currentViews = data?['views'] ?? views;

        return Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppConstants.titleTextStyle,
              ),
              const SizedBox(height: 8),
              Text(
                '${FormatHelper.formatCount(currentViews)} views • ${timeago.format(timestamp.toDate())}',
                style: AppConstants.captionTextStyle,
              ),
            ],
          ),
        );
      },
    );
  }
}

