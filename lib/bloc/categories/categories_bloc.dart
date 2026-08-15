import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../data/api/tmdb_api.dart';
import '../../data/models/tmdb_movie_response.dart';
import '../../models/movie.dart';
import 'categories_event.dart';
import 'categories_state.dart';

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  CategoriesBloc(this._api, {required int initialGenreId})
    : _selectedGenreId = initialGenreId,
      super(const CategoriesInitial()) {
    on<CategoriesGenreSelected>(_onGenreSelected);
    // Gõ tìm kiếm: add() ngay mỗi keystroke, debounce 400ms + huỷ
    // request cũ khi có ký tự mới (switchMap) nằm ở transformer, thay
    // cho Timer thủ công trước đây trong categories_page.dart.
    on<CategoriesSearchChanged>(
      _onSearchChanged,
      transformer: (events, mapper) =>
          events.debounce(const Duration(milliseconds: 400)).switchMap(mapper),
    );
    on<CategoriesRefreshRequested>(_onRefreshRequested);
    on<CategoriesLoadMoreRequested>(_onLoadMoreRequested);
  }

  final TmdbApi _api;

  // Bloc tự nhớ truy vấn đang active (thể loại đã chọn hoặc từ khoá
  // tìm kiếm) để CategoriesRefreshRequested biết phát lại đúng cái gì
  // mà không cần UI truyền lại.
  int _selectedGenreId;
  String _query = '';

  // Trạng thái phân trang của truy vấn đang active — reset về trang 1
  // mỗi khi đổi thể loại/từ khoá tìm kiếm hoặc refresh.
  int _page = 1;
  int _totalPages = 1;
  List<Movie> _movies = [];

  Future<void> _onGenreSelected(
    CategoriesGenreSelected event,
    Emitter<CategoriesState> emit,
  ) async {
    _selectedGenreId = event.genreId;
    _query = '';
    await _loadByGenre(emit);
  }

  Future<void> _onSearchChanged(
    CategoriesSearchChanged event,
    Emitter<CategoriesState> emit,
  ) async {
    _query = event.query.trim();
    if (_query.isEmpty) {
      await _loadByGenre(emit);
    } else {
      await _search(emit, _query);
    }
  }

  Future<void> _onRefreshRequested(
    CategoriesRefreshRequested event,
    Emitter<CategoriesState> emit,
  ) {
    return _query.isEmpty ? _loadByGenre(emit) : _search(emit, _query);
  }

  Future<void> _onLoadMoreRequested(
    CategoriesLoadMoreRequested event,
    Emitter<CategoriesState> emit,
  ) async {
    final current = state;
    if (current is! CategoriesLoaded ||
        current.isLoadingMore ||
        !current.hasMore) {
      return;
    }
    emit(CategoriesLoaded(_movies, hasMore: true, isLoadingMore: true));
    final nextPage = _page + 1;
    try {
      final response = _query.isEmpty
          ? await _api.getMoviesByGenre(_selectedGenreId, page: nextPage)
          : await _api.searchMovies(_query, page: nextPage);
      _page = nextPage;
      _totalPages = response.totalPages;
      _movies = [..._movies, ...response.results.map((m) => m.toMovie())];
      emit(CategoriesLoaded(_movies, hasMore: _page < _totalPages));
    } catch (e) {
      // Tải thêm thất bại: giữ nguyên danh sách đã có, chỉ tắt spinner.
      emit(CategoriesLoaded(_movies, hasMore: current.hasMore));
    }
  }

  Future<void> _loadByGenre(Emitter<CategoriesState> emit) async {
    emit(const CategoriesLoading());
    _page = 1;
    try {
      final response = await _api.getMoviesByGenre(_selectedGenreId);
      _totalPages = response.totalPages;
      _movies = response.results.map((m) => m.toMovie()).toList();
      emit(CategoriesLoaded(_movies, hasMore: _page < _totalPages));
    } catch (e) {
      emit(const CategoriesError('Không thể tải phim lúc này.'));
    }
  }

  Future<void> _search(Emitter<CategoriesState> emit, String query) async {
    emit(const CategoriesLoading());
    _page = 1;
    try {
      final response = await _api.searchMovies(query);
      _totalPages = response.totalPages;
      _movies = response.results.map((m) => m.toMovie()).toList();
      emit(CategoriesLoaded(_movies, hasMore: _page < _totalPages));
    } catch (e) {
      emit(const CategoriesError('Không thể tải phim lúc này.'));
    }
  }

  // Cầu nối cho RefreshIndicator, cùng lý do với HomeBloc.refresh().
  Future<void> refresh() {
    add(const CategoriesRefreshRequested());
    return stream.firstWhere(
      (state) => state is CategoriesLoaded || state is CategoriesError,
    );
  }
}
