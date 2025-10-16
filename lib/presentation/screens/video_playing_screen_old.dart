// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:timeago/timeago.dart' as timeago;
// import 'package:shared_preferences/shared_preferences.dart';

// class VideoPlayerScreen extends StatefulWidget {
//   final QueryDocumentSnapshot video;
//   const VideoPlayerScreen({super.key, required this.video});

//   @override
//   State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
// }

// class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
//   late VideoPlayerController _videoPlayerController;
//   ChewieController? _chewieController;
//   final TextEditingController _commentController = TextEditingController();
//   bool _isLiked = false;
//   bool _isDisliked = false;
//   bool _isSubscribed = false;
//   bool _isDescriptionExpanded = false;

//   @override
//   void initState() {
//     super.initState();
//     _initializePlayer();
//     _loadUserPreferences();
//     _incrementViewCount();
//   }

//   Future<void> _initializePlayer() async {
//     final videoUrl = widget.video['videoUrl'] as String;
//     _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    
//     await _videoPlayerController.initialize();
    
//     _chewieController = ChewieController(
//       videoPlayerController: _videoPlayerController,
//       autoPlay: true,
//       looping: false,
//       allowFullScreen: true,
//       allowMuting: true,
//       showControls: true,
//       materialProgressColors: ChewieProgressColors(
//         playedColor: Colors.red,
//         handleColor: Colors.red,
//         bufferedColor: Colors.grey,
//         backgroundColor: Colors.black26,
//       ),
//       placeholder: Container(
//         color: Colors.black,
//         child: const Center(
//           child: CircularProgressIndicator(color: Colors.red),
//         ),
//       ),
//       autoInitialize: true,
//     );
    
//       setState(() {});
//   }

//   Future<void> _loadUserPreferences() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _isLiked = prefs.getBool('liked_${widget.video.id}') ?? false;
//       _isDisliked = prefs.getBool('disliked_${widget.video.id}') ?? false;
//       _isSubscribed = prefs.getBool('subscribed_${widget.video['channelName']}') ?? false;
//     });
//   }

//   Future<void> _saveUserPreferences() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('liked_${widget.video.id}', _isLiked);
//     await prefs.setBool('disliked_${widget.video.id}', _isDisliked);
//     await prefs.setBool('subscribed_${widget.video['channelName']}', _isSubscribed);
//   }

//   Future<void> _incrementViewCount() async {
//     await FirebaseFirestore.instance
//         .collection('videos')
//         .doc(widget.video.id)
//         .update({
//       'views': FieldValue.increment(1),
//     });
//   }

//   Future<void> _toggleLike() async {
//     final docRef = FirebaseFirestore.instance
//         .collection('videos')
//         .doc(widget.video.id);

//     if (_isLiked) {
//       await docRef.update({'likes': FieldValue.increment(-1)});
//       setState(() => _isLiked = false);
//     } else {
//       await docRef.update({
//         'likes': FieldValue.increment(1),
//         if (_isDisliked) 'dislikes': FieldValue.increment(-1),
//       });
//       setState(() {
//         _isLiked = true;
//         _isDisliked = false;
//       });
//     }
//     await _saveUserPreferences();
//   }

//   Future<void> _toggleDislike() async {
//     final docRef = FirebaseFirestore.instance
//         .collection('videos')
//         .doc(widget.video.id);

//     if (_isDisliked) {
//       await docRef.update({'dislikes': FieldValue.increment(-1)});
//       setState(() => _isDisliked = false);
//     } else {
//       await docRef.update({
//         'dislikes': FieldValue.increment(1),
//         if (_isLiked) 'likes': FieldValue.increment(-1),
//       });
//       setState(() {
//         _isDisliked = true;
//         _isLiked = false;
//       });
//     }
//     await _saveUserPreferences();
//   }

