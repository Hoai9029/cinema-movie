import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

// ============================================================
// KHÁI NIỆM: BASIC WIDGETS + STATELESSWIDGET
// MovieCard không tự thay đổi theo thời gian (chỉ hiển thị dữ
// liệu được truyền vào từ ngoài) -> dùng StatelessWidget là đủ,
// không cần StatefulWidget.
//
// Đây cũng là ví dụ về "tách widget để tái sử dụng": thay vì
// viết lặp lại cấu trúc thẻ phim ở Trang chủ, Danh mục, Yêu
// thích..., ta viết MỘT lần rồi dùng lại ở mọi nơi.
// ============================================================
class MovieCard extends StatelessWidget {
  final String title;
  final String rating;
  final String? imagePath;
  final double width;

  const MovieCard({
    super.key,
    required this.title,
    required this.rating,
    this.imagePath,
    this.width = 140,
  });

  @override
  Widget build(BuildContext context) {
    // Column: xếp ảnh -> tên phim -> rating theo chiều DỌC.
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 190,
              width: width,
              color: AppColors.card,
              // ASSETS: Image.asset đọc ảnh đã khai báo trong pubspec.yaml.
              // errorBuilder: nếu thiếu file ảnh, hiện icon thay vì crash app.
              child: imagePath != null && imagePath!.isNotEmpty
                  ? Image.asset(
                      imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.movie,
                            size: 40,
                            color: AppColors.textFaded,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(
                        Icons.movie,
                        size: 40,
                        color: AppColors.textFaded,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          // Row: xếp icon ngôi sao và số điểm theo chiều NGANG.
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text(rating, style: const TextStyle(color: AppColors.textFaded)),
            ],
          ),
        ],
      ),
    );
  }
}
