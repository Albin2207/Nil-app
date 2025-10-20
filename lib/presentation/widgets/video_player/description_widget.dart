import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/video_provider.dart';

class DescriptionWidget extends StatelessWidget {
  final String description;

  const DescriptionWidget({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Consumer<VideoProvider>(
        builder: (context, provider, child) {
          return GestureDetector(
            onTap: () => provider.toggleDescriptionExpansion(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[700]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    maxLines: provider.isDescriptionExpanded ? null : 3,
                    overflow: provider.isDescriptionExpanded
                        ? null
                        : TextOverflow.ellipsis,
                  ),
                  if (description.length > 100)
                    Text(
                      provider.isDescriptionExpanded ? 'Show less' : 'Show more',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

