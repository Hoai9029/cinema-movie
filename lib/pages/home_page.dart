import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../data/fake_movies.dart';
import '../widgets/movie_card.dart';
import '../widgets/section_title.dart';
import '../widgets/responsive_container.dart';
import 'categories_page.dart';
import 'favorites_page.dart';
import 'movie_detail_page.dart';
import 'profile_page.dart';

// ============================================================
// KHÁI NIỆM: STATEFULWIDGET
// HomePage cần StatefulWidget vì nó phải NHỚ tab nào đang được
// chọn (_selectedIndex) và vẽ lại thanh điều hướng + nội dung
// mỗi khi người dùng bấm qua tab khác — StatelessWidget không
// giữ được giá trị này giữa các lần build.
// ============================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const _titles = ['Trang chủ', 'Danh mục', 'Yêu thích', 'Hồ sơ'];

  @override
  Widget build(BuildContext context) {
    // Widget Tree: mỗi tab tương ứng với MỘT widget con riêng biệt.
    // Scaffold chỉ hiển thị đúng 1 trong 4 widget này tại một thời
    // điểm, dựa theo _selectedIndex.
    final tabs = <Widget>[
      const _HomeTabContent(),
      const CategoriesPage(),
      const FavoritesPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(_titles[_selectedIndex]),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/images/avatar.png'),
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        // setState báo Flutter: "dữ liệu vừa đổi, vẽ lại giao diện đi".
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textFaded,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Danh mục'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Yêu thích'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}

// ============================================================
// Nội dung của tab "Trang chủ": banner nổi bật + các hàng phim
// theo thể loại. Tách ra thành widget riêng cho HomePage đỡ rối.
// StatelessWidget vì bản thân nó không tự thay đổi (chỉ hiển thị
// dữ liệu tĩnh từ fakeMovies).
// ============================================================
class _HomeTabContent extends StatelessWidget {
  const _HomeTabContent();

  @override
  Widget build(BuildContext context) {
    final genres = allGenres;
    final featured = fakeMovies.first;

    return ResponsiveContainer(
      maxWidth: 1000,
      // ListView: toàn bộ nội dung trang chủ cuộn theo chiều DỌC.
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --------------------------------------------------
          // KHÁI NIỆM: LAYOUT — STACK
          // Banner nổi bật gồm 3 lớp CHỒNG LÊN NHAU:
          //   Lớp 1 (dưới cùng): ảnh poster.
          //   Lớp 2: lớp phủ gradient tối dần xuống đáy, giúp chữ
          //          trắng phía trên luôn đọc được dù ảnh sáng.
          //   Lớp 3 (trên cùng): tên phim + nút Play, được định vị
          //          bằng Positioned ở góc dưới-trái.
          // Chỉ có Stack mới cho phép nhiều widget chồng lên nhau
          // như vậy — Column/Row luôn xếp widget CẠNH nhau, không
          // chồng lên nhau được.
          // --------------------------------------------------
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailPage(movie: featured),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Lớp 1: ảnh nền.
                    Image.asset(
                      featured.poster,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: AppColors.card);
                      },
                    ),
                    // Lớp 2: gradient tối dần xuống đáy.
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                    ),
                    // Lớp 3: chữ + nút play, neo ở góc dưới-trái.
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            featured.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.play_arrow, color: Colors.black, size: 18),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Xem ngay',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --------------------------------------------------
          // Một hàng ngang cho MỖI thể loại phim. Vòng lặp `for`
          // ở đây sinh ra danh sách widget động dựa trên dữ liệu,
          // thay vì gõ tay từng SectionTitle + ListView.
          // --------------------------------------------------
          for (final genre in genres) ...[
            SectionTitle(title: genre),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              // ListView ngang: danh sách phim của thể loại này
              // cuộn sang trái/phải.
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: moviesByGenre(genre).length,
                itemBuilder: (context, index) {
                  final movie = moviesByGenre(genre)[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieDetailPage(movie: movie),
                        ),
                      );
                    },
                    child: MovieCard(
                      title: movie.title,
                      rating: movie.rating.toString(),
                      imagePath: movie.poster,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
