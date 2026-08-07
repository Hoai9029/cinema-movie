import 'package:equatable/equatable.dart';

import 'movie_detail_bundle.dart';

sealed class MovieDetailState extends Equatable {
  const MovieDetailState();

  @override
  List<Object?> get props => [];
}

class MovieDetailInitial extends MovieDetailState {
  const MovieDetailInitial();
}

class MovieDetailLoading extends MovieDetailState {
  const MovieDetailLoading();
}

class MovieDetailLoaded extends MovieDetailState {
  const MovieDetailLoaded(this.bundle);

  final MovieDetailBundle bundle;

  @override
  List<Object?> get props => [bundle];
}

class MovieDetailError extends MovieDetailState {
  const MovieDetailError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
