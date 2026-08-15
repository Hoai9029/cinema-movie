import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../bloc/home/home_bloc.dart';
import '../bloc/home/home_event.dart';
import '../bloc/home/home_state.dart';
import '../bloc/profile/profile_bloc.dart';
import '../bloc/profile/profile_event.dart';
import '../bloc/profile/profile_state.dart';
import '../core/constants/app_avatars.dart';
import '../core/theme/app_colors.dart';
import '../data/api/tmdb_api.dart';
import '../data/api/tmdb_dio_client.dart';
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

  // Widget Tree: mỗi tab tương ứng với MỘT widget con riêng biệt.
  // Khai báo MỘT LẦN ở đây (không phải trong build()) và giữ nguyên
  // instance trong suốt vòng đời của _HomePageState, để IndexedStack
  // bên dưới luôn nhận đúng cùng 4 widget mỗi lần build.
  static const _tabs = <Widget>[
    _HomeTabContent(),
    CategoriesPage(),
    FavoritesPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Nạp hồ sơ (tên/SĐT/avatar) MỘT LẦN khi vào Home. ProfileBloc
    // được tạo ở gốc app (main.dart) nên header dưới đây và
    // ProfilePage đều đọc chung state này.
    context.read<ProfileBloc>().add(const ProfileStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundOf(context),
        title: Text(_titles[_selectedIndex]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                return CircleAvatar(
                  backgroundImage: AssetImage(
                    AppAvatars.pathOf(state.avatarId),
                  ),
                  backgroundColor: AppColors.primary,
                );
              },
            ),
          ),
        ],
      ),
      // IndexedStack giữ CẢ 4 tab luôn mounted trong cây widget cùng
      // lúc (chỉ ẩn/hiện bằng cách chọn index để vẽ), thay vì trước
      // đây body chỉ chứa DUY NHẤT 1 widget (tabs[_selectedIndex]).
      // Khi chỉ 1 widget tồn tại trong tree, chuyển tab sẽ làm Flutter
      // dispose() State của tab cũ và tạo State mới toanh cho tab kế
      // tiếp mỗi khi quay lại — mất vị trí cuộn, mất lựa chọn thể
      // loại, và HomeCubit/CategoriesCubit bị tạo lại nên gọi lại API
      // từ đầu. Với IndexedStack, State của cả 4 tab (và Cubit của
      // chúng) chỉ được tạo đúng 1 lần, tồn tại xuyên suốt vòng đời
      // HomePage.
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      // Theme() bọc ngoài để TẮT hiệu ứng ripple "sóng nước" mặc định
      // của Material 3 (InkSparkle) khi bấm vào từng tab. Các app thực
      // tế (Instagram, YouTube, Zalo...) chỉ đổi màu icon/label ngay
      // lập tức, không có gợn sóng lan tỏa loè loẹt.
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          // setState báo Flutter: "dữ liệu vừa đổi, vẽ lại giao diện đi".
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: AppColors.cardOf(context),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textFadedOf(context),
          type: BottomNavigationBarType.fixed,
          enableFeedback: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
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
  late final HomeBloc _bloc;

  // Chỉ số banner đang hiển thị, dùng để tô đậm dot indicator.
  // CarouselSlider tự quản lý việc scroll/auto-play; ta chỉ cần lắng
  // nghe onPageChanged để biết index hiện tại cho dot indicator.
  int _currentBannerIndex = 0;

  // Dữ liệu giả dùng làm khung xương (skeleton) khi đang tải. Chỉ
  // cần đúng SỐ LƯỢNG và HÌNH DẠNG (không cần nội dung thật) vì
  // Skeletonizer sẽ tự thay các Text/Image bên trong bằng khối bone
  // màu xám lấp lánh (shimmer), giữ nguyên kích thước layout thật.
  static final List<Movie> _fakeMovies = List.generate(
    8,
    (i) => Movie(
      id: 'fake-$i',
      title: 'Đang tải tên phim',
      poster: '',
      duration: '',
      rating: 0,
      overview: '',
      genre: '',
    ),
  );

  static final Map<String, List<Movie>> _fakeGenreMovies = {
    for (final entry in HomeBloc.genresToShow.entries)
      entry.value: List.generate(
        4,
        (i) => Movie(
          id: 'fake-${entry.key}-$i',
          title: 'Đang tải tên phim',
          poster: '',
          duration: '',
          rating: 0,
          overview: '',
          genre: '',
        ),
      ),
  };

  @override
  void initState() {
    super.initState();
    // API data không còn được gọi trực tiếp trong widget: HomeBloc
    // chịu trách nhiệm gọi TmdbApi (Dio/Retrofit) và phát ra state.
    _bloc = HomeBloc(TmdbApi(buildTmdbDio()))..add(const HomeRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: ResponsiveContainer(
        maxWidth: 1000,
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            // RefreshIndicator bọc NGOÀI mọi state (kể cả lỗi) để
            // người dùng luôn có thể kéo-để-tải-lại, không chỉ khi
            // đã có dữ liệu. onRefresh gọi HomeBloc.refresh() — add()
            // event rồi chờ tới khi state không còn Loading, để
            // spinner hiển thị đúng thời gian chờ dữ liệu.
            return RefreshIndicator(
              onRefresh: _bloc.refresh,
              child: switch (state) {
                HomeInitial() || HomeLoading() => Skeletonizer(
                  enabled: true,
                  child: _buildLoaded(context, _fakeMovies, _fakeGenreMovies),
                ),
                HomeError(:final message) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(message, textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  ],
                ),
                HomeLoaded(:final movies, :final genreMovies) => _buildLoaded(
                  context,
                  movies,
                  genreMovies,
                ),
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    List<Movie> movies,
    Map<String, List<Movie>> genreMovies,
  ) {
    if (movies.isEmpty) {
      // ListView (thay vì Center) để RefreshIndicator vẫn kéo được
      // ngay cả khi danh sách rỗng.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Không thể tải phim từ TMDB lúc này.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }

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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        CarouselSlider.builder(
          itemCount: banners.length,
          itemBuilder: (context, index, realIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildBannerCard(context, banners[index]),
            );
          },
          options: CarouselOptions(
            height: 220,
            viewportFraction: 0.9,
            enableInfiniteScroll: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 600),
            onPageChanged: (index, reason) {
              setState(() => _currentBannerIndex = index);
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
        _buildGenreSections(context, genreMovies),
      ],
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
  Widget _buildGenreSections(
    BuildContext context,
    Map<String, List<Movie>> genreMovies,
  ) {
    if (genreMovies.isEmpty) {
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
