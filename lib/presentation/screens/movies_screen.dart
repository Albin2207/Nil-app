import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/movies_provider.dart';
import '../../widgets/movies_card.dart';
import '../../widgets/tvshows_card.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movieProvider = context.watch<MovieProvider>();

    // Filter movies based on search query
    final filteredNowPlaying = _searchQuery.isEmpty
        ? movieProvider.nowPlaying
        : movieProvider.nowPlaying
              .where(
                (movie) => movie.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

    final filteredUpcoming = _searchQuery.isEmpty
        ? movieProvider.upcomingMovies
        : movieProvider.upcomingMovies
              .where(
                (movie) => movie.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

    final filteredTvShows = _searchQuery.isEmpty
        ? movieProvider.popularTvShows
        : movieProvider.popularTvShows
              .where(
                (movie) => movie.title.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search movies & TV shows...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade400),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildAllSections(
                    filteredNowPlaying,
                    filteredUpcoming,
                    filteredTvShows,
                  )
                : _buildSearchResults(
                    filteredNowPlaying,
                    filteredUpcoming,
                    filteredTvShows,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllSections(
    List filteredNowPlaying,
    List filteredUpcoming,
    List filteredTvShows,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Now Playing Section
        _buildSectionHeader('Now Playing'),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filteredNowPlaying.length,
            itemBuilder: (context, index) {
              return MovieCard(movie: filteredNowPlaying[index]);
            },
          ),
        ),
        const SizedBox(height: 32),

        // Upcoming Movies Section
        _buildSectionHeader('Upcoming Movies'),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filteredUpcoming.length,
            itemBuilder: (context, index) {
              return MovieCard(movie: filteredUpcoming[index]);
            },
          ),
        ),
        const SizedBox(height: 32),

        // Popular TV Shows Section
        _buildSectionHeader('Popular TV Shows'),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filteredTvShows.length,
            itemBuilder: (context, index) {
              return TvShowCard(
                movie: filteredTvShows[index],
                index: index + 1,
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSearchResults(
    List filteredNowPlaying,
    List filteredUpcoming,
    List filteredTvShows,
  ) {
    final allResults = [
      ...filteredNowPlaying,
      ...filteredUpcoming,
      ...filteredTvShows,
    ];

    if (allResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.shade700),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for something else',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Text(
          'Found ${allResults.length} result${allResults.length != 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
          ),
          itemCount: allResults.length,
          itemBuilder: (context, index) {
            return MovieCard(movie: allResults[index]);
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
