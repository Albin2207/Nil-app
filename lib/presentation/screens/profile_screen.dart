import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../../data/models/subscription_model.dart';
import 'login_screen.dart';
import 'video_playing_screen.dart';
import 'shorts_screen_new.dart';
import 'creator_profile_screen.dart';
import '../../core/utils/snackbar_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  // Fix negative counts (one-time use)
  Future<void> _fixNegativeCounts(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.firebaseUser?.uid;
    
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'uploadedVideosCount': FieldValue.increment(0), // Ensure it exists
        'uploadedShortsCount': 0, // Reset to 0
      });

      if (context.mounted) {
        SnackBarHelper.showSuccess(
          context,
          '✅ Counts fixed! Refresh the page.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(
          context,
          'Error: $e',
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[900]!.withValues(alpha: 0.95),
                Colors.grey[850]!.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to logout?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[700]!, width: 1),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey[300], fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await authProvider.signOut();
      // Navigation happens automatically when firebaseUser becomes null (see build method)
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.firebaseUser?.uid;

    if (userId == null) return;

    // Show warning dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete Account', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is permanent and cannot be undone.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'All your data will be permanently deleted:',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text('• Your profile', style: TextStyle(color: Colors.white70)),
            Text('• All uploaded videos', style: TextStyle(color: Colors.white70)),
            Text('• All uploaded shorts', style: TextStyle(color: Colors.white70)),
            Text('• Your comments', style: TextStyle(color: Colors.white70)),
            Text('• Your playlists', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 16),
            Text(
              'Are you absolutely sure?',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    try {
      // 1. Delete all user's videos
      final videosQuery = await FirebaseFirestore.instance
          .collection('videos')
          .where('uploadedBy', isEqualTo: userId)
          .get();

      for (var doc in videosQuery.docs) {
        await doc.reference.delete();
      }

      // 2. Delete all user's shorts
      final shortsQuery = await FirebaseFirestore.instance
          .collection('shorts')
          .where('uploadedBy', isEqualTo: userId)
          .get();

      for (var doc in shortsQuery.docs) {
        await doc.reference.delete();
      }

      // 3. Delete user document
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      // 4. Delete Firebase Auth account
      await firebase_auth.FirebaseAuth.instance.currentUser?.delete();

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show success and navigate to login
      if (context.mounted) {
        SnackBarHelper.showSuccess(
          context,
          'Account deleted successfully',
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show error
      if (context.mounted) {
        SnackBarHelper.showError(
          context,
          'Error deleting account: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final firebaseUser = authProvider.firebaseUser;

          if (firebaseUser == null) {
            // If user is null, navigate to login screen immediately
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            });
            
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          final user = authProvider.currentUser;
          final displayName = user?.name ?? firebaseUser.displayName ?? 'User';
          final displayEmail = user?.email ?? firebaseUser.email ?? 'No email';
          final photoUrl = user?.photoUrl ?? firebaseUser.photoURL;
          final userId = firebaseUser.uid;

          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.red.withValues(alpha: 0.4),
                            Colors.red.withValues(alpha: 0.2),
                            Colors.red.withValues(alpha: 0.05),
                            Colors.black,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          
                          // Profile Picture - CENTERED & BIGGER
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 600),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Opacity(
                                  opacity: value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.red, width: 4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withValues(alpha: 0.6 * value),
                                          blurRadius: 28,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 55,
                                      backgroundColor: Colors.grey[800],
                                      backgroundImage: photoUrl != null 
                                          ? NetworkImage(photoUrl) 
                                          : null,
                                      child: photoUrl == null
                                          ? Text(
                                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                              style: const TextStyle(
                                                fontSize: 40,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Name - CENTERED & BIGGER
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Email - CENTERED
                          Text(
                            displayEmail,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[300],
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Stats Row with Glass Effect
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStat('Videos', user?.uploadedVideosCount ?? 0),
                                Container(
                                  height: 48,
                                  width: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                _buildStat('Shorts', user?.uploadedShortsCount ?? 0),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Logout Button - CENTERED
                          ElevatedButton.icon(
                            onPressed: () => _handleLogout(context),
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withValues(alpha: 0.2),
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: BorderSide(color: Colors.red.withValues(alpha: 0.5), width: 1),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Scroll Indicator - For All Content Below
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 1500),
                            tween: Tween<double>(begin: 0, end: 8),
                            builder: (context, double value, child) {
                              return Transform.translate(
                                offset: Offset(0, value),
                                child: Opacity(
                                  opacity: 0.5,
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.keyboard_double_arrow_down,
                                        color: Colors.grey[400],
                                        size: 22,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Scroll to see your content',
          style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            onEnd: () {
                              // Loop animation by rebuilding
                              if (mounted) {
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  if (mounted) setState(() {});
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.red,
                        labelColor: Colors.red,
                        unselectedLabelColor: Colors.grey[400],
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        labelPadding: const EdgeInsets.symmetric(vertical: 12),
                        tabs: const [
                          Tab(text: 'Your Account'),
                          Tab(text: 'Subscriptions'),
                          Tab(text: 'Settings'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildYourAccountTab(userId, user),
                  _buildSubscriptionsTab(userId),
                  _buildSettingsTab(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, int count) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Column(
              children: [
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.red,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[300],
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // New: Your Account Tab with nested tabs for Videos/Shorts and Channel Stats
  Widget _buildYourAccountTab(String userId, dynamic user) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Channel Stats Section - More compact
          Flexible(
            flex: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.withValues(alpha: 0.15),
                  Colors.red.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildChannelStat(
                  'Videos',
                  user?.uploadedVideosCount ?? 0,
                  Icons.play_circle_outline,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.red.withValues(alpha: 0.3),
                ),
                _buildChannelStat(
                  'Shorts',
                  user?.uploadedShortsCount ?? 0,
                  Icons.video_library_outlined,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.red.withValues(alpha: 0.3),
                ),
                Consumer<SubscriptionProvider>(
                  builder: (context, subscriptionProvider, child) {
                    return StreamBuilder<int>(
                      stream: subscriptionProvider.getSubscriberCountStream(userId),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? (user?.subscribersCount ?? 0);
                        return _buildChannelStat(
                          'Subscribers',
                          count,
                          Icons.people_outline,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            ),
          ),
          
          // Sub-tabs for Videos and Shorts
          Container(
            color: Colors.black,
            child: TabBar(
              indicatorColor: Colors.red,
              labelColor: Colors.red,
              unselectedLabelColor: Colors.grey[400],
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Your Videos'),
                Tab(text: 'Your Shorts'),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              children: [
                _buildVideosTab(userId),
                _buildShortsTab(userId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelStat(String label, int count, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.red, size: 20),
        const SizedBox(height: 6),
        Text(
          _formatCount(count),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildVideosTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('videos')
          .where('uploadedBy', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No videos uploaded yet',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final video = snapshot.data!.docs[index];
            return _buildVideoItem(video, isShort: false);
          },
        );
      },
    );
  }

  Widget _buildShortsTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shorts')
          .where('uploadedBy', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No shorts uploaded yet',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 9 / 16,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final short = snapshot.data!.docs[index];
            return _buildShortItem(short);
          },
        );
      },
    );
  }

  Widget _buildVideoItem(QueryDocumentSnapshot video, {required bool isShort}) {
    final data = video.data() as Map<String, dynamic>;

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(video: video),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: data['thumbnailUrl'] ?? '',
                  width: 120,
                  height: 70,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.error, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Video Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${data['views'] ?? 0} views',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),

              // Delete Button
          IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDeleteContent(video.id, 'video'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortItem(QueryDocumentSnapshot short) {
    final data = short.data() as Map<String, dynamic>;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ShortsScreen(),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: data['thumbnailUrl'] ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[800],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[800],
                child: const Icon(Icons.error, color: Colors.grey),
              ),
            ),
          ),

          // Overlay gradient
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),

          // Views count
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${data['views'] ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Delete button
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
              ),
              onPressed: () => _confirmDeleteContent(short.id, 'short'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsTab(String userId) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();

    return StreamBuilder<List<SubscriptionModel>>(
      stream: subscriptionProvider.getSubscriptionsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                Icon(
                  Icons.subscriptions_outlined,
                  size: 80,
                  color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
                Text(
                  'No subscriptions yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Subscribe to channels to see them here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final subscriptions = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subscriptions.length,
          itemBuilder: (context, index) {
            final subscription = subscriptions[index];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: CachedNetworkImageProvider(
                      subscription.channelAvatar,
                    ),
                  ),
                ),
                title: Text(
                  subscription.channelName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                subtitle: StreamBuilder<int>(
                  stream: subscriptionProvider.getSubscriberCountStream(
                    subscription.channelId,
                  ),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Text(
                      '${_formatCount(count)} subscribers',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final success = await subscriptionProvider.unsubscribe(
                      userId: userId,
                      channelId: subscription.channelId,
                    );
                    
                    if (success && mounted) {
                      SnackBarHelper.showInfo(
                        context,
                        'Unsubscribed from ${subscription.channelName}',
                        icon: Icons.notifications_off,
                        color: Colors.orange,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Subscribed',
              style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreatorProfileScreen(
                        creatorId: subscription.channelId,
                        creatorName: subscription.channelName,
                        creatorAvatar: subscription.channelAvatar,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsTab(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Fix Button (Hidden feature for fixing negative counts)
        if ((user?.uploadedVideosCount ?? 0) < 0 || (user?.uploadedShortsCount ?? 0) < 0)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.build, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Fix Negative Counts',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Detected negative count. Tap to reset.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _fixNegativeCounts(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Fix Now'),
                ),
              ],
            ),
          ),
        
        // Account Info Section
        const Text(
          'Account Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        _buildInfoCard(
          icon: Icons.email_outlined,
          title: 'Email',
          subtitle: user?.email ?? 'No email',
        ),
        const SizedBox(height: 12),

        _buildInfoCard(
          icon: Icons.calendar_today,
          title: 'Member Since',
          subtitle: user != null ? _formatDate(user.createdAt) : 'Just now',
        ),

        if (user?.lastLogin != null) ...[
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.access_time,
            title: 'Last Login',
            subtitle: _formatDate(user!.lastLogin!),
          ),
        ],

        const SizedBox(height: 32),

        // Danger Zone
        const Text(
          'Danger Zone',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Delete Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            Text(
                'Permanently delete your account and all your content. This action cannot be undone.',
              style: TextStyle(
                fontSize: 14,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleDeleteAccount(context),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete Account Permanently'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteContent(String id, String type) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Delete ${type == 'video' ? 'Video' : 'Short'}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'This $type will be permanently deleted.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        // Delete the content
        await FirebaseFirestore.instance
            .collection(type == 'video' ? 'videos' : 'shorts')
            .doc(id)
            .delete();

        // Update user's count (only if it's greater than 0)
        final authProvider = context.read<AuthProvider>();
        final userId = authProvider.firebaseUser?.uid;
        if (userId != null) {
          final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
          final userDoc = await userRef.get();
          
          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            
            if (type == 'video') {
              final currentCount = data['uploadedVideosCount'] ?? 0;
              if (currentCount > 0) {
                await userRef.update({
                  'uploadedVideosCount': FieldValue.increment(-1),
                });
              }
            } else {
              final currentCount = data['uploadedShortsCount'] ?? 0;
              if (currentCount > 0) {
                await userRef.update({
                  'uploadedShortsCount': FieldValue.increment(-1),
                });
              }
            }
          }
        }

        if (mounted) {
          SnackBarHelper.showSuccess(
            context,
            '${type == 'video' ? 'Video' : 'Short'} deleted successfully',
          );
        }
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(
            context,
            'Error deleting $type: $e',
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// Custom delegate for pinned tab bar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
