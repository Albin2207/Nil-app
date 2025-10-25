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
          padding: const EdgeInsets.only(
            left: AppConstants.defaultPadding,
            right: AppConstants.defaultPadding,
            top: AppConstants.defaultPadding,
            bottom: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${FormatHelper.formatCount(currentViews)} views • ${timeago.format(timestamp.toDate())}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