//   Future<void> _toggleSubscribe() async {
//     final newState = !_isSubscribed;
//     setState(() {
//       _isSubscribed = newState;
//     });
//     await _saveUserPreferences();
    
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(newState ? 'Subscribed!' : 'Unsubscribed'),
//           duration: const Duration(seconds: 1),
//         ),
//       );
//     }
//   }

//   Future<void> _postComment() async {
//     if (_commentController.text.trim().isEmpty) return;

//     await FirebaseFirestore.instance
//         .collection('videos')
//         .doc(widget.video.id)
//         .collection('comments')
//         .add({
//       'text': _commentController.text.trim(),
//       'username': 'Anonymous User', // Replace with actual user from Firebase Auth
//       'userAvatar': 'https://i.pravatar.cc/150?img=1',
//       'timestamp': FieldValue.serverTimestamp(),
//       'likes': 0,
//       'dislikes': 0,
//       'parentId': null, // Top-level comment (no parent)
//     });

//     _commentController.clear();
//     if (mounted) {
//     FocusScope.of(context).unfocus();
//     }
//   }

//   void _shareVideo() {
//     Share.share(
//       'Check out this video: ${widget.video['title']}\n${widget.video['videoUrl']}',
//       subject: widget.video['title'],
//     );
//   }

//   String _formatCount(int count) {
//     if (count >= 1000000) {
//       return '${(count / 1000000).toStringAsFixed(1)}M';
//     } else if (count >= 1000) {
//       return '${(count / 1000).toStringAsFixed(1)}K';
//     }
//     return count.toString();
//   }

//   @override
//   void dispose() {
//     _videoPlayerController.dispose();
//     _chewieController?.dispose();
//     _commentController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: CustomScrollView(
//         slivers: [
//           // Video Player Section (Fixed at top)
//           SliverToBoxAdapter(
//             child: _chewieController != null
//                 ? AspectRatio(
//                     aspectRatio: _videoPlayerController.value.aspectRatio,
//                     child: Chewie(controller: _chewieController!),
//                   )
//                 : AspectRatio(
//                     aspectRatio: 16 / 9,
//               child: Container(
//                 color: Colors.black,
//                       child: const Center(
//                         child: CircularProgressIndicator(color: Colors.red),
//                       ),
//                     ),
//                   ),
//           ),

//           // Scrollable Content
//           SliverToBoxAdapter(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Video Title and Info
//                 _buildVideoInfo(),

//                 // Action Buttons (Like, Dislike, Share, etc.)
//                 _buildActionButtons(),

//                 const Divider(height: 32, thickness: 1),

//                 // Channel Info
//                 _buildChannelInfo(),

//                 // Description
//                 _buildDescription(),

//                 const Divider(height: 1, thickness: 8, color: Color(0xFFF5F5F5)),

//                 // Comments Section - Collapsed (Click to Open)
//                 _buildCommentsPreview(),

//                 const Divider(height: 1, thickness: 8, color: Color(0xFFF5F5F5)),

//                 // Related Videos Section
//                 _buildRelatedVideosSection(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildVideoInfo() {
//     final data = widget.video.data() as Map<String, dynamic>;
//     return StreamBuilder<DocumentSnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('videos')
//           .doc(widget.video.id)
//           .snapshots(),
//       builder: (context, snapshot) {
//         final videoData = snapshot.hasData
//             ? snapshot.data!.data() as Map<String, dynamic>?
//             : data;
        
