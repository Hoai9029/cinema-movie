import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/api/tmdb_api.dart';
import '../data/models/tmdb_movie_response.dart';
import '../models/movie.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._api) : super(const HomeInitial());

  final TmdbApi _api;

  // Thể loại hiển thị "phim tương tự" theo hàng ngang riêng (id
  // thể loại chuẩn của TMDB). Giữ nguyên danh sách như bản cũ.
  static const Map<int, String> genresToShow = {
    28: 'Hành động', // Action
    35: 'Hài', // Comedy
    18: 'Chính kịch', // Drama
    10749: 'Lãng mạn', // Romance
    14: 'Viễn tưởng', // Fantasy
  };

  Future<void> loadHome() async {
    emit(const HomeLoading());
    try {
      final (trending, genreMovies) = await (
        _api.getTrendingMovies(),
        _fetchMoviesGroupedByGenre(),
      ).wait;

      emit(
        HomeLoaded(
          movies: trending.results.map((m) => m.toMovie()).toList(),
          genreMovies: genreMovies,
        ),
      );
    } catch (e) {
      emit(HomeError('Không thể tải phim từ TMDB lúc này.\n$e'));
    }
  }

  Future<Map<String, List<Movie>>> _fetchMoviesGroupedByGenre() async {
    final result = <String, List<Movie>>{};

    for (final entry in genresToShow.entries) {
      try {
        final response = await _api.getMoviesByGenre(entry.key);
        final movies = response.results.map((m) => m.toMovie()).toList();
        if (movies.isNotEmpty) {
          result[entry.value] = movies;
        }
      } catch (_) {
        // Bỏ qua thể loại lỗi, không làm sập cả trang.
        continue;
      }
    }

    return result;
  }
}
