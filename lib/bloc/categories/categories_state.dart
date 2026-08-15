import 'package:equatable/equatable.dart';

import '../../models/movie.dart';

sealed class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => [];
}

class CategoriesInitial extends CategoriesState {
  const CategoriesInitial();
}

class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

class CategoriesLoaded extends CategoriesState {
  const CategoriesLoaded(
    this.movies, {
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<Movie> movies;
  // Còn trang tiếp theo để tải (infinite scroll) hay không.
  final bool hasMore;
  // Đang tải trang tiếp theo — hiển thị spinner ở cuối lưới.
  final bool isLoadingMore;

  @override
  List<Object?> get props => [movies, hasMore, isLoadingMore];
}

class CategoriesError extends CategoriesState {
  const CategoriesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
