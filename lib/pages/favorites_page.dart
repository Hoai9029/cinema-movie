import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/watchlist/watchlist_bloc.dart';
import '../bloc/watchlist/watchlist_event.dart';
import '../core/theme/app_colors.dart';
import '../widgets/favorite_toast.dart';
import '../widgets/responsive_container.dart';
import '../routes/app_router.dart';

// ============================================================
// KHÁI NIỆM: LAYOUT — LISTVIEW (dọc) + STATE ĐƯỢC CHIA SẺ
// Trang này đọc danh sách phim yêu thích từ WatchlistBloc bằng
// `context.watch`. Vì watch(), mỗi khi có phim được thêm/bỏ ở
// màn Chi tiết phim, danh sách ở ĐÂY tự cập nhật theo — không
// cần Navigator.push chờ kết quả trả về hay gọi lại API gì cả.
// ============================================================
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FavoriteToastListener(child: _FavoritesList());
  }
}

class _FavoritesList extends StatelessWidget {
  const _FavoritesList();

  @override
  Widget build(BuildContext context) {
    final watchlist = context.watch<WatchlistBloc>().state;
    final favoriteMovies = watchlist.favoriteMovies;

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
                Navigator.pushNamed(
                  context,
                  '${AppRoutes.movie}/${movie.id}',
                  arguments: movie,
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
                      child: SizedBox(
                        width: 60,
                        height: 80,
                        child: _buildPoster(context, movie.poster),
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
                      onPressed: () => context.read<WatchlistBloc>().add(
                        WatchlistToggled(movie),
                      ),
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

  Widget _buildPoster(BuildContext context, String posterPath) {
    Widget fallback() => Container(
      color: AppColors.surfaceOf(context),
      child: Icon(Icons.movie, color: AppColors.textFadedOf(context)),
    );

    if (posterPath.isEmpty) return fallback();

    if (posterPath.startsWith('http')) {
      return Image.network(
        posterPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback(),
      );
    }

    return Image.asset(
      posterPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback(),
    );
  }
}
