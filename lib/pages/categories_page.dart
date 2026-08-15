import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../bloc/categories/categories_bloc.dart';
import '../bloc/categories/categories_event.dart';
import '../bloc/categories/categories_state.dart';
import '../core/theme/app_colors.dart';
import '../data/api/tmdb_api.dart';
import '../data/api/tmdb_dio_client.dart';
import '../models/movie.dart';
import '../widgets/responsive_container.dart';
import '../routes/app_router.dart';

// ============================================================
// KHÁI NIỆM: RESPONSIVE UI (áp dụng cho lưới ảnh - GridView)
// Màn Danh mục hiển thị phim dưới dạng lưới, dữ liệu lấy thật từ
// TMDB (tìm kiếm theo tên hoặc lọc theo thể loại). Số cột của
// lưới không cố định — nó tính lại mỗi lần build dựa trên chiều
// rộng màn hình thực tế, nhờ LayoutBuilder.
// ============================================================
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late final CategoriesBloc _bloc;
  final TextEditingController _searchController = TextEditingController();

  // Thể loại hiển thị dạng chip, kèm id thể loại chuẩn của TMDB.
  // Đầy đủ 19 thể loại phim TMDB, tên dịch sang tiếng Việt cho đồng bộ.
  static const Map<String, int> _genres = {
    'Hành Động': 28,
    'Phiêu Lưu': 12,
    'Hoạt Hình': 16,
    'Hài': 35,
    'Tội Phạm': 80,
    'Tài Liệu': 99,
    'Chính Kịch': 18,
    'Gia Đình': 10751,
    'Giả Tưởng': 14,
    'Lịch Sử': 36,
    'Kinh Dị': 27,
    'Âm Nhạc': 10402,
    'Bí Ẩn': 9648,
    'Lãng Mạn': 10749,
    'Khoa Học Viễn Tưởng': 878,
    'Phim Truyền Hình': 10770,
    'Giật Gân': 53,
    'Chiến Tranh': 10752,
    'Viễn Tây': 37,
  };

  String? _selectedGenre;
  String _query = '';

  // Dữ liệu giả chỉ để dựng khung xương (skeleton) lưới phim khi
  // đang tải — Skeletonizer sẽ thay ảnh/tiêu đề bằng khối bone xám
  // lấp lánh, giữ nguyên hình dạng GridView thật.
  static final List<Movie> _fakeMovies = List.generate(
    12,
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

  @override
  void initState() {
    super.initState();
    _selectedGenre = _genres.keys.first;
    // API data không còn được gọi trực tiếp trong widget: CategoriesBloc
    // chịu trách nhiệm gọi TmdbApi (Dio/Retrofit) và phát ra state.
    // Debounce cho ô tìm kiếm cũng nằm trong CategoriesBloc (transformer
    // trên CategoriesSearchChanged), không còn Timer thủ công ở đây.
    _bloc = CategoriesBloc(
      TmdbApi(buildTmdbDio()),
      initialGenreId: _genres[_selectedGenre]!,
    )..add(CategoriesGenreSelected(_genres[_selectedGenre]!));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    setState(() {
      _query = query;
      if (query.isNotEmpty) _selectedGenre = null;
    });
    _bloc.add(CategoriesSearchChanged(value));
  }

  void _onGenreSelected(String genre) {
    setState(() {
      _selectedGenre = genre;
      _query = '';
      _searchController.clear();
    });
    _bloc.add(CategoriesGenreSelected(_genres[genre]!));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: ResponsiveContainer(
        maxWidth: 1100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(context),
              const SizedBox(height: 16),
              _buildGenreChips(context),
              const SizedBox(height: 16),
              Expanded(child: _buildMovieGrid(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      style: TextStyle(color: AppColors.textOf(context)),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm....',
        hintStyle: TextStyle(color: AppColors.textFadedOf(context)),
        prefixIcon: Icon(Icons.search, color: AppColors.textFadedOf(context)),
        filled: true,
        fillColor: AppColors.cardOf(context),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildGenreChips(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _genres.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = _genres.keys.elementAt(index);
          final isSelected = genre == _selectedGenre;
          return ChoiceChip(
            label: Text(genre),
            selected: isSelected,
            onSelected: (_) => _onGenreSelected(genre),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textOf(context),
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: AppColors.cardOf(context),
            selectedColor: AppColors.primary,
            shape: StadiumBorder(
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textFadedOf(context).withValues(alpha: 0.3),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMovieGrid(BuildContext context) {
    return BlocBuilder<CategoriesBloc, CategoriesState>(
      builder: (context, state) {
        // RefreshIndicator bọc NGOÀI mọi state (kể cả lỗi/rỗng) để
        // luôn kéo-để-tải-lại được. onRefresh gọi CategoriesBloc.refresh()
        // — Bloc tự nhớ truy vấn (search hoặc genre) đang active.
        return RefreshIndicator(
          onRefresh: _bloc.refresh,
          child: switch (state) {
            CategoriesInitial() || CategoriesLoading() => Skeletonizer(
              enabled: true,
              child: _buildGrid(context, _fakeMovies),
            ),
            CategoriesError(:final message) => _buildMessage(context, message),
            CategoriesLoaded(:final movies, :final isLoadingMore) =>
              movies.isEmpty
                  ? _buildMessage(
                      context,
                      _query.isEmpty
                          ? 'Không tìm thấy phim cho thể loại này.'
                          : 'Không tìm thấy phim phù hợp với "$_query".',
                    )
                  : _buildGrid(context, movies, showLoadingMore: isLoadingMore),
          },
        );
      },
    );
  }

  // Thông báo (lỗi / rỗng) đặt trong ListView có
  // AlwaysScrollableScrollPhysics để RefreshIndicator vẫn kéo được
  // dù nội dung không tràn màn hình.
  Widget _buildMessage(BuildContext context, String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textFadedOf(context)),
            ),
          ),
        ),
      ],
    );
  }

  // Infinite scroll: khi còn 300px là chạm đáy, xin bloc tải trang tiếp
  // theo. Bloc tự bỏ qua nếu đang tải hoặc đã hết trang nên gọi nhiều
  // lần lúc cuộn không sao.
  Widget _buildGrid(
    BuildContext context,
    List<Movie> movies, {
    bool showLoadingMore = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = responsiveGridColumns(constraints.maxWidth);
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 300) {
              _bloc.add(const CategoriesLoadMoreRequested());
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.58,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _MovieGridTile(movie: movies[index]),
                  childCount: movies.length,
                ),
              ),
              if (showLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MovieGridTile extends StatelessWidget {
  const _MovieGridTile({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '${AppRoutes.movie}/${movie.id}',
          arguments: movie,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppColors.cardOf(context),
                    child: _buildPoster(context),
                  ),
                  if (movie.rating > 0)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          movie.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textOf(context),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoster(BuildContext context) {
    if (movie.poster.isEmpty) {
      return Center(
        child: Icon(Icons.movie, color: AppColors.textFadedOf(context)),
      );
    }

    Widget errorBuilder(
      BuildContext context,
      Object error,
      StackTrace? stackTrace,
    ) {
      return Center(
        child: Icon(Icons.movie, color: AppColors.textFadedOf(context)),
      );
    }

    if (movie.poster.startsWith('http')) {
      return Image.network(
        movie.poster,
        fit: BoxFit.cover,
        errorBuilder: errorBuilder,
      );
    }

    return Image.asset(
      movie.poster,
      fit: BoxFit.cover,
      errorBuilder: errorBuilder,
    );
  }
}
