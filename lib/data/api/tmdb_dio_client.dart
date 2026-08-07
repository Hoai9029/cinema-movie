import 'package:dio/dio.dart';

import '../../config/tmdb_secrets.dart';

Dio buildTmdbDio() {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.themoviedb.org/3'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.queryParameters.putIfAbsent('api_key', () => TmdbSecrets.apiKey);
        options.headers['Authorization'] = 'Bearer ${TmdbSecrets.accessToken}';
        options.headers['accept'] = 'application/json';
        handler.next(options);
      },
    ),
  );
  return dio;
}
