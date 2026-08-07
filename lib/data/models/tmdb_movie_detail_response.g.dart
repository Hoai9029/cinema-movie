// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tmdb_movie_detail_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TmdbMovieDetailResponse _$TmdbMovieDetailResponseFromJson(
  Map<String, dynamic> json,
) => TmdbMovieDetailResponse(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  overview: json['overview'] as String,
  posterPath: json['poster_path'] as String?,
  backdropPath: json['backdrop_path'] as String?,
  voteAverage: (json['vote_average'] as num).toDouble(),
  runtime: (json['runtime'] as num?)?.toInt(),
  genres: (json['genres'] as List<dynamic>)
      .map((e) => TmdbGenre.fromJson(e as Map<String, dynamic>))
      .toList(),
);

TmdbGenre _$TmdbGenreFromJson(Map<String, dynamic> json) =>
    TmdbGenre(id: (json['id'] as num).toInt(), name: json['name'] as String);

TmdbCreditsResponse _$TmdbCreditsResponseFromJson(Map<String, dynamic> json) =>
    TmdbCreditsResponse(
      cast: (json['cast'] as List<dynamic>)
          .map((e) => TmdbCastMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

TmdbCastMember _$TmdbCastMemberFromJson(Map<String, dynamic> json) =>
    TmdbCastMember(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      character: json['character'] as String,
      profilePath: json['profile_path'] as String?,
    );

TmdbVideosResponse _$TmdbVideosResponseFromJson(Map<String, dynamic> json) =>
    TmdbVideosResponse(
      results: (json['results'] as List<dynamic>)
          .map((e) => TmdbVideo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

TmdbVideo _$TmdbVideoFromJson(Map<String, dynamic> json) => TmdbVideo(
  id: json['id'] as String,
  key: json['key'] as String,
  site: json['site'] as String,
  type: json['type'] as String,
  name: json['name'] as String,
);
