import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/tmdb_secrets.dart';
import '../../models/movie.dart';
import '../models/tmdb_movie_response.dart';

class TmdbMovieRepository {
  TmdbMovieRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static String get _apiKey => TmdbSecrets.apiKey;
  static String get _accessToken => TmdbSecrets.accessToken;

  Future<List<Movie>> fetchTrendingMovies() async {
    final uri = Uri.parse('$_baseUrl/trending/movie/day?api_key=$_apiKey');
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('TMDB request failed: ${response.statusCode}');
    }

    return _mapTmdbMovies(response.body);
  }

  Future<List<Movie>> fetchMoviesByGenre(int genreId, {int page = 1}) async {
    final uri = Uri.parse(
      '$_baseUrl/discover/movie'
      '?api_key=$_apiKey&with_genres=$genreId'
      '&sort_by=popularity.desc&page=$page',
    );
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('TMDB request failed: ${response.statusCode}');
    }

    return _mapTmdbMovies(response.body);
  }

  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    final uri = Uri.parse(
      '$_baseUrl/search/movie'
      '?api_key=$_apiKey&query=${Uri.encodeQueryComponent(query)}'
      '&page=$page',
    );
    final response = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('TMDB request failed: ${response.statusCode}');
    }

    return _mapTmdbMovies(response.body);
  }

  List<Movie> _mapTmdbMovies(String responseBody) {
    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    final movies = TmdbMovieResponse.fromJson(json).results;

    return movies
        .map(
          (movie) => Movie(
            id: movie.id.toString(),
            title: movie.title,
            poster: movie.posterUrl,
            duration: movie.releaseDate.isEmpty
                ? 'Coming soon'
                : movie.releaseDate,
            rating: movie.voteAverage,
            overview: movie.overview.isEmpty
                ? 'No overview available.'
                : movie.overview,
            genre: 'TMDB',
          ),
        )
        .toList();
  }
}
