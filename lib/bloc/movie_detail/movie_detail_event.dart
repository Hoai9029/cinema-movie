import 'package:equatable/equatable.dart';

sealed class MovieDetailEvent extends Equatable {
  const MovieDetailEvent();

  @override
  List<Object?> get props => [];
}

class MovieDetailRequested extends MovieDetailEvent {
  const MovieDetailRequested(this.movieId);

  final int movieId;

  @override
  List<Object?> get props => [movieId];
}
