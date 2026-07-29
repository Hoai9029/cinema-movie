import 'package:flutter/material.dart';

// ============================================================
// KHÁI NIỆM: THEME (1/2)
// Tập trung toàn bộ màu sắc của app ở một nơi duy nhất.
// Muốn đổi tông màu cả app -> chỉ sửa ở đây, không phải lục
// từng file để đổi lẻ tẻ.
// ============================================================
class AppColors {
  static const Color background = Color(0xFF0F0F1A); // nền tối kiểu Netflix
  static const Color primary = Color(0xFFE21221); // đỏ chủ đạo
  static const Color card = Color(0xFF1E1E2E); // nền thẻ phim
  static const Color surface = Color(0xFF262638); // nền khối nổi (form, hộp thoại)
  static const Color text = Color(0xFFFFFFFF); // chữ chính
  static const Color textFaded = Color(0xFF9E9EAE); // chữ phụ, mờ hơn
  static const Color success = Color(0xFF2ECC71); // xanh báo thành công
}
