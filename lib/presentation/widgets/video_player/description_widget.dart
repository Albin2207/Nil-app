import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/format_helper.dart';

class DescriptionWidget extends StatelessWidget {
  final String description;
  final int likes;
  final int views;
  final Timestamp timestamp;

  const DescriptionWidget({
    super.key,
    required this.description,
    required this.likes,
    required this.views,
    required this.timestamp,
  });

  void _showDescriptionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.grey),
              // Description content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.thumb_up_outlined,
                              label: 'Likes',
                              value: FormatHelper.formatCount(likes),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.visibility_outlined,
                              label: 'Views',
                              value: FormatHelper.formatCount(views),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoCard(
                              icon: Icons.calendar_today_outlined,
                              label: 'Uploaded',
                              value: timeago.format(timestamp.toDate()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Description text
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.defaultPadding,
        right: AppConstants.defaultPadding,
        top: 4,
        bottom: 8,
      ),
      child: InkWell(
        onTap: () => _showDescriptionSheet(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withValues(alpha: 0.08),
                Colors.grey[900]!.withValues(alpha: 0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text: description.length > 50 
                            ? '${description.substring(0, 50)}...' 
                            : description,
                      ),
                      TextSpan(
                        text: ' more',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.1),
            Colors.grey[850]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.red,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

