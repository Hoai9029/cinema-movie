import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/tmdb_secrets.dart';

Dio buildTmdbDio() {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.themoviedb.org/3'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.queryParameters.putIfAbsent(
          'api_key',
          () => TmdbSecrets.apiKey,
        );
        options.headers['Authorization'] = 'Bearer ${TmdbSecrets.accessToken}';
        options.headers['accept'] = 'application/json';
        handler.next(options);
      },
      onError: (error, handler) {
        final requestInfo =
            '${error.requestOptions.method} ${error.requestOptions.uri}';
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;

        if (kDebugMode) {
          debugPrint('TMDB DEBUG ERROR: $requestInfo');
          debugPrint('TMDB DEBUG ERROR status: $statusCode');
          debugPrint('TMDB DEBUG ERROR message: ${error.message}');
          if (responseData != null) {
            debugPrint('TMDB DEBUG ERROR body: $responseData');
          }
        }

        handler.next(error);
      },
    ),
  );
  return dio;
}
