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
import '../routes/app_router.dart';

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
//
// CẬP NHẬT UI (theo ảnh mẫu):
//  - Banner nổi bật (giữ nguyên logic cũ)
//  - "Trending"            -> hàng ngang, lấy từ _futureMovies (giữ
//                             nguyên nguồn dữ liệu / logic fetch cũ)
//  - "Recommended For You" -> hàng ngang thứ hai, cũng lấy từ cùng
//                             _futureMovies nhưng là phần còn lại
//                             của danh sách (không gọi thêm API mới,
//                             không đổi logic fetch ban đầu)
//  - Bên dưới "Recommended For You": danh sách phim TƯƠNG TỰ, được
//    NHÓM THEO THỂ LOẠI (genre), lấy dữ liệu thật từ TMDB thông qua
//    repository (phần mở rộng logic MỚI, tách biệt hoàn toàn khỏi
//    _futureMovies cũ để không ảnh hưởng hành vi hiện có).
// ============================================================
class _HomeTabContent extends StatefulWidget {
  const _HomeTabContent();

  @override
  State<_HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<_HomeTabContent> {
  final TmdbMovieRepository _repository = TmdbMovieRepository();
  late Future<List<Movie>> _futureMovies;

  // ---- MỚI: dữ liệu "phim tương tự theo thể loại" ----
  // Map<tên thể loại, danh sách phim thuộc thể loại đó>.
  late Future<Map<String, List<Movie>>> _futureGenreMovies;

  // Chỉ số banner đang hiển thị, dùng để tô đậm dot indicator.
  int _currentBannerIndex = 0;
  late final PageController _bannerController;

  // Danh sách thể loại muốn hiển thị (id thể loại chuẩn của TMDB).
  // Có thể thay đổi/mở rộng tuỳ nhu cầu app.
  static const Map<int, String> _genresToShow = {
    28: 'Hành động', // Action
    35: 'Hài', // Comedy
    18: 'Chính kịch', // Drama
    10749: 'Lãng mạn', // Romance
    14: 'Viễn tưởng', // Fantasy
  };

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(viewportFraction: 0.9);
    _futureMovies = _repository.fetchTrendingMovies();
    // MỚI: gọi song song, không phụ thuộc / không đổi _futureMovies.
    _futureGenreMovies = _fetchMoviesGroupedByGenre();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  // MỚI: gọi TMDB để lấy phim tương tự, nhóm theo từng thể loại.
  // Dùng repository.fetchMoviesByGenre(genreId) - xem ghi chú cuối
  // file để thêm hàm này vào TmdbMovieRepository nếu chưa có.
  Future<Map<String, List<Movie>>> _fetchMoviesGroupedByGenre() async {
    final result = <String, List<Movie>>{};

    for (final entry in _genresToShow.entries) {
      try {
        final movies = await _repository.fetchMoviesByGenre(entry.key);
        if (movies.isNotEmpty) {
          result[entry.value] = movies;
        }
      } catch (_) {
        // Bỏ qua thể loại lỗi, không làm sập cả trang.
        continue;
      }
    }

    return result;
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

          if (snapshot.hasError) {
            debugPrint('TMDB fetchTrendingMovies error: ${snapshot.error}');
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  snapshot.hasError
                      ? 'Không thể tải phim từ TMDB lúc này.\n${snapshot.error}'
                      : 'Không thể tải phim từ TMDB lúc này.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final movies = snapshot.data!;

          // MỚI: lấy vài phim đầu để làm các banner trượt qua lại
          // (thay vì chỉ 1 banner tĩnh như trước). Vẫn lấy từ cùng
          // danh sách movies cũ, không gọi thêm API.
          final banners = movies.take(5).toList();

          // Chia danh sách gốc thành 2 phần để khớp với ảnh mẫu:
          // "Trending" và "Recommended For You". Không gọi thêm
          // API, không đổi logic fetch ban đầu.
          final trending = movies.take(6).toList();
          final recommended = movies.length > 6
              ? movies.skip(6).take(6).toList()
              : movies;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                height: 220,
                child: PageView.builder(
                  controller: _bannerController,
                  itemCount: banners.length,
                  onPageChanged: (index) {
                    setState(() => _currentBannerIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildBannerCard(context, banners[index]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // ---- MỚI: dot indicator cho banner ----
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(banners.length, (index) {
                  final isActive = index == _currentBannerIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textFadedOf(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // ---- "Trending" (thay cho "Phim mới nhất" cũ, theo ảnh mẫu) ----
              SectionTitle(title: 'Trending'),
              const SizedBox(height: 12),
              _buildMovieRow(context, trending, sectionKey: 'trending'),
              const SizedBox(height: 24),

              // ---- "Recommended For You" (hàng thứ 2 trong ảnh mẫu) ----
              SectionTitle(title: 'Recommended For You'),
              const SizedBox(height: 12),
              _buildMovieRow(context, recommended, sectionKey: 'recommended'),
              const SizedBox(height: 24),

              // ---- MỚI: danh sách phim tương tự, nhóm theo thể loại ----
              // Đặt ngay dưới "Recommended For You" như yêu cầu.
              _buildGenreSections(context),
            ],
          );
        },
      ),
    );
  }

  // Hàng ngang chứa các MovieCard - dùng chung cho Trending /
  // Recommended / các nhóm thể loại để không lặp code.
  //
  // sectionKey: cùng một phim có thể xuất hiện ở nhiều hàng khác nhau
  // trên trang (vd Trending và một thể loại nào đó đều có chung một
  // phim hot). Hero yêu cầu tag là DUY NHẤT trong toàn bộ trang tại
  // một thời điểm, nên mỗi hàng cần một tiền tố riêng để tránh crash
  // "multiple heroes share the same tag". Tag này được truyền thẳng
  // sang MovieDetailPage để Hero khớp đúng cặp nguồn - đích.
  Widget _buildMovieRow(
    BuildContext context,
    List<Movie> movies, {
    required String sectionKey,
  }) {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          final heroTag = 'poster-$sectionKey-${movie.id}';
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MovieDetailPage(movie: movie, heroTag: heroTag),
                ),
              );
            },
            child: MovieCard(
              title: movie.title,
              rating: movie.rating.toStringAsFixed(1),
              imagePath: movie.poster,
              heroTag: heroTag,
            ),
          );
        },
      ),
    );
  }

  // MỚI: khối "phim tương tự theo thể loại", lấy dữ liệu thật từ
  // TMDB (fetchMoviesByGenre). Mỗi thể loại là một SectionTitle +
  // một hàng ngang riêng, y hệt kiểu Trending/Recommended.
  Widget _buildGenreSections(BuildContext context) {
    return FutureBuilder<Map<String, List<Movie>>>(
      future: _futureGenreMovies,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final genreMovies = snapshot.data;
        if (genreMovies == null || genreMovies.isEmpty) {
          // Không chặn phần còn lại của trang nếu TMDB lỗi/rỗng.
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final genreEntry in genreMovies.entries) ...[
              SectionTitle(title: 'Tương tự - ${genreEntry.key}'),
              const SizedBox(height: 12),
              _buildMovieRow(
                context,
                genreEntry.value,
                sectionKey: 'genre-${genreEntry.key}',
              ),
              const SizedBox(height: 24),
            ],
          ],
        );
      },
    );
  }

  // MỚI: nội dung 1 banner trong carousel - y hệt UI banner cũ
  // (Stack + gradient + tiêu đề + nút "Xem ngay"), chỉ tách ra
  // thành hàm riêng để CarouselSlider.builder dùng lại cho mỗi item.
  Widget _buildBannerCard(BuildContext context, Movie movie) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '${AppRoutes.movie}/${movie.id}',
        arguments: movie,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPoster(movie.poster, context),
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
                      movie.title,
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

