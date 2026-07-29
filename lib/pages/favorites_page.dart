import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../data/fake_movies.dart';
import '../data/watchlist_state.dart';
import '../widgets/responsive_container.dart';
import 'movie_detail_page.dart';

// ============================================================
// KHÁI NIỆM: LAYOUT — LISTVIEW (dọc) + STATE ĐƯỢC CHIA SẺ
// Trang này đọc danh sách phim yêu thích từ WatchlistState bằng
// `context.watch`. Vì watch(), mỗi khi có phim được thêm/bỏ ở
// màn Chi tiết phim, danh sách ở ĐÂY tự cập nhật theo — không
// cần Navigator.push chờ kết quả trả về hay gọi lại API gì cả.
// ============================================================
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final watchlist = context.watch<WatchlistState>();
    final favoriteMovies = fakeMovies
        .where((m) => watchlist.isFavorite(m.id))
        .toList();

    if (favoriteMovies.isEmpty) {
      // Trạng thái rỗng: Column căn giữa gồm icon + 2 dòng chữ.
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 56,
              color: AppColors.textFadedOf(context),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có phim yêu thích',
              style: TextStyle(color: AppColors.textOf(context), fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Bấm biểu tượng trái tim ở trang chi tiết phim để lưu vào đây',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textFadedOf(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ResponsiveContainer(
      maxWidth: 800,
      // ListView: danh sách phim yêu thích cuộn theo chiều DỌC.
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favoriteMovies.length,
        itemBuilder: (context, index) {
          final movie = favoriteMovies[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MovieDetailPage(movie: movie),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardOf(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                // Row: ảnh poster nhỏ bên trái + thông tin bên phải.
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        movie.poster,
                        width: 60,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 80,
                            color: AppColors.surfaceOf(context),
                            child: Icon(
                              Icons.movie,
                              color: AppColors.textFadedOf(context),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Expanded: khối thông tin chiếm hết chỗ trống còn
                    // lại trong Row, để nút trái tim luôn nằm sát phải.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            style: TextStyle(
                              color: AppColors.textOf(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${movie.genre} • ${movie.duration}',
                            style: TextStyle(
                              color: AppColors.textFadedOf(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.favorite,
                        color: AppColors.primary,
                      ),
                      onPressed: () => watchlist.toggleFavorite(movie.id),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
