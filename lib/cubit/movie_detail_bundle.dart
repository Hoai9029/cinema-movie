import '../data/models/tmdb_movie_detail_response.dart';
import '../models/movie.dart';

class MovieDetailBundle {
  const MovieDetailBundle({
    required this.detail,
    required this.cast,
    required this.videos,
    required this.similarMovies,
  });

  final TmdbMovieDetailResponse detail;
  final List<TmdbCastMember> cast;
  final List<TmdbVideo> videos;
  final List<Movie> similarMovies;

  String get runtimeLabel {
    final minutes = detail.runtime ?? 0;
    if (minutes <= 0) return 'N/A';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return hours > 0 ? '${hours}h ${remaining}m' : '${remaining}m';
  }

  List<String> get genreNames => detail.genres.map((g) => g.name).toList();
}
