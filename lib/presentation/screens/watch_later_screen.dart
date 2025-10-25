import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/services/watch_later_service.dart';
import '../../data/models/watch_later_model.dart';
import '../providers/auth_provider.dart';
import 'video_playing_screen.dart';
import 'main_screen.dart';

class WatchLaterScreen extends StatefulWidget {
  const WatchLaterScreen({super.key});

  @override
  State<WatchLaterScreen> createState() => _WatchLaterScreenState();
}

class _WatchLaterScreenState extends State<WatchLaterScreen> {
  void _showClearWatchLaterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Clear Watch Later',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to clear all items from your Watch Later list?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final userId = authProvider.firebaseUser?.uid;
                if (userId != null) {
                  await WatchLaterService.clearWatchLater(userId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Watch Later list cleared'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.watch_later_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No videos in Watch Later',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save videos to watch them later',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchLaterItem(BuildContext context, WatchLaterModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
         onTap: () async {
           // Fetch the content document from Firestore based on contentType
           try {
             final collection = item.contentType == 'video' ? 'videos' : 'shorts';
             final contentDoc = await FirebaseFirestore.instance
                 .collection(collection)
                 .doc(item.contentId)
                 .get();
             
             if (contentDoc.exists && mounted) {
               if (item.contentType == 'video') {
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => VideoPlayerScreen(
                       video: contentDoc,
                     ),
                   ),
                 );
               } else {
                 // For shorts, navigate to main screen with Shorts tab
                 Navigator.of(context).pushAndRemoveUntil(
                   MaterialPageRoute(
                     builder: (context) => const MainScreen(initialTab: 1), // 1 = Shorts tab
                   ),
                   (route) => false, // Remove all previous routes
                 );
                 // Show a message
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(
                     content: Text('Opening Shorts tab...'),
                     backgroundColor: Colors.blue,
                     duration: Duration(seconds: 2),
                   ),
                 );
               }
             } else if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: Text('${item.contentType == 'video' ? 'Video' : 'Short'} not found'),
                   backgroundColor: Colors.red,
                 ),
               );
             }
           } catch (e) {
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(
                   content: Text('Error loading content'),
                   backgroundColor: Colors.red,
                 ),
               );
             }
           }
         },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.thumbnailUrl,
                  width: 120,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 68,
                      color: Colors.grey[800],
                      child: const Icon(Icons.video_library, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.channelName,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Saved ${_formatDate(item.savedAt)}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Remove button
              IconButton(
                onPressed: () async {
                  await WatchLaterService.removeFromWatchLater(item.contentId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Removed from Watch Later'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.close, color: Colors.grey),
                iconSize: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Watch Later',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            onPressed: _showClearWatchLaterDialog,
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final userId = authProvider.firebaseUser?.uid;
          
          if (userId == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('watchLater')
                .where('userId', isEqualTo: userId)
                .orderBy('savedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              final watchLaterItems = snapshot.data!.docs
                  .map((doc) => WatchLaterModel.fromFirestore(doc))
                  .toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: watchLaterItems.length,
                itemBuilder: (context, index) {
                  final item = watchLaterItems[index];
                  return _buildWatchLaterItem(context, item);
                },
              );
            },
          );
        },
      ),
    );
  }
}
