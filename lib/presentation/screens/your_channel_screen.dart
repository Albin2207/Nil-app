import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import 'moderation_screen.dart';

class YourChannelScreen extends StatelessWidget {
  const YourChannelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Channel',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          final hasContent = (user?.uploadedVideosCount ?? 0) > 0 || (user?.uploadedShortsCount ?? 0) > 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.withValues(alpha: 0.3),
                        Colors.red.withValues(alpha: 0.1),
                        Colors.black,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: user?.photoUrl != null 
                            ? NetworkImage(user!.photoUrl!) 
                            : null,
                        child: user?.photoUrl == null
                            ? Text(
                                (user?.name ?? 'User').isNotEmpty 
                                    ? (user!.name[0].toUpperCase()) 
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? 'Your Channel',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasContent ? 'Content Creator' : 'Start creating content',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (hasContent) ...[
                  // Channel Statistics
                  _buildChannelStats(context, user),
                  const SizedBox(height: 24),
                  
                  // Engagement Stats
                  _buildEngagementStats(context, user),
                  const SizedBox(height: 24),
                  
                  // Moderation Section
                  _buildModerationSection(context),
                ] else ...[
                  // No content yet
                  _buildNoContentSection(context),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChannelStats(BuildContext context, dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Channel Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Videos',
                '${user?.uploadedVideosCount ?? 0}',
                Icons.play_circle_outline,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Shorts',
                '${user?.uploadedShortsCount ?? 0}',
                Icons.short_text,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            int subscribersCount = 0;
            if (snapshot.hasData && snapshot.data != null) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              subscribersCount = data?['subscribersCount'] ?? 0;
            }
            return _buildStatCard(
              'Subscribers',
              _formatCount(subscribersCount),
              Icons.people_outline,
              Colors.blue,
            );
          },
        ),
      ],
    );
  }

  Widget _buildEngagementStats(BuildContext context, dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Engagement Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, int>>(
          future: _getEngagementStats(user?.uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: Colors.red,
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            final stats = snapshot.data!;
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Views',
                        _formatCount(stats['views'] ?? 0),
                        Icons.visibility_outlined,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Total Likes',
                        _formatCount(stats['likes'] ?? 0),
                        Icons.thumb_up_outlined,
                        Colors.pink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Comments',
                        _formatCount(stats['comments'] ?? 0),
                        Icons.comment_outlined,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Shares',
                        _formatCount(stats['shares'] ?? 0),
                        Icons.share_outlined,
                        Colors.cyan,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildModerationSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Moderation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Manage reported content and moderate your channel',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModerationScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Open Moderation Panel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoContentSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No content yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start uploading videos or shorts to manage your channel',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _getEngagementStats(String? userId) async {
    if (userId == null) {
      return {
        'views': 0,
        'likes': 0,
        'comments': 0,
        'shares': 0,
      };
    }

    try {
      int totalViews = 0;
      int totalLikes = 0;
      int totalComments = 0;
      int totalShares = 0;

      // Get all videos by this user
      final videosSnapshot = await FirebaseFirestore.instance
          .collection('videos')
          .where('uploadedBy', isEqualTo: userId)
          .get();

      for (var doc in videosSnapshot.docs) {
        final data = doc.data();
        totalViews += (data['viewsCount'] as int? ?? 0);
        totalLikes += (data['likesCount'] as int? ?? 0);
        totalShares += (data['sharesCount'] as int? ?? 0);
        
        // Count comments for this video
        final commentsSnapshot = await FirebaseFirestore.instance
            .collection('comments')
            .where('videoId', isEqualTo: doc.id)
            .get();
        totalComments += commentsSnapshot.docs.length;
      }

      // Get all shorts by this user
      final shortsSnapshot = await FirebaseFirestore.instance
          .collection('shorts')
          .where('uploadedBy', isEqualTo: userId)
          .get();

      for (var doc in shortsSnapshot.docs) {
        final data = doc.data();
        totalViews += (data['viewsCount'] as int? ?? 0);
        totalLikes += (data['likesCount'] as int? ?? 0);
        totalShares += (data['sharesCount'] as int? ?? 0);
        
        // Count comments for this short
        final commentsSnapshot = await FirebaseFirestore.instance
            .collection('comments')
            .where('videoId', isEqualTo: doc.id)
            .get();
        totalComments += commentsSnapshot.docs.length;
      }

      return {
        'views': totalViews,
        'likes': totalLikes,
        'comments': totalComments,
        'shares': totalShares,
      };
    } catch (e) {
      debugPrint('Error getting engagement stats: $e');
      return {
        'views': 0,
        'likes': 0,
        'comments': 0,
        'shares': 0,
      };
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
}
