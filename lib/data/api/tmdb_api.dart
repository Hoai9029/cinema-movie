import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/tmdb_movie_detail_response.dart';
import '../models/tmdb_movie_response.dart';

part 'tmdb_api.g.dart';

@RestApi(baseUrl: 'https://api.themoviedb.org/3')
abstract class TmdbApi {
  factory TmdbApi(Dio dio, {String baseUrl}) = _TmdbApi;

  @GET('/movie/{id}')
  Future<TmdbMovieDetailResponse> getMovieDetail(@Path('id') int movieId);

  @GET('/movie/{id}/credits')
  Future<TmdbCreditsResponse> getCredits(@Path('id') int movieId);

  @GET('/movie/{id}/videos')
  Future<TmdbVideosResponse> getVideos(@Path('id') int movieId);

  @GET('/movie/{id}/similar')
  Future<TmdbMovieResponse> getSimilarMovies(@Path('id') int movieId);

  @GET('/trending/movie/day')
  Future<TmdbMovieResponse> getTrendingMovies();

  @GET('/discover/movie')
  Future<TmdbMovieResponse> getMoviesByGenre(
    @Query('with_genres') int genreId, {
    @Query('sort_by') String sortBy = 'popularity.desc',
    @Query('page') int page = 1,
  });

  @GET('/search/movie')
  Future<TmdbMovieResponse> searchMovies(
    @Query('query') String query, {
    @Query('page') int page = 1,
  });
}
