import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../core/theme/app_colors.dart';
import '../cubit/categories_cubit.dart';
import '../cubit/categories_state.dart';
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
  late final CategoriesCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Thể loại hiển thị dạng chip, kèm id thể loại chuẩn của TMDB.
  static const Map<String, int> _genres = {
    'Horror': 27,
    'Romance': 10749,
    'Action': 28,
    'Fantasy': 14,
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

  // Tải lại đúng dữ liệu đang hiển thị (theo từ khoá tìm kiếm nếu có,
  // ngược lại theo thể loại đang chọn) — dùng chung cho pull-to-refresh.
  Future<void> _refresh() {
    return _query.isEmpty
        ? _cubit.loadByGenre(_genres[_selectedGenre ?? _genres.keys.first]!)
        : _cubit.search(_query);
  }

  @override
  void initState() {
    super.initState();
    _selectedGenre = _genres.keys.first;
    // API data không còn được gọi trực tiếp trong widget: CategoriesCubit
    // chịu trách nhiệm gọi TmdbApi (Dio/Retrofit) và phát ra state.
    _cubit = CategoriesCubit(TmdbApi(buildTmdbDio()))
      ..loadByGenre(_genres[_selectedGenre]!);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _query = value.trim());
      if (_query.isEmpty) {
        _cubit.loadByGenre(_genres[_selectedGenre]!);
      } else {
        setState(() => _selectedGenre = null);
        _cubit.search(_query);
      }
    });
  }

  void _onGenreSelected(String genre) {
    setState(() {
      _selectedGenre = genre;
      _query = '';
      _searchController.clear();
    });
    _cubit.loadByGenre(_genres[genre]!);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
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
        hintText: 'Search....',
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
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        // RefreshIndicator bọc NGOÀI mọi state (kể cả lỗi/rỗng) để
        // luôn kéo-để-tải-lại được. onRefresh gọi lại đúng hàm cubit
        // đang dùng (loadByGenre hoặc search) qua _refresh().
        return RefreshIndicator(
          onRefresh: _refresh,
          child: switch (state) {
            CategoriesInitial() || CategoriesLoading() => Skeletonizer(
              enabled: true,
              child: _buildGrid(context, _fakeMovies),
            ),
            CategoriesError(:final message) => _buildMessage(
              context,
              message,
            ),
            CategoriesLoaded(:final movies) => movies.isEmpty
                ? _buildMessage(
                    context,
                    _query.isEmpty
                        ? 'Không tìm thấy phim cho thể loại này.'
                        : 'Không tìm thấy phim phù hợp với "$_query".',
                  )
                : _buildGrid(context, movies),
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

  Widget _buildGrid(BuildContext context, List<Movie> movies) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = responsiveGridColumns(constraints.maxWidth);
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: movies.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.58,
          ),
          itemBuilder: (context, index) {
            return _MovieGridTile(movie: movies[index]);
          },
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

    Widget errorBuilder(BuildContext context, Object error, StackTrace? stackTrace) {
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
