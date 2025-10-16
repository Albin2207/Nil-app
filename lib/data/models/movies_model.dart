class Movie {
  final String id;
  final String title;
  final String thumbnail;
  final double? rating;
  final String? year;

  Movie({
    required this.id,
    required this.title,
    required this.thumbnail,
    this.rating,
    this.year,
  });
}