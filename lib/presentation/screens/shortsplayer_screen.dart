import 'package:flutter/material.dart';
import 'package:nil_app/data/models/shorts_model.dart';
import 'package:provider/provider.dart';
import '../providers/shorts_provider.dart';
import '../widgets/action_button.dart';

class ShortsPlayerScreen extends StatefulWidget {
  final int initialIndex;

  const ShortsPlayerScreen({super.key, required this.initialIndex});

  @override
  State<ShortsPlayerScreen> createState() => _ShortsPlayerScreenState();
}

class _ShortsPlayerScreenState extends State<ShortsPlayerScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shorts = context.watch<ShortProvider>().shorts;

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: shorts.length,
        onPageChanged: (index) {
          setState(() {});
        },
        itemBuilder: (context, index) {
          return _ShortPlayer(short: shorts[index]);
        },
      ),
    );
  }
}

class _ShortPlayer extends StatelessWidget {
  final Short short;

  const _ShortPlayer({required this.short});

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShortProvider>();

    return Stack(
      children: [
        // Video Thumbnail (Full Screen)
        Positioned.fill(
          child: Image.network(short.thumbnail, fit: BoxFit.cover),
        ),

        // Bottom Info Section
        Positioned(
          bottom: 0,
          left: 0,
          right: 80,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 18,
                      child: Text(
                        short.channelAvatar,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      short.channelHandle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => provider.toggleSubscribe(short.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: short.isSubscribed
                              ? Colors.grey.shade800
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          short.isSubscribed ? 'Subscribed' : 'Subscribe',
                          style: TextStyle(
                            color: short.isSubscribed
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  short.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        // Right Side Action Buttons
        Positioned(
          right: 8,
          bottom: 100,
          child: Column(
            children: [
              ActionButton(
                icon: Icons.thumb_up,
                label: _formatNumber(short.likes),
                isActive: short.isLiked,
                onTap: () => provider.toggleLike(short.id),
              ),
              const SizedBox(height: 24),
              ActionButton(
                icon: Icons.thumb_down,
                label: 'Dislike',
                isActive: short.isDisliked,
                onTap: () => provider.toggleDislike(short.id),
              ),
              const SizedBox(height: 24),
              ActionButton(
                icon: Icons.comment,
                label: _formatNumber(short.comments),
                onTap: () {},
              ),
              const SizedBox(height: 24),
              ActionButton(icon: Icons.share, label: 'Share', onTap: () {}),
              const SizedBox(height: 24),
              ActionButton(icon: Icons.repeat, label: 'Remix', onTap: () {}),
            ],
          ),
        ),

        // Back Button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }
}
