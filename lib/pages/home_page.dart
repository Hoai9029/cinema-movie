import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../data/repositories/tmdb_movie_repository.dart';
import '../models/movie.dart';
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
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundOf(context),
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
        backgroundColor: AppColors.cardOf(context),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textFadedOf(context),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Danh mục',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Yêu thích',
          ),
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
class _HomeTabContent extends StatefulWidget {
  const _HomeTabContent();

  @override
  State<_HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<_HomeTabContent> {
  final TmdbMovieRepository _repository = TmdbMovieRepository();
  late Future<List<Movie>> _futureMovies;

  @override
  void initState() {
    super.initState();
    _futureMovies = _repository.fetchTrendingMovies();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      maxWidth: 1000,
      child: FutureBuilder<List<Movie>>(
        future: _futureMovies,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Không thể tải phim từ TMDB lúc này.'),
            );
          }

          final movies = snapshot.data!;
          final featured = movies.first;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                        _buildPoster(featured.poster, context),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                        ),
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
                                  const Icon(
                                    Icons.play_arrow,
                                    color: Colors.black,
                                    size: 18,
                                  ),
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
              SectionTitle(title: 'Phim mới nhất'),
              const SizedBox(height: 12),
              SizedBox(
                height: 260,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
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
                        rating: movie.rating.toStringAsFixed(1),
                        imagePath: movie.poster,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPoster(String posterPath, BuildContext context) {
    if (posterPath.startsWith('http')) {
      return Image.network(
        posterPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(color: AppColors.cardOf(context));
        },
      );
    }

    if (posterPath.isNotEmpty) {
      return Image.asset(
        posterPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(color: AppColors.cardOf(context));
        },
      );
    }

    return Container(color: AppColors.cardOf(context));
  }
}
