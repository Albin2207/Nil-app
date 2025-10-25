import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/format_helper.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../screens/creator_profile_screen.dart';

class ChannelInfoWidget extends StatelessWidget {
  final String channelName;
  final String channelAvatar;
  final int subscribers;
  final String? channelId;

  const ChannelInfoWidget({
    super.key,
    required this.channelName,
    required this.channelAvatar,
    required this.subscribers,
    this.channelId,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final currentUserId = authProvider.firebaseUser?.uid;
    
    // Don't show subscribe button if it's the user's own content or no channelId
    final showSubscribeButton = channelId != null && 
                                 currentUserId != null && 
                                 channelId != currentUserId;
    
    final isSubscribed = channelId != null 
        ? subscriptionProvider.isSubscribed(channelId!) 
        : false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Row(
        children: [
          // Avatar - Tappable to navigate to creator profile
          InkWell(
            onTap: channelId != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreatorProfileScreen(
                          creatorId: channelId!,
                          creatorName: channelName,
                          creatorAvatar: channelAvatar,
                        ),
                      ),
                    );
                  }
                : null,
            child: CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(channelAvatar),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: channelId != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatorProfileScreen(
                            creatorId: channelId!,
                            creatorName: channelName,
                            creatorAvatar: channelAvatar,
                          ),
                        ),
                      );
                    }
                  : null,
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
                  StreamBuilder<int>(
                    stream: channelId != null
                        ? subscriptionProvider.getSubscriberCountStream(channelId!)
                        : Stream.value(subscribers),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? subscribers;
                      return Text(
                        '${FormatHelper.formatCount(count)} subscribers',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (showSubscribeButton)
            ElevatedButton(
              onPressed: () async {
                print('📹 Video player subscribe button pressed - isSubscribed: $isSubscribed');
                print('📹 currentUserId: $currentUserId');
                print('📹 channelId: $channelId');
                
                if (isSubscribed) {
                  print('📹 Calling unsubscribe...');
                  final success = await subscriptionProvider.unsubscribe(
                    userId: currentUserId,
                    channelId: channelId!,
                  );
                  
                  print('📹 Unsubscribe result: $success');
                  
                  if (context.mounted) {
                    if (success) {
                      SnackBarHelper.showInfo(
                        context,
                        'Unsubscribed from $channelName',
                        icon: Icons.notifications_off,
                        color: Colors.orange,
                      );
                    } else {
                      SnackBarHelper.showError(
                        context,
                        'Failed to unsubscribe',
                        icon: Icons.error_outline,
                      );
                    }
                  }
                } else {
                  print('📹 Calling subscribe...');
                  final success = await subscriptionProvider.subscribe(
                    userId: currentUserId,
                    channelId: channelId!,
                    channelName: channelName,
                    channelAvatar: channelAvatar,
                  );
                  
                  print('📹 Subscribe result: $success');
                  
                  if (context.mounted) {
                    if (success) {
                      SnackBarHelper.showSuccess(
                        context,
                        'Subscribed to $channelName',
                        icon: Icons.notifications_active,
                      );
                    } else {
                      SnackBarHelper.showError(
                        context,
                        'Failed to subscribe. Check console for details.',
                        icon: Icons.error_outline,
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSubscribed ? Colors.grey[200] : Colors.red,
                foregroundColor: isSubscribed ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                isSubscribed ? 'Subscribed' : 'Subscribe',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
