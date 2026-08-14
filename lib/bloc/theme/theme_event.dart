import 'package:equatable/equatable.dart';

sealed class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class ThemeToggled extends ThemeEvent {
  const ThemeToggled(this.isDark);

  final bool isDark;

  @override
  List<Object?> get props => [isDark];
}
