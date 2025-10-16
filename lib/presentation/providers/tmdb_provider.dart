import 'package:flutter/material.dart';
import '../../data/models/movie_tmdb_model.dart';
import '../../data/repositories/tmdb_repository.dart';

class TmdbProvider extends ChangeNotifier {
  final TmdbRepository _repository = TmdbRepository();

  List<MovieTmdb> _trendingMovies = [];
  List<MovieTmdb> _popularMovies = [];
  List<MovieTmdb> _topRatedMovies = [];
  List<MovieTmdb> _nowPlayingMovies = [];
  List<MovieTmdb> _upcomingMovies = [];
  List<MovieTmdb> _popularTvShows = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  List<MovieTmdb> get trendingMovies => _trendingMovies;
  List<MovieTmdb> get popularMovies => _popularMovies;
  List<MovieTmdb> get topRatedMovies => _topRatedMovies;
  List<MovieTmdb> get nowPlayingMovies => _nowPlayingMovies;
  List<MovieTmdb> get upcomingMovies => _upcomingMovies;
  List<MovieTmdb> get popularTvShows => _popularTvShows;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all movies - resilient version (doesn't fail if one category fails)
  Future<void> loadAllMovies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch all categories, but don't fail if one fails
      final results = await Future.wait([
        _repository.getTrendingMovies().catchError((e) {
          print('⚠️ Trending failed: $e');
          return <MovieTmdb>[];
        }),
        _repository.getPopularMovies().catchError((e) {
          print('⚠️ Popular failed: $e');
          return <MovieTmdb>[];
        }),
        _repository.getTopRatedMovies().catchError((e) {
          print('⚠️ Top Rated failed: $e');
          return <MovieTmdb>[];
        }),
        _repository.getNowPlayingMovies().catchError((e) {
          print('⚠️ Now Playing failed: $e');
          return <MovieTmdb>[];
        }),
        _repository.getUpcomingMovies().catchError((e) {
          print('⚠️ Upcoming failed: $e');
          return <MovieTmdb>[];
        }),
        _repository.getPopularTvShows().catchError((e) {
          print('⚠️ TV Shows failed: $e');
          return <MovieTmdb>[];
        }),
      ]);

      _trendingMovies = results[0];
      _popularMovies = results[1];
      _topRatedMovies = results[2];
      _nowPlayingMovies = results[3];
      _upcomingMovies = results[4];
      _popularTvShows = results[5];

      // Check if at least one category loaded
      final totalMovies = _trendingMovies.length +
          _popularMovies.length +
          _topRatedMovies.length +
          _nowPlayingMovies.length +
          _upcomingMovies.length +
          _popularTvShows.length;

      if (totalMovies == 0) {
        _error = 'No movies loaded. Please check your internet connection and try again.';
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get movie details
  Future<MovieDetails> getMovieDetails(int id) async {
    return await _repository.getMovieDetails(id);
  }

  // Search movies
  Future<List<MovieTmdb>> searchMovies(String query) async {
    return await _repository.searchMovies(query);
  }
}