//         return Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 videoData?['title'] ?? data['title'] ?? 'Untitled',
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 '${_formatCount(videoData?['views'] ?? data['views'] ?? 0)} views • ${videoData?['timestamp'] != null ? timeago.format((videoData?['timestamp'] as Timestamp).toDate()) : 'Recently'}',
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildActionButtons() {
//     final data = widget.video.data() as Map<String, dynamic>;
//     return StreamBuilder<DocumentSnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('videos')
//           .doc(widget.video.id)
//           .snapshots(),
//       builder: (context, snapshot) {
//         final videoData = snapshot.hasData
//             ? snapshot.data!.data() as Map<String, dynamic>?
//             : data;
        
//         return Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: [
//                 _buildActionButton(
//                   icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
//                   label: _formatCount(videoData?['likes'] ?? data['likes'] ?? 0),
//                   onTap: _toggleLike,
//                   isActive: _isLiked,
//                 ),
//                 const SizedBox(width: 8),
//                 _buildActionButton(
//                   icon: _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
//                   label: 'Dislike',
//                   onTap: _toggleDislike,
//                   isActive: _isDisliked,
//                 ),
//                 const SizedBox(width: 8),
//                 _buildActionButton(
//                   icon: Icons.share_outlined,
//                   label: 'Share',
//                   onTap: _shareVideo,
//                 ),
//                 const SizedBox(width: 8),
//                 _buildActionButton(
//                   icon: Icons.download_outlined,
//                   label: 'Download',
//                   onTap: () {
//                     if (mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Download feature coming soon')),
//                       );
//                     }
//                   },
//                 ),
//                 const SizedBox(width: 8),
//                 _buildActionButton(
//                   icon: Icons.playlist_add,
//                   label: 'Save',
//                   onTap: () {
//                     if (mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Saved to Watch Later')),
//                       );
//                     }
//                   },
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildChannelInfo() {
//     final data = widget.video.data() as Map<String, dynamic>;
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 20,
//             backgroundImage: NetworkImage(
//               data['channelAvatar'] ?? 'https://i.pravatar.cc/150?img=2',
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   data['channelName'] ?? 'Channel Name',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black,
//                   ),
//                 ),
//                 Text(
//                   '${_formatCount(data['subscribers'] ?? 0)} subscribers',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           ElevatedButton(
//             onPressed: _toggleSubscribe,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _isSubscribed ? Colors.grey[200] : Colors.red,
//               foregroundColor: _isSubscribed ? Colors.black87 : Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               elevation: 0,
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             ),
//             child: Text(
//               _isSubscribed ? 'Subscribed' : 'Subscribe',
//               style: const TextStyle(fontWeight: FontWeight.w600),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDescription() {
//     final data = widget.video.data() as Map<String, dynamic>;
//     if (data['description'] == null) return const SizedBox();
    
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: GestureDetector(
//         onTap: () {
//           setState(() {
//             _isDescriptionExpanded = !_isDescriptionExpanded;
//           });
//         },
//         child: Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.grey[100],
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 data['description'] ?? 'No description',
//                 style: const TextStyle(
//                   fontSize: 14,
//                   color: Colors.black87,
//                 ),
//                 maxLines: _isDescriptionExpanded ? null : 3,
//                 overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
//               ),
//               if ((data['description'] ?? '').length > 100)
//                 Text(
//                   _isDescriptionExpanded ? 'Show less' : 'Show more',
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }


//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//     bool isActive = false,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(24),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.grey[100],
//           borderRadius: BorderRadius.circular(24),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               icon,
//               size: 20,
//               color: isActive ? Colors.red : Colors.black87,
//             ),
//             const SizedBox(width: 6),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: isActive ? Colors.red : Colors.black87,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Collapsed Comments Preview (YouTube-style)
//   Widget _buildCommentsPreview() {
//     return StreamBuilder<QuerySnapshot>(
//                       stream: FirebaseFirestore.instance
//                           .collection('videos')
//                           .doc(widget.video.id)
//                           .collection('comments')
//                           .snapshots(),
//                       builder: (context, snapshot) {
//         // Count only top-level comments (where parentId is null or doesn't exist)
//         final commentCount = snapshot.hasData 
//             ? snapshot.data!.docs.where((doc) {
//                 final data = doc.data() as Map<String, dynamic>;
//                 return data['parentId'] == null;
//               }).length
//             : 0;

//         return InkWell(
//           onTap: () => _openCommentsBottomSheet(),
//           child: Padding(
//                               padding: const EdgeInsets.all(16),
//             child: Row(
//                           children: [
//                 Text(
//                   'Comments',
//                                 style: const TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                     color: Colors.black,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   '$commentCount',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const Spacer(),
//                 Icon(Icons.expand_more, color: Colors.grey[600]),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // Open Comments Bottom Sheet (YouTube-style)
//   void _openCommentsBottomSheet() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => DraggableScrollableSheet(
//         initialChildSize: 0.9,
//         minChildSize: 0.5,
//         maxChildSize: 0.95,
//         builder: (context, scrollController) {
//           return Container(
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//             ),
//             child: Column(
//               children: [
//                 // Handle bar
//                 Container(
//                   margin: const EdgeInsets.only(top: 12, bottom: 8),
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),

