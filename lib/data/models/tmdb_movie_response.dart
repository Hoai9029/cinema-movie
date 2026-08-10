import '../../models/movie.dart';

class TmdbMovieResponse {
  const TmdbMovieResponse({required this.results});

  factory TmdbMovieResponse.fromJson(Map<String, dynamic> json) {
    final results =
        (json['results'] as List?)
            ?.map((item) => TmdbMovie.fromJson(item as Map<String, dynamic>))
            .toList() ??
        <TmdbMovie>[];
    return TmdbMovieResponse(results: results);
  }

  final List<TmdbMovie> results;
}

class TmdbMovie {
  const TmdbMovie({
    required this.id,
    required this.title,
    required this.overview,
    required this.releaseDate,
    required this.voteAverage,
    required this.posterPath,
  });

  factory TmdbMovie.fromJson(Map<String, dynamic> json) {
    return TmdbMovie(
      id: json['id'] as int,
      title: json['title']?.toString() ?? 'Untitled',
      overview: json['overview']?.toString() ?? '',
      releaseDate: json['release_date']?.toString() ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      posterPath: json['poster_path']?.toString() ?? '',
    );
  }

  final int id;
  final String title;
  final String overview;
  final String releaseDate;
  final double voteAverage;
  final String posterPath;

  String get posterUrl =>
      posterPath.isEmpty ? '' : 'https://image.tmdb.org/t/p/w500$posterPath';
}

extension TmdbMovieMapper on TmdbMovie {
  Movie toMovie({String genre = 'TMDB'}) => Movie(
    id: id.toString(),
    title: title,
    poster: posterUrl,
    duration: releaseDate.isEmpty ? 'Coming soon' : releaseDate,
    rating: voteAverage,
    overview: overview.isEmpty ? 'No overview available.' : overview,
    genre: genre,
  );
}
