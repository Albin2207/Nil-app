import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart'; // Import to use VideoCard
import 'video_playing_screen.dart';
import 'creator_profile_screen.dart';
import '../../core/services/search_history_service.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _searchHistory = [];
  bool _isGridView = false;
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTab = _tabController.index;
      });
    });
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final history = await SearchHistoryService.getHistory();
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _searchQuery = query.toLowerCase();
    });
    
    // Add to history
    await SearchHistoryService.addToHistory(query);
    await _loadSearchHistory();
  }

  Future<void> _clearHistory() async {
    await SearchHistoryService.clearHistory();
    await _loadSearchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search videos...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.red),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                // Update for real-time filtering
              });
            },
            onSubmitted: (value) {
              _performSearch(value);
            },
            textInputAction: TextInputAction.search,
          ),
        ),
        actions: [
          if (_searchQuery.isNotEmpty && _currentTab == 1)
            IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list : Icons.grid_view,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
        ],
      ),
      body: _searchQuery.isEmpty
          ? _buildSearchHistory()
          : Column(
              children: [
                // Tabs
                Container(
                  color: Colors.black,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.red,
                    labelColor: Colors.red,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'Videos'),
                      Tab(text: 'Channels'),
                    ],
                  ),
                ),
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllTab(),
                      _buildVideosTab(),
                      _buildChannelsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // All Tab - Shows both channels and videos
  Widget _buildAllTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('videos')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, videoSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .snapshots(),
          builder: (context, channelSnapshot) {
            if (videoSnapshot.connectionState == ConnectionState.waiting ||
                channelSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.red),
              );
            }

            final videos = videoSnapshot.data?.docs ?? [];
            final channels = channelSnapshot.data?.docs ?? [];

            // Filter videos
            final filteredVideos = videos.where((video) {
              final data = video.data() as Map<String, dynamic>;
              final title = (data['title'] ?? '').toString().toLowerCase();
              final channelName = (data['channelName'] ?? '').toString().toLowerCase();
              return title.contains(_searchQuery) || channelName.contains(_searchQuery);
            }).toList();

            // Filter channels and remove duplicates
            final filteredChannels = channels.where((channel) {
              final data = channel.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery);
            }).toList();
            
            // Remove duplicates by ID
            final uniqueChannels = <String, QueryDocumentSnapshot>{};
            for (var channel in filteredChannels) {
              uniqueChannels[channel.id] = channel;
            }
            final deduplicatedChannels = uniqueChannels.values.toList();

            if (filteredVideos.isEmpty && deduplicatedChannels.isEmpty) {
              return _buildNoResults();
            }

            return ListView(
              children: [
                // Channels section
                if (deduplicatedChannels.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Channels (${deduplicatedChannels.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                  ...deduplicatedChannels.take(3).map((channel) => _buildChannelTile(channel)),
                  if (deduplicatedChannels.length > 3)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextButton(
                        onPressed: () {
                          _tabController.animateTo(2);
                        },
                        child: const Text(
                          'View all channels',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  const Divider(height: 32, thickness: 1, color: Colors.grey),
                ],
                // Videos section
                if (filteredVideos.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Videos (${filteredVideos.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                  ...filteredVideos.map((video) => VideoCard(
          video: video,
          onMarkNotInterested: _handleMarkNotInterested,
          onBlockChannel: _handleBlockChannel,
        )),
                ],
              ],
            );
          },
        );
      },
    );
  }

  // Videos Tab
  Widget _buildVideosTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('videos')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        final videos = snapshot.data?.docs ?? [];
        final filteredVideos = videos.where((video) {
          final data = video.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          final channelName = (data['channelName'] ?? '').toString().toLowerCase();
          return title.contains(_searchQuery) || channelName.contains(_searchQuery);
        }).toList();

        if (filteredVideos.isEmpty) {
          return _buildNoResults();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${filteredVideos.length} ${filteredVideos.length == 1 ? 'result' : 'results'} found',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: _isGridView
                  ? _buildGridView(filteredVideos)
                  : ListView.builder(
                      itemCount: filteredVideos.length,
                      itemBuilder: (context, index) {
                        return VideoCard(
          video: filteredVideos[index],
          onMarkNotInterested: _handleMarkNotInterested,
          onBlockChannel: _handleBlockChannel,
        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // Channels Tab
  Widget _buildChannelsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        final channels = snapshot.data?.docs ?? [];
        final filteredChannels = channels.where((channel) {
          final data = channel.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();
        
        // Remove duplicates by ID
        final uniqueChannels = <String, QueryDocumentSnapshot>{};
        for (var channel in filteredChannels) {
          uniqueChannels[channel.id] = channel;
        }
        final deduplicatedChannels = uniqueChannels.values.toList();

        if (deduplicatedChannels.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  'No channels found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${deduplicatedChannels.length} ${deduplicatedChannels.length == 1 ? 'channel' : 'channels'} found',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: deduplicatedChannels.length,
                itemBuilder: (context, index) {
                  return _buildChannelTile(deduplicatedChannels[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChannelTile(QueryDocumentSnapshot channel) {
    final data = channel.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unknown';
    final photoUrl = data['photoUrl'] ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(channel.id)
          .snapshots(),
      builder: (context, snapshot) {
        final liveData = snapshot.data?.data() as Map<String, dynamic>?;
        final subscribersCount = liveData?['subscribersCount'] ?? data['subscribersCount'] ?? 0;
        final videosCount = liveData?['uploadedVideosCount'] ?? data['uploadedVideosCount'] ?? 0;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreatorProfileScreen(
                  creatorId: channel.id,
                  creatorName: name,
                  creatorAvatar: photoUrl,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.withValues(alpha: 0.05),
                  Colors.grey[900]!,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Channel Avatar
                Container(
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
                    radius: 30,
                    backgroundColor: Colors.red,
                    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                // Channel Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.blue[400],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatCount(subscribersCount)} subscribers • $videosCount videos',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                // Subscribe Button
                Consumer2<AuthProvider, SubscriptionProvider>(
                  builder: (context, authProvider, subscriptionProvider, child) {
                    final currentUserId = authProvider.currentUser?.uid;
                    final isSubscribed = currentUserId != null
                        ? subscriptionProvider.isSubscribed(channel.id)
                        : false;

                    return ElevatedButton(
                      onPressed: currentUserId == null
                          ? null
                          : () async {
                              if (isSubscribed) {
                                await subscriptionProvider.unsubscribe(
                                  userId: currentUserId,
                                  channelId: channel.id,
                                );
                              } else {
                                await subscriptionProvider.subscribe(
                                  userId: currentUserId,
                                  channelId: channel.id,
                                  channelName: name,
                                  channelAvatar: photoUrl,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSubscribed ? Colors.grey[800] : Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        isSubscribed ? 'Subscribed' : 'Subscribe',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              'Search for videos',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find your favorite content',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[300],
                ),
              ),
              TextButton(
                onPressed: _clearHistory,
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: Colors.red.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                leading: Icon(
                  Icons.history,
                  color: Colors.grey[600],
                ),
                title: Text(
                  query,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  onPressed: () async {
                    await SearchHistoryService.removeFromHistory(query);
                    await _loadSearchHistory();
                  },
                ),
                onTap: () {
                  _searchController.text = query;
                  _performSearch(query);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGridView(List<QueryDocumentSnapshot> videos) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return _buildGridItem(videos[index]);
      },
    );
  }

  Widget _buildGridItem(QueryDocumentSnapshot video) {
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.grey[800],
                      child: data['thumbnailUrl'] != null
                          ? Image.network(
                              data['thumbnailUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 32,
                                    color: Colors.grey[600],
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                size: 48,
                                color: Colors.grey[600],
                              ),
                            ),
                    ),
                    // Play overlay
                    Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 40,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Untitled',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['channelName'] ?? 'Unknown',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMarkNotInterested(String videoId) {
    // For search screen, we don't need local state management
    // The filtering will be handled by the parent home screen
    // This is just a placeholder to satisfy the VideoCard requirements
  }

  void _handleBlockChannel(String channelId) {
    // For search screen, we don't need local state management
    // The filtering will be handled by the parent home screen
    // This is just a placeholder to satisfy the VideoCard requirements
  }
}