//                 // Header
//                             Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       StreamBuilder<QuerySnapshot>(
//                         stream: FirebaseFirestore.instance
//                             .collection('videos')
//                             .doc(widget.video.id)
//                             .collection('comments')
//                             .snapshots(),
//                         builder: (context, snapshot) {
//                           final count = snapshot.hasData 
//                               ? snapshot.data!.docs.where((doc) {
//                                   final data = doc.data() as Map<String, dynamic>;
//                                   return data['parentId'] == null;
//                                 }).length
//                               : 0;
//                           return Text(
//                             'Comments $count',
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.black,
//                             ),
//                           );
//                         },
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.close),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const Divider(height: 1),

//                 // Add Comment Section
//                 Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       const CircleAvatar(
//                         radius: 18,
//                         backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=1'),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: TextField(
//                           controller: _commentController,
//                           style: const TextStyle(
//                             color: Colors.black,
//                             fontSize: 14,
//                           ),
//                           decoration: InputDecoration(
//                             hintText: 'Add a comment...',
//                             hintStyle: TextStyle(color: Colors.grey[500]),
//                             filled: true,
//                             fillColor: Colors.grey[50],
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(24),
//                               borderSide: BorderSide(color: Colors.grey[300]!),
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(24),
//                               borderSide: BorderSide(color: Colors.grey[300]!),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(24),
//                               borderSide: const BorderSide(color: Colors.red, width: 2),
//                             ),
//                             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                             suffixIcon: IconButton(
//                               icon: const Icon(Icons.send, color: Colors.red),
//                               onPressed: () {
//                                 _postComment();
//                                 // Don't close the sheet - stay open to see the comment
//                               },
//                             ),
//                           ),
//                           onSubmitted: (_) {
//                             _postComment();
//                             // Don't close the sheet - stay open to see the comment
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const Divider(height: 1),

//                             // Comments List
//                 Expanded(
//                   child: StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('videos')
//                         .doc(widget.video.id)
//                         .collection('comments')
//                         .orderBy('timestamp', descending: true)
//                         .snapshots(),
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return const Center(child: CircularProgressIndicator(color: Colors.red));
//                       }

//                       if (!snapshot.hasData) {
//                         return Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.comment_outlined, size: 64, color: Colors.grey[400]),
//                               const SizedBox(height: 16),
//                               Text(
//                                 'No comments yet',
//                                 style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Be the first to comment!',
//                                 style: TextStyle(fontSize: 14, color: Colors.grey[500]),
//                               ),
//                             ],
//                           ),
//                         );
//                       }

//                       // Filter only top-level comments (parentId is null)
//                       final topLevelComments = snapshot.data!.docs.where((doc) {
//                         final data = doc.data() as Map<String, dynamic>;
//                         return data['parentId'] == null;
//                       }).toList();

//                       if (topLevelComments.isEmpty) {
//                         return Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.comment_outlined, size: 64, color: Colors.grey[400]),
//                               const SizedBox(height: 16),
//                               Text(
//                                 'No comments yet',
//                                 style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Be the first to comment!',
//                                 style: TextStyle(fontSize: 14, color: Colors.grey[500]),
//                               ),
//                             ],
//                           ),
//                         );
//                       }

