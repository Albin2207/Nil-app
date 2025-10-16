import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/tmdb_provider.dart';
import '../../data/models/movie_tmdb_model.dart';
import 'movie_details_screen.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<TmdbProvider>().loadAllMovies());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Movies & TV Shows',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Add search functionality
            },
          ),
        ],
      ),
      body: Consumer<TmdbProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading movies',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.loadAllMovies(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            children: [
              // Featured Movie Banner
              if (provider.trendingMovies.isNotEmpty)
                _buildFeaturedBanner(provider.trendingMovies.first),

              const SizedBox(height: 24),

              // Trending Movies
              _buildSection(
                'Trending Now',
                provider.trendingMovies,
                isLarge: true,
              ),

              // Popular Movies
              _buildSection('Popular Movies', provider.popularMovies),

              // Now Playing
              _buildSection('Now Playing', provider.nowPlayingMovies),

              // Top Rated
              _buildSection('Top Rated', provider.topRatedMovies),

              // Upcoming
              _buildSection('Coming Soon', provider.upcomingMovies),

              // Popular TV Shows
              _buildSection('Popular TV Shows', provider.popularTvShows),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeaturedBanner(MovieTmdb movie) {
    return GestureDetector(
      onTap: () => _navigateToDetails(movie),
      child: Stack(
        children: [
          // Backdrop Image
          CachedNetworkImage(
            imageUrl: movie.backdropUrl,
            height: 500,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 500,
              color: Colors.grey[900],
            ),
            errorWidget: (context, url, error) => Container(
              height: 500,
              color: Colors.grey[900],
              child: const Icon(Icons.error, color: Colors.grey),
            ),
          ),

          // Gradient Overlay
          Container(
            height: 500,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                  Colors.black,
                ],
              ),
            ),
          ),

          // Movie Info
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      movie.voteAverage.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      movie.year,
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  movie.overview,
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _navigateToDetails(movie),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Watch Trailer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _navigateToDetails(movie),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('More Info'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<MovieTmdb> movies,
      {bool isLarge = false}) {
    if (movies.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: isLarge ? 280 : 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              return _buildMovieCard(movies[index], isLarge: isLarge);
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMovieCard(MovieTmdb movie, {bool isLarge = false}) {
    final width = isLarge ? 180.0 : 140.0;
    final height = isLarge ? 270.0 : 210.0;

    return GestureDetector(
      onTap: () => _navigateToDetails(movie),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: movie.posterUrl,
                height: height,
                width: width,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: height,
                  width: width,
                  color: Colors.grey[900],
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.red,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: height,
                  width: width,
                  color: Colors.grey[900],
                  child: const Icon(Icons.movie, color: Colors.grey, size: 50),
                ),
              ),
            ),
            if (isLarge) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    movie.voteAverage.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(MovieTmdb movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(movieId: movie.id),
      ),
    );
  }
}

