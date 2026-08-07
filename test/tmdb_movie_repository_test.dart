import 'dart:convert';

import 'package:cinema_movie/data/repositories/tmdb_movie_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('TmdbMovieRepository', () {
    test('fetchMoviesByGenre maps TMDB results into Movie models', () async {
      final responseBody = jsonEncode({
        'results': [
          {
            'id': 1,
            'title': 'Inception',
            'overview': 'A mind-bending thriller',
            'release_date': '2010-07-16',
            'vote_average': 8.8,
            'poster_path': '/inception.jpg',
          },
        ],
      });

      Uri? requestedUrl;
      final client = _FakeClient(
        response: http.Response(responseBody, 200),
        onGet: (url) => requestedUrl = url,
      );

      final repository = TmdbMovieRepository(client: client);
      final movies = await repository.fetchMoviesByGenre(28);

      expect(requestedUrl, isNotNull);
      expect(requestedUrl!.toString(), contains('discover/movie'));
      expect(requestedUrl.toString(), contains('with_genres=28'));
      expect(movies, hasLength(1));
      expect(movies.first.title, 'Inception');
      expect(
        movies.first.poster,
        'https://image.tmdb.org/t/p/w500/inception.jpg',
      );
    });
  });
}

class _FakeClient extends http.BaseClient {
  _FakeClient({required this.response, required this.onGet});

  final http.Response response;
  final void Function(Uri url) onGet;

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    onGet(url);
    return response;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
      request: request,
      reasonPhrase: response.reasonPhrase,
    );
  }
}
