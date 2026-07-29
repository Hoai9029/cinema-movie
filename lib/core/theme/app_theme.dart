import 'package:flutter/material.dart';
import 'app_colors.dart';

// ============================================================
// KHÁI NIỆM: THEME (2/2)
// ThemeData được gắn vào MaterialApp trong main.dart bằng
// `theme: AppTheme.dark`. Từ đó MỌI widget con trong app đều
// có thể đọc lại theme này bằng `Theme.of(context)` thay vì
// phải truyền màu/font đi khắp nơi.
// ============================================================
class AppTheme {
  static ThemeData dark = ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    fontFamily: 'Roboto',
    brightness: Brightness.dark,
    useMaterial3: true,

    // Khai báo sẵn kiểu chữ dùng chung, để lấy qua Theme.of(context).textTheme
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: AppColors.text,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(color: AppColors.textFaded, fontSize: 14),
    ),

    // Style dùng chung cho mọi ô nhập liệu (TextField/TextFormField)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    ),

    // Style dùng chung cho mọi ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  static ThemeData light = ThemeData(
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    primaryColor: AppColors.primary,
    fontFamily: 'Roboto',
    brightness: Brightness.light,
    useMaterial3: true,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: Color(0xFF111111),
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      bodyMedium: TextStyle(color: Color(0xFF666666), fontSize: 14),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFEDEDED),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
