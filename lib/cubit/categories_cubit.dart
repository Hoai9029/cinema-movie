import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/api/tmdb_api.dart';
import '../data/models/tmdb_movie_response.dart';
import 'categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit(this._api) : super(const CategoriesInitial());

  final TmdbApi _api;

  Future<void> loadByGenre(int genreId) async {
    emit(const CategoriesLoading());
    try {
      final response = await _api.getMoviesByGenre(genreId);
      emit(CategoriesLoaded(response.results.map((m) => m.toMovie()).toList()));
    } catch (e) {
      emit(CategoriesError('Không thể tải phim lúc này.'));
    }
  }

  Future<void> search(String query) async {
    emit(const CategoriesLoading());
    try {
      final response = await _api.searchMovies(query);
      emit(CategoriesLoaded(response.results.map((m) => m.toMovie()).toList()));
    } catch (e) {
      emit(CategoriesError('Không thể tải phim lúc này.'));
    }
  }
}
