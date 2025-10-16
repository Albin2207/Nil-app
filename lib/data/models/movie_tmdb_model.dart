import '../../core/constants/tmdb_config.dart';

class MovieTmdb {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String overview;
  final double voteAverage;
  final String? releaseDate;
  final List<int> genreIds;
  final bool isMovie; // true for movie, false for TV show

  MovieTmdb({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.overview,
    required this.voteAverage,
    this.releaseDate,
    required this.genreIds,
    this.isMovie = true,
  });

  factory MovieTmdb.fromJson(Map<String, dynamic> json) {
    return MovieTmdb(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? 'Unknown',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      overview: json['overview'] ?? '',
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
      releaseDate: json['release_date'] ?? json['first_air_date'],
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      isMovie: json['title'] != null, // If has 'title' it's a movie, else TV show
    );
  }

  String get posterUrl => TmdbConfig.getPosterUrl(posterPath);
  String get backdropUrl => TmdbConfig.getBackdropUrl(backdropPath);
  String get year => releaseDate?.split('-').first ?? 'N/A';
}

class MovieDetails {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String overview;
  final double voteAverage;
  final String? releaseDate;
  final int runtime;
  final List<Genre> genres;
  final List<Video> videos;
  final List<Cast> cast;

  MovieDetails({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.overview,
    required this.voteAverage,
    this.releaseDate,
    required this.runtime,
    required this.genres,
    required this.videos,
    required this.cast,
  });

  factory MovieDetails.fromJson(Map<String, dynamic> json) {
    return MovieDetails(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? 'Unknown',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      overview: json['overview'] ?? '',
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
      releaseDate: json['release_date'] ?? json['first_air_date'],
      runtime: json['runtime'] ?? json['episode_run_time']?[0] ?? 0,
      genres: (json['genres'] as List?)
              ?.map((g) => Genre.fromJson(g))
              .toList() ??
          [],
      videos: (json['videos']?['results'] as List?)
              ?.map((v) => Video.fromJson(v))
              .toList() ??
          [],
      cast: (json['credits']?['cast'] as List?)
              ?.map((c) => Cast.fromJson(c))
              .take(10)
              .toList() ??
          [],
    );
  }

  String get posterUrl => TmdbConfig.getPosterUrl(posterPath);
  String get backdropUrl => TmdbConfig.getBackdropUrl(backdropPath);
  String get year => releaseDate?.split('-').first ?? 'N/A';
  String get runtimeFormatted => '${runtime ~/ 60}h ${runtime % 60}min';
  
  Video? get trailer {
    return videos.firstWhere(
      (v) => v.type == 'Trailer' && v.site == 'YouTube',
      orElse: () => videos.isNotEmpty ? videos.first : Video.empty(),
    );
  }
}

class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class Video {
  final String id;
  final String key;
  final String name;
  final String site;
  final String type;

  Video({
    required this.id,
    required this.key,
    required this.name,
    required this.site,
    required this.type,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? '',
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      site: json['site'] ?? '',
      type: json['type'] ?? '',
    );
  }

  factory Video.empty() {
    return Video(id: '', key: '', name: '', site: '', type: '');
  }

  bool get isYouTube => site == 'YouTube';
  bool get isTrailer => type == 'Trailer';
}

class Cast {
  final int id;
  final String name;
  final String character;
  final String? profilePath;

  Cast({
    required this.id,
    required this.name,
    required this.character,
    this.profilePath,
  });

  factory Cast.fromJson(Map<String, dynamic> json) {
    return Cast(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      character: json['character'] ?? '',
      profilePath: json['profile_path'],
    );
  }

  String get profileUrl => TmdbConfig.getPosterUrl(profilePath, size: TmdbConfig.profileSize);
}

