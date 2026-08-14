import 'package:equatable/equatable.dart';

import '../../models/movie.dart';

// Tín hiệu cho BlocListener biết vừa có 1 lượt bấm tim thành công (để
// hiện toast) — không phải dữ liệu hiển thị, chỉ dùng để so sánh
// previous/current trong listenWhen.
class FavoriteToggle extends Equatable {
  const FavoriteToggle({required this.movieId, required this.isFavorite});

  final String movieId;
  final bool isFavorite;

  @override
  List<Object?> get props => [movieId, isFavorite];
}

class WatchlistState extends Equatable {
  const WatchlistState({this.favorites = const {}, this.lastToggle});

  final Map<String, Movie> favorites;
  final FavoriteToggle? lastToggle;

  bool isFavorite(String movieId) => favorites.containsKey(movieId);

  List<Movie> get favoriteMovies => favorites.values.toList();

  WatchlistState copyWith({
    Map<String, Movie>? favorites,
    FavoriteToggle? lastToggle,
  }) {
    return WatchlistState(
      favorites: favorites ?? this.favorites,
      lastToggle: lastToggle ?? this.lastToggle,
    );
  }

  @override
  List<Object?> get props => [favorites, lastToggle];
}
