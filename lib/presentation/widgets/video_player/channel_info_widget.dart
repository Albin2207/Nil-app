import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/format_helper.dart';
import '../../providers/video_provider.dart';

class ChannelInfoWidget extends StatelessWidget {
  final String channelName;
  final String channelAvatar;
  final int subscribers;

  const ChannelInfoWidget({
    super.key,
    required this.channelName,
    required this.channelAvatar,
    required this.subscribers,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(channelAvatar),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channelName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${FormatHelper.formatCount(subscribers)} subscribers',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Consumer<VideoProvider>(
            builder: (context, provider, child) {
              return ElevatedButton(
                onPressed: () => provider.toggleSubscribe(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.isSubscribed
                      ? Colors.grey[200]
                      : AppConstants.primaryColor,
                  foregroundColor: provider.isSubscribed
                      ? AppConstants.textPrimaryColor
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  provider.isSubscribed ? 'Subscribed' : 'Subscribe',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

