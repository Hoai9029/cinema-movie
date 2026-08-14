import 'package:bloc_test/bloc_test.dart';
import 'package:cinema_movie/bloc/movie_detail/movie_detail_bloc.dart';
import 'package:cinema_movie/bloc/movie_detail/movie_detail_bundle.dart';
import 'package:cinema_movie/bloc/movie_detail/movie_detail_event.dart';
import 'package:cinema_movie/bloc/movie_detail/movie_detail_state.dart';
import 'package:cinema_movie/data/api/tmdb_api.dart';
import 'package:cinema_movie/data/models/tmdb_movie_detail_response.dart';
import 'package:cinema_movie/data/models/tmdb_movie_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MovieDetailBloc', () {
    blocTest<MovieDetailBloc, MovieDetailState>(
      'emits Loading then Loaded when all 4 requests succeed',
      build: () => MovieDetailBloc(_FakeTmdbApi()),
      act: (bloc) => bloc.add(const MovieDetailRequested(693134)),
      expect: () => [isA<MovieDetailLoading>(), isA<MovieDetailLoaded>()],
      verify: (bloc) {
        final loaded = bloc.state as MovieDetailLoaded;
        expect(loaded.bundle.detail.title, 'Dune: Part Two');
        expect(loaded.bundle.runtimeLabel, '2h 46m');
        expect(loaded.bundle.genreNames, ['Science Fiction']);
        expect(loaded.bundle.cast, hasLength(1));
        expect(loaded.bundle.similarMovies, hasLength(1));
        expect(loaded.bundle.similarMovies.first.title, 'Dune');
        expect(loaded.bundle.trailerVideo?.key, 'xyz');
      },
    );

    blocTest<MovieDetailBloc, MovieDetailState>(
      'emits Loading then Error when a request fails',
      build: () => MovieDetailBloc(_FakeTmdbApi(shouldThrow: true)),
      act: (bloc) => bloc.add(const MovieDetailRequested(693134)),
      expect: () => [isA<MovieDetailLoading>(), isA<MovieDetailError>()],
    );
  });

  group('MovieDetailBundle.trailerVideo', () {
    MovieDetailBundle bundleWithVideos(List<TmdbVideo> videos) {
      return MovieDetailBundle(
        detail: TmdbMovieDetailResponse.fromJson({
          'id': 1,
          'title': 'Test',
          'overview': '',
          'poster_path': null,
          'backdrop_path': null,
          'vote_average': 0,
          'runtime': null,
          'genres': [],
        }),
        cast: const [],
        videos: videos,
        similarMovies: const [],
      );
    }

    test('returns null when there are no videos', () {
      expect(bundleWithVideos(const []).trailerVideo, isNull);
    });

    test('returns null when no video is a YouTube trailer', () {
      final videos = [
        TmdbVideo.fromJson({
          'id': '1',
          'key': 'abc',
          'site': 'YouTube',
          'type': 'Teaser',
          'name': 'Teaser',
        }),
        TmdbVideo.fromJson({
          'id': '2',
          'key': 'def',
          'site': 'Vimeo',
          'type': 'Trailer',
          'name': 'Vimeo Trailer',
        }),
      ];
      expect(bundleWithVideos(videos).trailerVideo, isNull);
    });

    test('returns the first YouTube trailer when present', () {
      final videos = [
        TmdbVideo.fromJson({
          'id': '1',
          'key': 'abc',
          'site': 'YouTube',
          'type': 'Teaser',
          'name': 'Teaser',
        }),
        TmdbVideo.fromJson({
          'id': '2',
          'key': 'def',
          'site': 'YouTube',
          'type': 'Trailer',
          'name': 'Official Trailer',
        }),
      ];
      final trailer = bundleWithVideos(videos).trailerVideo;
      expect(trailer, isNotNull);
      expect(trailer!.key, 'def');
    });
  });
}

class _FakeTmdbApi implements TmdbApi {
  _FakeTmdbApi({this.shouldThrow = false});

  final bool shouldThrow;

  @override
  Future<TmdbMovieDetailResponse> getMovieDetail(int movieId) async {
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
  Future<TmdbCreditsResponse> getCredits(int movieId) async {
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
  Future<TmdbVideosResponse> getVideos(int movieId) async {
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
  Future<TmdbMovieResponse> getSimilarMovies(int movieId) async {
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

  @override
  Future<TmdbMovieResponse> getTrendingMovies() async {
    if (shouldThrow) throw Exception('network error');
    return const TmdbMovieResponse(results: []);
  }

  @override
  Future<TmdbMovieResponse> getMoviesByGenre(
    int genreId, {
    String sortBy = 'popularity.desc',
    int page = 1,
  }) async {
    if (shouldThrow) throw Exception('network error');
    return const TmdbMovieResponse(results: []);
  }

  @override
  Future<TmdbMovieResponse> searchMovies(String query, {int page = 1}) async {
    if (shouldThrow) throw Exception('network error');
    return const TmdbMovieResponse(results: []);
  }
}
