import 'package:cinema_movie/cubit/movie_detail_bundle.dart';
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
      expect(loaded.bundle.trailerVideo?.key, 'xyz');
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
}
