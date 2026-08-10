import 'package:equatable/equatable.dart';

import '../models/movie.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  const HomeLoaded({required this.movies, required this.genreMovies});

  final List<Movie> movies;
  final Map<String, List<Movie>> genreMovies;

  @override
  List<Object?> get props => [movies, genreMovies];
}

class HomeError extends HomeState {
  const HomeError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
