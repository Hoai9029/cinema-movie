import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../data/fake_movies.dart';
import '../widgets/responsive_container.dart';
import 'movie_detail_page.dart';

// ============================================================
// KHÁI NIỆM: RESPONSIVE UI (áp dụng cho lưới ảnh - GridView)
// Màn Danh mục hiển thị TẤT CẢ phim dưới dạng lưới thay vì hàng
// ngang. Số cột của lưới không cố định — nó tính lại mỗi lần
// build dựa trên chiều rộng màn hình thực tế, nhờ LayoutBuilder.
// Đây là lý do khi bạn kéo giãn cửa sổ trình duyệt (chạy
// `flutter run -d chrome`), số cột phim sẽ tự tăng/giảm.
// ============================================================
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      maxWidth: 1100,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = responsiveGridColumns(constraints.maxWidth);

          // ListView ở ngoài để cả trang cuộn được (tiêu đề + lưới),
          // GridView bên trong dùng shrinkWrap vì nó nằm lồng trong
          // một ListView khác (không tự cuộn riêng nữa).
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Tất cả phim',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Đang hiện ${fakeMovies.length} phim theo dạng lưới '
                '($columns cột trên màn hình này)',
                style: const TextStyle(color: AppColors.textFaded, fontSize: 12),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fakeMovies.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (context, index) {
                  final movie = fakeMovies[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieDetailPage(movie: movie),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              color: AppColors.card,
                              width: double.infinity,
                              child: Image.asset(
                                movie.poster,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.movie, color: AppColors.textFaded),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          movie.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          movie.genre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textFaded,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