//                       return ListView.builder(
//                         controller: scrollController,
//                         itemCount: topLevelComments.length,
//                         itemBuilder: (context, index) {
//                           final comment = topLevelComments[index];
//                                 final data = comment.data() as Map<String, dynamic>;
//                           return _buildCommentItemWithReplies(comment.id, data);
//                         },
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   // Build Comment with Replies (Tree Structure)
//   Widget _buildCommentItemWithReplies(String commentId, Map<String, dynamic> data) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildCommentItem(commentId, data, isReply: false),
        
//         // Show Replies
//         StreamBuilder<QuerySnapshot>(
//           stream: FirebaseFirestore.instance
//               .collection('videos')
//               .doc(widget.video.id)
//               .collection('comments')
//               .orderBy('timestamp', descending: false)
//               .snapshots(),
//           builder: (context, snapshot) {
//             if (!snapshot.hasData) {
//               return const SizedBox();
//             }

//             // Filter replies for this specific comment
//             final replies = snapshot.data!.docs.where((doc) {
//               final data = doc.data() as Map<String, dynamic>;
//               return data['parentId'] == commentId;
//             }).toList();

//             if (replies.isEmpty) {
//               return const SizedBox();
//             }

//                                 return Padding(
//               padding: const EdgeInsets.only(left: 48),
//               child: Column(
//                 children: replies.map((reply) {
//                   final replyData = reply.data() as Map<String, dynamic>;
//                   return _buildCommentItem(reply.id, replyData, isReply: true);
//                 }).toList(),
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildCommentItem(String commentId, Map<String, dynamic> data, {bool isReply = false}) {
//     // Check user's like/dislike state
//     final hasLiked = _commentLikes[commentId] ?? false;
//     final hasDisliked = _commentDislikes[commentId] ?? false;
    
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: isReply ? 8 : 16,
//         vertical: 12,
//       ),
//                                   child: Row(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       CircleAvatar(
//             radius: isReply ? 16 : 18,
//                                         backgroundImage: NetworkImage(
//                                           data['userAvatar'] ?? 'https://i.pravatar.cc/150?img=3',
//                                         ),
//                                       ),
//                                       const SizedBox(width: 12),
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             Row(
//                                               children: [
//                                                 Text(
//                       data['username'] ?? 'Anonymous User',
//                       style: TextStyle(
//                                                     fontWeight: FontWeight.w600,
//                         fontSize: isReply ? 12 : 13,
//                         color: Colors.black,
//                                                   ),
//                                                 ),
//                                                 const SizedBox(width: 8),
//                                                 Text(
//                                                   data['timestamp'] != null
//                                                       ? timeago.format((data['timestamp'] as Timestamp).toDate())
//                                                       : 'Just now',
//                                                   style: TextStyle(
//                         fontSize: 11,
//                                                     color: Colors.grey[600],
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             const SizedBox(height: 4),
//                 Text(
//                   data['text'] ?? '',
//                   style: TextStyle(
//                     fontSize: isReply ? 13 : 14,
//                     color: Colors.black87,
//                   ),
//                 ),
//                                             const SizedBox(height: 8),
//                                             Row(
//                                               children: [
//                     InkWell(
//                       onTap: () => _toggleCommentLike(commentId),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//                         child: Row(
//                           children: [
//                             Icon(
//                               hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
//                               size: 16,
//                               color: hasLiked ? Colors.red : Colors.grey[700],
//                             ),
//                             const SizedBox(width: 6),
//                             Text(
//                               '${data['likes'] ?? 0}',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: hasLiked ? Colors.red : Colors.grey[700],
//                                 fontWeight: hasLiked ? FontWeight.w600 : FontWeight.normal,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     InkWell(
//                       onTap: () => _toggleCommentDislike(commentId),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//                         child: Row(
//                           children: [
//                             Icon(
//                               hasDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
//                               size: 16,
//                               color: hasDisliked ? Colors.red : Colors.grey[700],
//                             ),
//                             if (data['dislikes'] != null && data['dislikes'] > 0) ...[
//                               const SizedBox(width: 6),
//                               Text(
//                                 '${data['dislikes']}',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: hasDisliked ? Colors.red : Colors.grey[700],
//                                   fontWeight: hasDisliked ? FontWeight.w600 : FontWeight.normal,
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ),
//                                                 const SizedBox(width: 16),
//                     if (!isReply)
//                       InkWell(
//                         onTap: () => _replyToComment(commentId, data['username'] ?? 'User'),
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//                           child: Text(
//                             'Reply',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey[700],
//                             ),
//                           ),
//                         ),
//                       ),
//                                               ],
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 );
//   }