// ============================================================
// GHI CHÚ: thêm dòng sau vào pubspec.yaml (mục dependencies) rồi
// chạy `flutter pub get` để dùng được carousel_slider:
//
//   dependencies:
//     carousel_slider: ^4.2.1
// ============================================================

// ============================================================
// GHI CHÚ: cần thêm vào TmdbMovieRepository (file
// data/repositories/tmdb_movie_repository.dart) nếu repository
// của bạn CHƯA có hàm lấy phim theo thể loại. Hàm này gọi endpoint
// TMDB Discover, tương tự cách fetchTrendingMovies() hiện có của
// bạn đang gọi TMDB - chỉ đổi endpoint và tham số with_genres.
//
// Future<List<Movie>> fetchMoviesByGenre(int genreId, {int page = 1}) async {
//   final uri = Uri.parse(
//     'https://api.themoviedb.org/3/discover/movie'
//     '?api_key=$apiKey&language=vi-VN&with_genres=$genreId'
//     '&sort_by=popularity.desc&page=$page',
//   );
//   final response = await http.get(uri);
//   if (response.statusCode != 200) {
//     throw Exception('Không thể tải phim theo thể loại $genreId');
//   }
//   final data = jsonDecode(response.body) as Map<String, dynamic>;
//   final results = data['results'] as List<dynamic>;
//   return results.map((json) => Movie.fromJson(json)).toList();
// }
// ============================================================
