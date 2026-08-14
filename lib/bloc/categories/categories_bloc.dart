import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

import '../../data/api/tmdb_api.dart';
import '../../data/models/tmdb_movie_response.dart';
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
  }

  final TmdbApi _api;

  // Bloc tự nhớ truy vấn đang active (thể loại đã chọn hoặc từ khoá
  // tìm kiếm) để CategoriesRefreshRequested biết phát lại đúng cái gì
  // mà không cần UI truyền lại.
  int _selectedGenreId;
  String _query = '';

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

  Future<void> _loadByGenre(Emitter<CategoriesState> emit) async {
    emit(const CategoriesLoading());
    try {
      final response = await _api.getMoviesByGenre(_selectedGenreId);
      emit(
        CategoriesLoaded(response.results.map((m) => m.toMovie()).toList()),
      );
    } catch (e) {
      emit(const CategoriesError('Không thể tải phim lúc này.'));
    }
  }

  Future<void> _search(Emitter<CategoriesState> emit, String query) async {
    emit(const CategoriesLoading());
    try {
      final response = await _api.searchMovies(query);
      emit(
        CategoriesLoaded(response.results.map((m) => m.toMovie()).toList()),
      );
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