//   // Track comment likes/dislikes locally
//   final Map<String, bool> _commentLikes = {};
//   final Map<String, bool> _commentDislikes = {};

//   Future<void> _toggleCommentLike(String commentId) async {
//     final wasLiked = _commentLikes[commentId] ?? false;
//     final wasDisliked = _commentDislikes[commentId] ?? false;
    
//     final docRef = FirebaseFirestore.instance
//         .collection('videos')
//         .doc(widget.video.id)
//         .collection('comments')
//         .doc(commentId);

//     if (wasLiked) {
//       // Unlike
//       await docRef.update({'likes': FieldValue.increment(-1)});
//       setState(() => _commentLikes[commentId] = false);
//     } else {
//       // Like
//       final updates = <String, dynamic>{'likes': FieldValue.increment(1)};
//       if (wasDisliked) {
//         updates['dislikes'] = FieldValue.increment(-1);
//       }
//       await docRef.update(updates);
//       setState(() {
//         _commentLikes[commentId] = true;
//         _commentDislikes[commentId] = false;
//       });
//     }
//   }

//   Future<void> _toggleCommentDislike(String commentId) async {
//     final wasLiked = _commentLikes[commentId] ?? false;
//     final wasDisliked = _commentDislikes[commentId] ?? false;
    
//     final docRef = FirebaseFirestore.instance
//         .collection('videos')
//         .doc(widget.video.id)
//         .collection('comments')
//         .doc(commentId);

//     if (wasDisliked) {
//       // Remove dislike
//       await docRef.update({'dislikes': FieldValue.increment(-1)});
//       setState(() => _commentDislikes[commentId] = false);
//     } else {
//       // Dislike
//       final updates = <String, dynamic>{'dislikes': FieldValue.increment(1)};
//       if (wasLiked) {
//         updates['likes'] = FieldValue.increment(-1);
//       }
//       await docRef.update(updates);
//       setState(() {
//         _commentDislikes[commentId] = true;
//         _commentLikes[commentId] = false;
//       });
//     }
//   }

