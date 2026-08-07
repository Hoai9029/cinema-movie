import 'package:json_annotation/json_annotation.dart';

part 'tmdb_movie_detail_response.g.dart';

@JsonSerializable(createToJson: false)
class TmdbMovieDetailResponse {
  const TmdbMovieDetailResponse({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.runtime,
    required this.genres,
  });

  factory TmdbMovieDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$TmdbMovieDetailResponseFromJson(json);

  final int id;
  final String title;
  final String overview;
  @JsonKey(name: 'poster_path')
  final String? posterPath;
  @JsonKey(name: 'backdrop_path')
  final String? backdropPath;
  @JsonKey(name: 'vote_average')
  final double voteAverage;
  final int? runtime;
  final List<TmdbGenre> genres;

  String get posterUrl => posterPath == null || posterPath!.isEmpty
      ? ''
      : 'https://image.tmdb.org/t/p/w500$posterPath';

  String get backdropUrl => backdropPath == null || backdropPath!.isEmpty
      ? ''
      : 'https://image.tmdb.org/t/p/w780$backdropPath';
}

@JsonSerializable(createToJson: false)
class TmdbGenre {
  const TmdbGenre({required this.id, required this.name});

  factory TmdbGenre.fromJson(Map<String, dynamic> json) =>
      _$TmdbGenreFromJson(json);

  final int id;
  final String name;
}

@JsonSerializable(createToJson: false)
class TmdbCreditsResponse {
  const TmdbCreditsResponse({required this.cast});

  factory TmdbCreditsResponse.fromJson(Map<String, dynamic> json) =>
      _$TmdbCreditsResponseFromJson(json);

  final List<TmdbCastMember> cast;
}

@JsonSerializable(createToJson: false)
class TmdbCastMember {
  const TmdbCastMember({
    required this.id,
    required this.name,
    required this.character,
    required this.profilePath,
  });

  factory TmdbCastMember.fromJson(Map<String, dynamic> json) =>
      _$TmdbCastMemberFromJson(json);

  final int id;
  final String name;
  final String character;
  @JsonKey(name: 'profile_path')
  final String? profilePath;

  String get profileUrl => profilePath == null || profilePath!.isEmpty
      ? ''
      : 'https://image.tmdb.org/t/p/w185$profilePath';
}

@JsonSerializable(createToJson: false)
class TmdbVideosResponse {
  const TmdbVideosResponse({required this.results});

  factory TmdbVideosResponse.fromJson(Map<String, dynamic> json) =>
      _$TmdbVideosResponseFromJson(json);

  final List<TmdbVideo> results;
}

@JsonSerializable(createToJson: false)
class TmdbVideo {
  const TmdbVideo({
    required this.id,
    required this.key,
    required this.site,
    required this.type,
    required this.name,
  });

  factory TmdbVideo.fromJson(Map<String, dynamic> json) =>
      _$TmdbVideoFromJson(json);

  final String id;
  final String key;
  final String site;
  final String type;
  final String name;

  bool get isYoutubeTrailer => site == 'YouTube' && type == 'Trailer';
}
