// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../presentation/providers/shorts_provider.dart';
// import '../providers/video_providers.dart';
// import '../widgets/shorts_csrd.dart';
// import '../widgets/video_card.dart';
// import 'shortsplayer_screen.dart';

// class SearchScreen extends StatefulWidget {
//   const SearchScreen({super.key});

//   @override
//   State<SearchScreen> createState() => _SearchScreenState();
// }

// class _SearchScreenState extends State<SearchScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final videos = context.watch<VideoProvider>().videos;
//     final shorts = context.watch<ShortProvider>().shorts;

//     // Filter based on search query
//     final filteredVideos = _searchQuery.isEmpty
//         ? <dynamic>[]
//         : videos
//             .where((video) =>
//                 video.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
//                 video.channel.toLowerCase().contains(_searchQuery.toLowerCase()))
//             .toList();

//     final filteredShorts = _searchQuery.isEmpty
//         ? <dynamic>[]
//         : shorts
//             .where((short) =>
//                 short.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
//                 short.channel.toLowerCase().contains(_searchQuery.toLowerCase()))
//             .toList();

//     final totalResults = filteredVideos.length + filteredShorts.length;

//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: TextField(
//           controller: _searchController,
//           autofocus: true,
//           onChanged: (value) {
//             setState(() {
//               _searchQuery = value;
//             });
//           },
//           style: const TextStyle(color: Colors.white),
//           decoration: InputDecoration(
//             hintText: 'Search videos & shorts...',
//             hintStyle: TextStyle(color: Colors.grey.shade500),
//             border: InputBorder.none,
//             suffixIcon: _searchQuery.isNotEmpty
//                 ? IconButton(
//                     icon: Icon(Icons.clear, color: Colors.grey.shade400),
//                     onPressed: () {
//                       _searchController.clear();
//                       setState(() {
//                         _searchQuery = '';
//                       });
//                     },
//                   )
//                 : null,
//           ),
//         ),
//       ),
//       body: _searchQuery.isEmpty
//           ? _buildEmptySearch()
//           : totalResults == 0
//               ? _buildNoResults()
//               : _buildSearchResults(filteredVideos, filteredShorts),
//     );
//   }

//   Widget _buildEmptySearch() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.search,
//             size: 80,
//             color: Colors.grey.shade700,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Search for videos & shorts',
//             style: TextStyle(
//               fontSize: 18,
//               color: Colors.grey.shade600,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNoResults() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.search_off,
//             size: 80,
//             color: Colors.grey.shade700,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No results found',
//             style: TextStyle(
//               fontSize: 18,
//               color: Colors.grey.shade600,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Try searching for something else',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade700,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchResults(List filteredVideos, List filteredShorts) {
//     final allShorts = context.read<ShortProvider>().shorts;
//     final totalResults = filteredVideos.length + filteredShorts.length;

//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         // Results count
//         Text(
//           'Found $totalResults result${totalResults != 1 ? 's' : ''}',
//           style: TextStyle(
//             fontSize: 14,
//             color: Colors.grey.shade400,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         const SizedBox(height: 16),

//         // Videos Section
//         if (filteredVideos.isNotEmpty) ...[
//           const Text(
//             'Videos',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 12),
//           ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: filteredVideos.length,
//             itemBuilder: (context, index) {
//               return VideoCard(video: filteredVideos[index]);
//             },
//           ),
//           const SizedBox(height: 24),
//         ],

//         // Shorts Section
//         if (filteredShorts.isNotEmpty) ...[
//           const Text(
//             'Shorts',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 12),
//           GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               childAspectRatio: 0.57,
//               crossAxisSpacing: 8,
//               mainAxisSpacing: 8,
//             ),
//             itemCount: filteredShorts.length,
//             itemBuilder: (context, index) {
//               return ShortCard(
//                 short: filteredShorts[index],
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ShortsPlayerScreen(
//                         initialIndex: allShorts.indexOf(filteredShorts[index]),
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ],
//       ],
//     );
//   }
// }