//   void _replyToComment(String parentId, String username) {
//     final replyController = TextEditingController();
    
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.white,
//         title: Text(
//           'Reply to $username',
//           style: const TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         content: TextField(
//           controller: replyController,
//           autofocus: true,
//           maxLines: 3,
//           style: const TextStyle(color: Colors.black),
//           decoration: InputDecoration(
//             hintText: 'Write a reply...',
//             hintStyle: TextStyle(color: Colors.grey[500]),
//             filled: true,
//             fillColor: Colors.grey[50],
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Colors.grey[300]!),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: const BorderSide(color: Colors.red, width: 2),
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text(
//               'Cancel',
//               style: TextStyle(color: Colors.grey),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (replyController.text.trim().isNotEmpty) {
//                 await FirebaseFirestore.instance
//                     .collection('videos')
//                     .doc(widget.video.id)
//                     .collection('comments')
//                     .add({
//                   'text': replyController.text.trim(),
//                   'username': 'Anonymous User',
//                   'userAvatar': 'https://i.pravatar.cc/150?img=1',
//                   'timestamp': FieldValue.serverTimestamp(),
//                   'likes': 0,
//                   'dislikes': 0,
//                   'parentId': parentId, // Link to parent comment
//                 });
//                 if (mounted) {
//                   Navigator.pop(context);
//                 }
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//               elevation: 0,
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             ),
//             child: const Text('Reply'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRelatedVideosSection() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('videos')
//           .where(FieldPath.documentId, isNotEqualTo: widget.video.id)
//           .orderBy(FieldPath.documentId)
//           .limit(10)
//           .snapshots(),
//       builder: (context, snapshot) {
//         // Show loading state
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Padding(
//             padding: EdgeInsets.all(32),
//             child: Center(child: CircularProgressIndicator(color: Colors.red)),
//           );
//         }

//         // Show empty state if no related videos
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Text(
//                   'Related Videos',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black,
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(32),
//                 child: Center(
//                   child: Column(
//                     children: [
//                       Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
//                       const SizedBox(height: 16),
//                       Text(
//                         'No more videos yet',
//                         style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Add more videos to see recommendations here',
//                         style: TextStyle(fontSize: 14, color: Colors.grey[500]),
//                         textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//           );
//         }

//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Padding(
//               padding: EdgeInsets.all(16),
//               child: Text(
//                 'Related Videos',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black,
//                 ),
//               ),
//             ),
//             ...snapshot.data!.docs.map((doc) {
//               return _buildRelatedVideoCard(doc);
//             }),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildRelatedVideoCard(QueryDocumentSnapshot video) {
//     final data = video.data() as Map<String, dynamic>;
    
//     return InkWell(
//       onTap: () {
//         // Navigate to the new video
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(
//             builder: (context) => VideoPlayerScreen(video: video),
//           ),
//         );
//       },
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Thumbnail
//             Stack(
//               children: [
//                 Container(
//                   width: 168,
//                   height: 94,
//         decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: data['thumbnailUrl'] != null
//                       ? ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child: Image.network(
//                             data['thumbnailUrl'],
//                             fit: BoxFit.cover,
//                             errorBuilder: (context, error, stackTrace) {
//                               return const Center(
//                                 child: Icon(Icons.error_outline, size: 32),
//                               );
//                             },
//                           ),
//                         )
//                       : const Center(
//                           child: Icon(Icons.play_circle_outline, size: 48),
//                         ),
//                 ),
//                 // Duration badge
//                 if (data['duration'] != null)
//                   Positioned(
//                     bottom: 4,
//                     right: 4,
//       child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 4,
//                         vertical: 2,
//                       ),
//         decoration: BoxDecoration(
//                         color: Colors.black87,
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: Text(
//                         _formatDuration(data['duration']),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 11,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(width: 12),
//             // Video Info
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//                     data['title'] ?? 'Untitled Video',
//                     style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                       height: 1.3,
//                       color: Colors.black,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     data['channelName'] ?? 'Unknown Channel',
//                     style: const TextStyle(
//                       fontSize: 12,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   Text(
//                     '${_formatCount(data['views'] ?? 0)} views • ${data['timestamp'] != null ? timeago.format((data['timestamp'] as Timestamp).toDate()) : 'Recently'}',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // More options
//             IconButton(
//               icon: const Icon(Icons.more_vert, size: 20),
//               onPressed: () {},
//               padding: EdgeInsets.zero,
//               constraints: const BoxConstraints(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatDuration(int seconds) {
//     final duration = Duration(seconds: seconds);
//     final hours = duration.inHours;
//     final minutes = duration.inMinutes.remainder(60);
//     final secs = duration.inSeconds.remainder(60);
    
//     if (hours > 0) {
//       return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
//     }
//     return '$minutes:${secs.toString().padLeft(2, '0')}';
//   }
// }
