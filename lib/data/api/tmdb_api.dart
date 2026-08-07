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
}
