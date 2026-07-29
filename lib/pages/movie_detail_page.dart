import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../data/watchlist_state.dart';
import '../models/movie.dart';
import 'watch_page.dart';

// ============================================================
// KHÁI NIỆM: STATELESSWIDGET nhận dữ liệu qua constructor
// MovieDetailPage không tự lưu trạng thái nội bộ nào (trạng thái
// yêu thích được lưu ở WatchlistState dùng chung, không phải ở
// đây) nên vẫn có thể là StatelessWidget dù giao diện "trông"
// động — vì phần động đó do widget CHA (Provider) quản lý, còn
// widget này chỉ ĐỌC và HIỂN THỊ dữ liệu được truyền vào.
// ============================================================
class MovieDetailPage extends StatelessWidget {
  final Movie movie; // Navigation: dữ liệu được truyền từ màn trước qua đây.

  const MovieDetailPage({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    // context.watch: nếu trạng thái yêu thích đổi (do người dùng
    // bấm tim ở MÀN KHÁC), icon trái tim ở đây cũng tự cập nhật.
    final watchlist = context.watch<WatchlistState>();
    final isFavorite = watchlist.isFavorite(movie.id);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // ------------------------------------------------
                // KHÁI NIỆM: LAYOUT — STACK
                // Ảnh nền phim + nút back + nút yêu thích + nút play
                // đều chồng lên nhau trên cùng một vùng ảnh, mỗi
                // nút được định vị bằng Positioned ở một góc riêng.
                // ------------------------------------------------
                SizedBox(
                  height: 300,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: AppColors.card,
                        child: Image.asset(
                          movie.poster,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.movie,
                                size: 80,
                                color: AppColors.textFadedOf(context),
                              ),
                            );
                          },
                        ),
                      ),
                      // Gradient để nút/icon phía trên luôn nổi rõ.
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black45,
                              Colors.transparent,
                              Colors.black87,
                            ],
                            stops: [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                      // Nút back, góc trên-trái.
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _CircleIconButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                      // Nút yêu thích, góc trên-phải.
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _CircleIconButton(
                          icon: isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          iconColor: isFavorite
                              ? AppColors.primary
                              : Colors.white,
                          onTap: () => watchlist.toggleFavorite(movie.id),
                        ),
                      ),
                      // Nút play lớn, chính giữa ảnh.
                      Center(
                        child: _CircleIconButton(
                          icon: Icons.play_arrow,
                          size: 64,
                          iconSize: 32,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WatchPage(movie: movie),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOf(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Row: nhãn thể loại + rating + thời lượng nằm
                      // cạnh nhau theo chiều ngang.
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardOf(context),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              movie.genre,
                              style: TextStyle(
                                color: AppColors.textFadedOf(context),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${movie.rating}  •  ${movie.duration}',
                            style: TextStyle(
                              color: AppColors.textFadedOf(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nội dung',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOf(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie.overview,
                        style: TextStyle(
                          color: AppColors.textFadedOf(context),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nút "Xem ngay" cố định ở đáy màn hình.
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigation: đẩy sang màn Xem phim, mang theo dữ
                  // liệu `movie` để WatchPage biết đang phát phim nào.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WatchPage(movie: movie),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Xem ngay', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Nút tròn nổi trên ảnh (dùng cho back / yêu thích / play).
// Tách widget riêng vì dùng lại 3 lần ở trên với style khác nhau.
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.iconSize = 20,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
