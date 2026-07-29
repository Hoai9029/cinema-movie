import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

// ============================================================
// KHÁI NIỆM: LAYOUT — ROW + EXPANDED
// Tiêu đề của mỗi hàng phim (vd "Đang thịnh hành") + chữ
// "Xem tất cả" nằm bên phải. Đây là ví dụ kinh điển cho Expanded:
// - Text tiêu đề được bọc Expanded để "nở ra" chiếm hết khoảng
//   trống còn lại trong Row.
// - Text "Xem tất cả" giữ đúng kích thước của nó, được đẩy sát
//   lề phải nhờ tiêu đề bên trái đã chiếm hết chỗ trống.
// Nếu bỏ Expanded, hai Text sẽ dính sát nhau ở giữa màn hình
// thay vì tách ra hai đầu.
// ============================================================
class SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionTitle({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('Xem tất cả'),
          ),
      ],
    );
  }
}
