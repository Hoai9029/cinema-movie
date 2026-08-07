import 'dart:async';

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../data/repositories/tmdb_movie_repository.dart';
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
  final TmdbMovieRepository _repository = TmdbMovieRepository();
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
  late Future<List<Movie>> _futureMovies;

  @override
  void initState() {
    super.initState();
    _selectedGenre = _genres.keys.first;
    _futureMovies = _repository.fetchMoviesByGenre(_genres[_selectedGenre]!);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _query = value.trim();
        if (_query.isEmpty) {
          _futureMovies = _repository.fetchMoviesByGenre(
            _genres[_selectedGenre]!,
          );
        } else {
          _selectedGenre = null;
          _futureMovies = _repository.searchMovies(_query);
        }
      });
    });
  }

  void _onGenreSelected(String genre) {
    setState(() {
      _selectedGenre = genre;
      _query = '';
      _searchController.clear();
      _futureMovies = _repository.fetchMoviesByGenre(_genres[genre]!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
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
    return FutureBuilder<List<Movie>>(
      future: _futureMovies,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Không thể tải phim lúc này.',
              style: TextStyle(color: AppColors.textFadedOf(context)),
            ),
          );
        }

        final movies = snapshot.data ?? [];
        if (movies.isEmpty) {
          return Center(
            child: Text(
              _query.isEmpty
                  ? 'Không tìm thấy phim cho thể loại này.'
                  : 'Không tìm thấy phim phù hợp với "$_query".',
              style: TextStyle(color: AppColors.textFadedOf(context)),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = responsiveGridColumns(constraints.maxWidth);
            return GridView.builder(
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
