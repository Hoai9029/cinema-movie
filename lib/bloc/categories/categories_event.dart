import 'package:equatable/equatable.dart';

sealed class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object?> get props => [];
}

class CategoriesGenreSelected extends CategoriesEvent {
  const CategoriesGenreSelected(this.genreId);

  final int genreId;

  @override
  List<Object?> get props => [genreId];
}

// Add() ngay mỗi keystroke; debounce 400ms được áp dụng ở
// CategoriesBloc (transformer trên on<CategoriesSearchChanged>), không
// còn Timer thủ công trong UI.
class CategoriesSearchChanged extends CategoriesEvent {
  const CategoriesSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

// Dùng cho pull-to-refresh: KHÔNG debounce, phát lại đúng truy vấn
// (search hoặc genre) đang active — Bloc tự nhớ truy vấn gần nhất.
class CategoriesRefreshRequested extends CategoriesEvent {
  const CategoriesRefreshRequested();
}
