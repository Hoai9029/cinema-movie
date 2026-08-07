import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_colors.dart';
import '../cubit/movie_detail_bundle.dart';
import '../cubit/movie_detail_cubit.dart';
import '../cubit/movie_detail_state.dart';
import '../data/api/tmdb_api.dart';
import '../data/api/tmdb_dio_client.dart';
import '../data/watchlist_state.dart';
import '../models/movie.dart';
import '../routes/app_router.dart';
import 'trailer_player_page.dart';

class MovieDetailPage extends StatelessWidget {
  final Movie movie;

  const MovieDetailPage({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = MovieDetailCubit(TmdbApi(buildTmdbDio()));
        final movieId = int.tryParse(movie.id);
        if (movieId != null) {
          cubit.loadMovieDetail(movieId);
        }
        return cubit;
      },
      child: _MovieDetailView(movie: movie),
    );
  }
}

class _MovieDetailView extends StatelessWidget {
  const _MovieDetailView({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final watchlist = context.watch<WatchlistState>();
    final isFavorite = watchlist.isFavorite(movie.id);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: BlocBuilder<MovieDetailCubit, MovieDetailState>(
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildHeader(context, state, isFavorite, watchlist),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildBody(context, state),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '${AppRoutes.watch}/${movie.id}',
                        arguments: movie,
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Xem ngay', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    MovieDetailState state,
    bool isFavorite,
    WatchlistState watchlist,
  ) {
    final backdropUrl =
        state is MovieDetailLoaded && state.bundle.detail.backdropUrl.isNotEmpty
        ? state.bundle.detail.backdropUrl
        : movie.poster;

    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppColors.card,
            child: _buildPoster(backdropUrl, context),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black45, Colors.transparent, Colors.black87],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _CircleIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _CircleIconButton(
              icon: isFavorite ? Icons.favorite : Icons.favorite_border,
              iconColor: isFavorite ? AppColors.primary : Colors.white,
              onTap: () => watchlist.toggleFavorite(movie),
            ),
          ),
          if (state is MovieDetailLoaded && state.bundle.trailerVideo != null)
            Center(
              child: _CircleIconButton(
                icon: Icons.play_arrow,
                size: 64,
                iconSize: 32,
                onTap: () {
                  final trailer = state.bundle.trailerVideo!;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrailerPlayerPage(
                        videoId: trailer.key,
                        title: trailer.name,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, MovieDetailState state) {
    return switch (state) {
      MovieDetailInitial() || MovieDetailLoading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
      MovieDetailError(:final message) => _ErrorSection(
        message: message,
        onRetry: () {
          final movieId = int.tryParse(movie.id);
          if (movieId != null) {
            context.read<MovieDetailCubit>().loadMovieDetail(movieId);
          }
        },
      ),
      MovieDetailLoaded(:final bundle) => _LoadedSection(
        movie: movie,
        bundle: bundle,
      ),
    };
  }

  Widget _buildPoster(String posterPath, BuildContext context) {
    if (posterPath.startsWith('http')) {
      return Image.network(
        posterPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _posterFallback(context),
      );
    }

    if (posterPath.isNotEmpty) {
      return Image.asset(
        posterPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _posterFallback(context),
      );
    }

    return _posterFallback(context);
  }

  Widget _posterFallback(BuildContext context) {
    return Center(
      child: Icon(Icons.movie, size: 80, color: AppColors.textFadedOf(context)),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  const _ErrorSection({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.textFadedOf(context)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textFadedOf(context)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _LoadedSection extends StatelessWidget {
  const _LoadedSection({required this.movie, required this.bundle});

  final Movie movie;
  final MovieDetailBundle bundle;

  @override
  Widget build(BuildContext context) {
    final detail = bundle.detail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.title.isNotEmpty ? detail.title : movie.title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textOf(context),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              detail.voteAverage.toStringAsFixed(1),
              style: TextStyle(color: AppColors.textFadedOf(context)),
            ),
            const SizedBox(width: 12),
            Icon(Icons.access_time, size: 16, color: AppColors.textFadedOf(context)),
            const SizedBox(width: 4),
            Text(
              bundle.runtimeLabel,
              style: TextStyle(color: AppColors.textFadedOf(context)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildGenreChips(context),
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
          detail.overview.isNotEmpty ? detail.overview : movie.overview,
          style: TextStyle(color: AppColors.textFadedOf(context), height: 1.5),
        ),
        const SizedBox(height: 20),
        if (bundle.cast.isNotEmpty) ...[
          Text(
            'Diễn viên',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textOf(context),
            ),
          ),
          const SizedBox(height: 12),
          _buildCastList(context),
          const SizedBox(height: 20),
        ],
        if (bundle.similarMovies.isNotEmpty) ...[
          Text(
            'Phim tương tự',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textOf(context),
            ),
          ),
          const SizedBox(height: 12),
          _buildSimilarMovies(context),
        ],
      ],
    );
  }

  Widget _buildGenreChips(BuildContext context) {
    final genres = bundle.genreNames.isNotEmpty
        ? bundle.genreNames
        : [movie.genre];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genres
          .map(
            (genre) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardOf(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                genre,
                style: TextStyle(
                  color: AppColors.textFadedOf(context),
                  fontSize: 12,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCastList(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: bundle.cast.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cast = bundle.cast[index];
          return SizedBox(
            width: 80,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: cast.profileUrl.isNotEmpty
                        ? Image.network(
                            cast.profileUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _castFallback(context),
                          )
                        : _castFallback(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  cast.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOf(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _castFallback(BuildContext context) {
    return Container(
      color: AppColors.cardOf(context),
      child: Icon(Icons.person, color: AppColors.textFadedOf(context)),
    );
  }

  Widget _buildSimilarMovies(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: bundle.similarMovies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final similarMovie = bundle.similarMovies[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailPage(movie: similarMovie),
                ),
              );
            },
            child: SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: similarMovie.poster.isNotEmpty
                          ? Image.network(
                              similarMovie.poster,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  _castFallback(context),
                            )
                          : _castFallback(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    similarMovie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOf(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

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
        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
