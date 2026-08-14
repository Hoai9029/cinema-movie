import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/api/tmdb_api.dart';
import '../../data/models/tmdb_movie_response.dart';
import 'movie_detail_bundle.dart';
import 'movie_detail_event.dart';
import 'movie_detail_state.dart';

class MovieDetailBloc extends Bloc<MovieDetailEvent, MovieDetailState> {
  MovieDetailBloc(this._api) : super(const MovieDetailInitial()) {
    on<MovieDetailRequested>(_onRequested);
  }

  final TmdbApi _api;

  Future<void> _onRequested(
    MovieDetailRequested event,
    Emitter<MovieDetailState> emit,
  ) async {
    emit(const MovieDetailLoading());
    try {
      final (detail, credits, videos, similar) = await (
        _api.getMovieDetail(event.movieId),
        _api.getCredits(event.movieId),
        _api.getVideos(event.movieId),
        _api.getSimilarMovies(event.movieId),
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
