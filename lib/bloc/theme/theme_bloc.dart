import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import 'theme_event.dart';
import 'theme_state.dart';

// ============================================================
// LƯU TRỮ: Hive box "settings" (toàn thiết bị, không theo từng
// tài khoản như WatchlistBloc/HistoryBloc) — nút bật/tắt "Chế độ
// tối" trong hồ sơ vốn không gắn với uid nào, nên chỉ cần 1 giá
// trị dùng chung cho cả máy.
// ============================================================
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc({Box? settingsBox})
    : _settingsBox = settingsBox,
      super(
        ThemeState(
          isDark: settingsBox?.get(_isDarkModeKey, defaultValue: false) ??
              false,
        ),
      ) {
    on<ThemeToggled>((event, emit) {
      emit(ThemeState(isDark: event.isDark));
      _settingsBox?.put(_isDarkModeKey, event.isDark);
    });
  }

  final Box? _settingsBox;

  static const _isDarkModeKey = 'isDarkMode';
}
