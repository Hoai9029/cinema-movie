import 'package:equatable/equatable.dart';

class ThemeState extends Equatable {
  const ThemeState({required this.isDark});

  final bool isDark;

  @override
  List<Object?> get props => [isDark];
}
