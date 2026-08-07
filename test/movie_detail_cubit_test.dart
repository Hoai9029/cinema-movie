import 'package:cinema_movie/cubit/movie_detail_cubit.dart';
import 'package:cinema_movie/cubit/movie_detail_state.dart';
import 'package:cinema_movie/data/api/tmdb_api.dart';
import 'package:cinema_movie/data/models/tmdb_movie_detail_response.dart';
import 'package:cinema_movie/data/models/tmdb_movie_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MovieDetailCubit', () {
    test('emits Loading then Loaded when all 4 requests succeed', () async {
      final api = _FakeTmdbApi();
      final cubit = MovieDetailCubit(api);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<MovieDetailLoading>(), isA<MovieDetailLoaded>()]),
      );

      await cubit.loadMovieDetail(693134);
      await expectation;

      final loaded = cubit.state as MovieDetailLoaded;
      expect(loaded.bundle.detail.title, 'Dune: Part Two');
      expect(loaded.bundle.runtimeLabel, '2h 46m');
      expect(loaded.bundle.genreNames, ['Science Fiction']);
      expect(loaded.bundle.cast, hasLength(1));
      expect(loaded.bundle.similarMovies, hasLength(1));
      expect(loaded.bundle.similarMovies.first.title, 'Dune');
    });

    test('emits Loading then Error when a request fails', () async {
      final api = _FakeTmdbApi(shouldThrow: true);
      final cubit = MovieDetailCubit(api);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<MovieDetailLoading>(), isA<MovieDetailError>()]),
      );

      await cubit.loadMovieDetail(693134);
      await expectation;
    });
  });
}

class _FakeTmdbApi implements TmdbApi {
  _FakeTmdbApi({this.shouldThrow = false});

  final bool shouldThrow;

  @override
  Future<TmdbMovieDetailResponse> getMovieDetail(
    int movieId,
    String language,
  ) async {
    if (shouldThrow) throw Exception('network error');
    return TmdbMovieDetailResponse.fromJson({
      'id': movieId,
      'title': 'Dune: Part Two',
      'overview': 'Paul Atreides unites with the Fremen.',
      'poster_path': '/poster.jpg',
      'backdrop_path': '/backdrop.jpg',
      'vote_average': 8.5,
      'runtime': 166,
      'genres': [
        {'id': 878, 'name': 'Science Fiction'},
      ],
    });
  }

  @override
  Future<TmdbCreditsResponse> getCredits(int movieId, String language) async {
    if (shouldThrow) throw Exception('network error');
    return TmdbCreditsResponse.fromJson({
      'cast': [
        {
          'id': 1,
          'name': 'Timothée Chalamet',
          'character': 'Paul Atreides',
          'profile_path': '/actor.jpg',
        },
      ],
    });
  }

  @override
  Future<TmdbVideosResponse> getVideos(int movieId, String language) async {
    if (shouldThrow) throw Exception('network error');
    return TmdbVideosResponse.fromJson({
      'results': [
        {
          'id': 'abc123',
          'key': 'xyz',
          'site': 'YouTube',
          'type': 'Trailer',
          'name': 'Official Trailer',
        },
      ],
    });
  }

  @override
  Future<TmdbMovieResponse> getSimilarMovies(
    int movieId,
    String language,
  ) async {
    if (shouldThrow) throw Exception('network error');
    return TmdbMovieResponse.fromJson({
      'results': [
        {
          'id': 438631,
          'title': 'Dune',
          'overview': 'Paul Atreides arrives on Arrakis.',
          'release_date': '2021-10-22',
          'vote_average': 8.0,
          'poster_path': '/dune.jpg',
        },
      ],
    });
  }
}
