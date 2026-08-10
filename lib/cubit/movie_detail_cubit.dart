import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/api/tmdb_api.dart';
import '../data/models/tmdb_movie_response.dart';
import 'movie_detail_bundle.dart';
import 'movie_detail_state.dart';

class MovieDetailCubit extends Cubit<MovieDetailState> {
  MovieDetailCubit(this._api) : super(const MovieDetailInitial());

  final TmdbApi _api;

  Future<void> loadMovieDetail(int movieId) async {
    emit(const MovieDetailLoading());
    try {
      final (detail, credits, videos, similar) = await (
        _api.getMovieDetail(movieId),
        _api.getCredits(movieId),
        _api.getVideos(movieId),
        _api.getSimilarMovies(movieId),
      ).wait;

      final similarMovies = similar.results.map((m) => m.toMovie()).toList();

      emit(
        MovieDetailLoaded(
          MovieDetailBundle(
            detail: detail,
            cast: credits.cast,
            videos: videos.results,
            similarMovies: similarMovies,
          ),
        ),
      );
    } catch (e) {
      emit(MovieDetailError('Không thể tải thông tin phim: $e'));
    }
  }
}
