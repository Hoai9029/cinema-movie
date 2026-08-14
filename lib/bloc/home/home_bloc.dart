import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/api/tmdb_api.dart';
import '../../data/models/tmdb_movie_response.dart';
import '../../models/movie.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._api) : super(const HomeInitial()) {
    on<HomeRequested>(_onRequested);
  }

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

  Future<void> _onRequested(
    HomeRequested event,
    Emitter<HomeState> emit,
  ) async {
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

  // Cầu nối cho RefreshIndicator: onRefresh cần 1 Future<void> hoàn
  // thành đúng lúc dữ liệu tải xong (không phải lúc add() được gọi)
  // để spinner hiển thị đúng thời gian chờ — add() một mình không trả
  // Future, nên chờ state kế tiếp không còn Loading.
  Future<void> refresh() {
    add(const HomeRequested());
    return stream.firstWhere(
      (state) => state is HomeLoaded || state is HomeError,
    );
  }
}
