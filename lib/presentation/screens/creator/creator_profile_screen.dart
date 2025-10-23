import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../home/video_playing_screen.dart';

class CreatorProfileScreen extends StatefulWidget {
  final String creatorId;
  final String creatorName;
  final String creatorAvatar;

  const CreatorProfileScreen({
    super.key,
    required this.creatorId,
    required this.creatorName,
    required this.creatorAvatar,
  });

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _videosCount = 0;
  int _shortsCount = 0;
  int _subscribersCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCreatorStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCreatorStats() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.creatorId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _videosCount = data['uploadedVideosCount'] ?? 0;
          _shortsCount = data['uploadedShortsCount'] ?? 0;
          _subscribersCount = data['subscribersCount'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading creator stats: $e');
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final currentUserId = authProvider.firebaseUser?.uid;
    final isOwnProfile = currentUserId == widget.creatorId;
    final isSubscribed = subscriptionProvider.isSubscribed(widget.creatorId);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Creator Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.red.withValues(alpha: 0.1),
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              children: [
                // Back button and avatar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    // Profile Picture
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundImage: CachedNetworkImageProvider(widget.creatorAvatar),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Channel Name
                Text(
                  widget.creatorName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStat(_formatCount(_subscribersCount), 'Subscribers'),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    _buildStat(_videosCount.toString(), 'Videos'),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    _buildStat(_shortsCount.toString(), 'Shorts'),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Subscribe Button (only show if not own profile)
                if (!isOwnProfile && currentUserId != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        print('👤 Creator profile subscribe button pressed - isSubscribed: $isSubscribed');
                        print('👤 currentUserId: $currentUserId');
                        print('👤 creatorId: ${widget.creatorId}');
                        
                        if (isSubscribed) {
                          print('👤 Calling unsubscribe...');
                          final success = await subscriptionProvider.unsubscribe(
                            userId: currentUserId,
                            channelId: widget.creatorId,
                          );
                          
                          print('👤 Unsubscribe result: $success');
                          
                          if (context.mounted) {
                            if (success) {
                              SnackBarHelper.showInfo(
                                context,
                                'Unsubscribed from ${widget.creatorName}',
                                icon: Icons.notifications_off,
                                color: Colors.orange,
                              );
                              _loadCreatorStats(); // Refresh stats
                            } else {
                              SnackBarHelper.showError(
                                context,
                                'Failed to unsubscribe',
                                icon: Icons.error_outline,
                              );
                            }
                          }
                        } else {
                          print('👤 Calling subscribe...');
                          final success = await subscriptionProvider.subscribe(
                            userId: currentUserId,
                            channelId: widget.creatorId,
                            channelName: widget.creatorName,
                            channelAvatar: widget.creatorAvatar,
                          );
                          
                          print('👤 Subscribe result: $success');
                          
                          if (context.mounted) {
                            if (success) {
                              SnackBarHelper.showSuccess(
                                context,
                                'Subscribed to ${widget.creatorName}',
                                icon: Icons.notifications_active,
                              );
                              _loadCreatorStats(); // Refresh stats
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
                      icon: Icon(
                        isSubscribed ? Icons.notifications_active : Icons.notifications_none,
                        size: 20,
                      ),
                      label: Text(
                        isSubscribed ? 'Subscribed' : 'Subscribe',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSubscribed ? Colors.grey[300] : Colors.red,
                        foregroundColor: isSubscribed ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Tabs
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.red,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.red,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Videos'),
                Tab(text: 'Shorts'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVideosTab(),
                _buildShortsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildVideosTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('videos')
          .where('uploadedBy', isEqualTo: widget.creatorId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No videos yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final video = snapshot.data!.docs[index];
            final data = video.data() as Map<String, dynamic>;
            
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(video: video),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[300],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: data['thumbnailUrl'] != null
                            ? CachedNetworkImage(
                                imageUrl: data['thumbnailUrl'],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(color: Colors.red),
                                ),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              )
                            : const Icon(Icons.video_library, size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    data['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Views
                  Text(
                    '${_formatCount(data['views'] ?? 0)} views',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShortsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shorts')
          .where('uploadedBy', isEqualTo: widget.creatorId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No shorts yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final short = snapshot.data!.docs[index];
            final data = short.data() as Map<String, dynamic>;
            
            return InkWell(
              onTap: () {
                // TODO: Navigate to shorts player at this index
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      data['thumbnailUrl'] != null
                          ? CachedNetworkImage(
                              imageUrl: data['thumbnailUrl'],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(color: Colors.red),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            )
                          : const Icon(Icons.play_circle, size: 40),
                      // Views overlay
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Row(
                          children: [
                            const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _formatCount(data['views'] ?? 0),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

