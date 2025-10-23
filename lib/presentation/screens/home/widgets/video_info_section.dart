import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Video information section with channel avatar, title, views, timestamp
class VideoInfoSection extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onMoreOptions;

  const VideoInfoSection({
    super.key,
    required this.data,
    required this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChannelAvatar(),
          const SizedBox(width: 12),
          _buildVideoDetails(),
          _buildMoreButton(),
        ],
      ),
    );
  }

  Widget _buildChannelAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(
          data['channelAvatar'] ?? 'https://i.pravatar.cc/150?img=2',
        ),
      ),
    );
  }

  Widget _buildVideoDetails() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['title'] ?? 'Untitled Video',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            data['channelName'] ?? 'Unknown Channel',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.visibility, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                '${_formatCount(data['views'] ?? 0)} views',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(width: 8),
              Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  data['timestamp'] != null
                      ? timeago.format((data['timestamp'] as Timestamp).toDate())
                      : 'Recently',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoreButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[400]),
        onPressed: onMoreOptions,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

