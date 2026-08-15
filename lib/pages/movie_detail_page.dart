import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../bloc/movie_detail/movie_detail_bloc.dart';
import '../bloc/movie_detail/movie_detail_bundle.dart';
import '../bloc/movie_detail/movie_detail_event.dart';
import '../bloc/movie_detail/movie_detail_state.dart';
import '../bloc/watchlist/watchlist_bloc.dart';
import '../bloc/watchlist/watchlist_event.dart';
import '../core/theme/app_colors.dart';
import '../data/api/tmdb_api.dart';
import '../data/api/tmdb_dio_client.dart';
import '../data/models/tmdb_movie_detail_response.dart';
import '../models/movie.dart';
import '../widgets/favorite_toast.dart';

// Dữ liệu phim đầy đủ hiện chưa có nguồn thật (chưa có backend cấp link
// phim) — dùng tạm 1 video YouTube làm giả lập cho nút "Xem ngay" cho
// tới khi API trả về link phim thật. Parse bằng chính hàm tiện ích của
// package thay vì tự cắt chuỗi tay.
final String _fakeFullMovieVideoId =
    YoutubePlayer.convertUrlToId(
      'https://youtu.be/h_1t3-6oWz4?si=FxuDuOyQbFtBOBED',
    ) ??
    '';

// Dữ liệu giả chỉ để dựng khung xương (skeleton) cho phần thông tin
// phim khi đang tải — Skeletonizer sẽ thay chữ/ảnh bằng khối bone
// xám lấp lánh, giữ nguyên bố cục thật của _LoadedSection.
final _fakeMovieDetailBundle = MovieDetailBundle(
  detail: const TmdbMovieDetailResponse(
    id: 0,
    title: 'Đang tải tên phim',
    overview:
        'Đang tải nội dung mô tả phim, đoạn văn bản giả này chỉ để giữ '
        'đúng chiều cao của khung xương trong lúc chờ dữ liệu thật.',
    posterPath: null,
    backdropPath: null,
    voteAverage: 0,
    runtime: 0,
    genres: [TmdbGenre(id: 0, name: 'Thể loại')],
  ),
  cast: List.generate(
    4,
    (_) => const TmdbCastMember(
      id: 0,
      name: 'Diễn viên',
      character: '',
      profilePath: null,
    ),
  ),
  videos: const [],
  similarMovies: List.generate(
    4,
    (i) => Movie(
      id: 'fake-$i',
      title: 'Tên phim',
      poster: '',
      duration: '',
      rating: 0,
      overview: '',
      genre: '',
    ),
  ),
);

class MovieDetailPage extends StatelessWidget {
  final Movie movie;
  // Tag Hero cho poster ở đầu trang. Phải khớp với heroTag của
  // MovieCard đã điều hướng tới đây; nếu không truyền, dùng tag mặc
  // định theo id phim (đủ dùng cho các màn chỉ có 1 danh sách phim,
  // ví dụ Yêu thích, Danh mục).
  final String? heroTag;

  const MovieDetailPage({super.key, required this.movie, this.heroTag});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = MovieDetailBloc(TmdbApi(buildTmdbDio()));
        final movieId = int.tryParse(movie.id);
        if (movieId != null) {
          bloc.add(MovieDetailRequested(movieId));
        }
        return bloc;
      },
      child: _MovieDetailView(
        movie: movie,
        heroTag: heroTag ?? 'poster-${movie.id}',
      ),
    );
  }
}

class _MovieDetailView extends StatefulWidget {
  const _MovieDetailView({required this.movie, required this.heroTag});

  final Movie movie;
  final String heroTag;

  @override
  State<_MovieDetailView> createState() => _MovieDetailViewState();
}

class _MovieDetailViewState extends State<_MovieDetailView> {
  // Một controller duy nhất dùng chung cho cả trailer lẫn "xem ngay":
  // đổi nguồn video bằng controller.load(id) thay vì tạo controller mới
  // mỗi lần, để không phải mở WebView mới hay gọi lại API chi tiết phim.
  YoutubePlayerController? _playerController;

  @override
  void dispose() {
    _playerController?.dispose();
    super.dispose();
  }

  void _startPlayback(String videoId) {
    setState(() {
      _playerController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
      );
    });
  }

  void _playFullMovie() {
    if (_fakeFullMovieVideoId.isEmpty) return;
    final controller = _playerController;
    if (controller == null) {
      _startPlayback(_fakeFullMovieVideoId);
    } else {
      controller.load(_fakeFullMovieVideoId);
    }
  }

  void _seekBy(Duration offset) {
    final controller = _playerController;
    if (controller == null) return;
    final duration = controller.metadata.duration;
    var target = controller.value.position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (duration > Duration.zero && target > duration) target = duration;
    controller.seekTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.watch<WatchlistBloc>().state.isFavorite(
      widget.movie.id,
    );

    return BlocConsumer<MovieDetailBloc, MovieDetailState>(
      // Khi chi tiết phim tải xong và có trailer, tự phát ngay — không
      // cần người dùng bấm nút play nữa.
      listener: (context, state) {
        if (state is MovieDetailLoaded && _playerController == null) {
          final trailer = state.bundle.trailerVideo;
          if (trailer != null) _startPlayback(trailer.key);
        }
      },
      builder: (context, state) {
        final controller = _playerController;
        if (controller == null) {
          return _buildScaffold(context, state, isFavorite, null);
        }

        // YoutubePlayerBuilder tự quản lý việc xoay ngang/fullscreen:
        // bấm nút fullscreen mặc định trong bottomActions sẽ khoá xoay
        // ngang + ẩn status bar; bấm back hoặc bấm lại nút đó sẽ tự thu
        // nhỏ về đúng vị trí nhúng trong trang detail này.
        return YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: controller,
            showVideoProgressIndicator: true,
            bottomActions: [
              const SizedBox(width: 8),
              const CurrentPosition(),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white),
                tooltip: 'Tua lùi 10 giây',
                onPressed: () => _seekBy(const Duration(seconds: -10)),
              ),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white),
                tooltip: 'Tua tới 10 giây',
                onPressed: () => _seekBy(const Duration(seconds: 10)),
              ),
              const ProgressBar(isExpanded: true),
              const RemainingDuration(),
              const FullScreenButton(),
            ],
          ),
          builder: (context, player) =>
              _buildScaffold(context, state, isFavorite, player),
        );
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    MovieDetailState state,
    bool isFavorite,
    Widget? player,
  ) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: FavoriteToastListener(
        child: Column(
          children: [
            // Header cố định NGOÀI ListView — video (nếu đang phát) đứng
            // yên khi cuộn, giống player ghim đầu trang của YouTube app,
            // chỉ phần thông tin bên dưới cuộn.
            _buildHeader(context, state, isFavorite, player),
            Expanded(
              // Header phía trên đã tự tiêu thụ topSafeArea rồi — nếu
              // không loại bỏ nó khỏi MediaQuery ở đây, ListView (không
              // truyền padding riêng) sẽ tự động cộng thêm đúng
              // topSafeArea đó vào đầu nội dung, cộng dồn với Padding
              // 16 bên dưới thành khoảng trống lớn bất thường.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildBody(context, state),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _playFullMovie,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Xem ngay', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    MovieDetailState state,
    bool isFavorite,
    Widget? player,
  ) {
    final backdropUrl =
        state is MovieDetailLoaded && state.bundle.detail.backdropUrl.isNotEmpty
        ? state.bundle.detail.backdropUrl
        : widget.movie.poster;

    // Vùng status bar/tai thỏ (punch-hole của Pixel 8...) khác nhau theo
    // từng máy — lấy đúng chiều cao thật thay vì đoán 1 số cố định, để
    // khung video/ảnh không bao giờ bắt đầu trước điểm này.
    final topSafeArea = MediaQuery.paddingOf(context).top;
    // Poster tĩnh dùng chung tỉ lệ 16:9 với video (thay vì 1 chiều cao cố
    // định khác) để khi trailer tự phát, khung header không đổi kích
    // thước đột ngột — chuyển mượt từ ảnh sang video tại đúng chỗ.
    final headerHeight = MediaQuery.sizeOf(context).width * 9 / 16;
    final buttonTop = topSafeArea + 8;

    return Stack(
      children: [
        Column(
          children: [
            // Nền cùng màu theme toàn màn hình lấp vùng status bar, để
            // video/ảnh không bị đẩy tràn lên sát mép trên hoặc bị punch-
            // hole che, đồng thời tạo cảm giác liền mạch với phần dưới.
            Container(
              height: topSafeArea,
              color: AppColors.backgroundOf(context),
            ),
            SizedBox(
              height: headerHeight,
              child:
                  player ??
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: widget.heroTag,
                        child: Container(
                          color: AppColors.card,
                          child: _buildPoster(backdropUrl, context),
                        ),
                      ),
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
                    ],
                  ),
            ),
          ],
        ),
        Positioned(
          top: buttonTop,
          left: 12,
          child: _CircleIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
        ),
        Positioned(
          top: buttonTop,
          right: 12,
          child: _CircleIconButton(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            iconColor: isFavorite ? AppColors.primary : Colors.white,
            onTap: () => context.read<WatchlistBloc>().add(
              WatchlistToggled(widget.movie),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, MovieDetailState state) {
    return switch (state) {
      MovieDetailInitial() || MovieDetailLoading() => Skeletonizer(
        enabled: true,
        child: _LoadedSection(
          movie: widget.movie,
          bundle: _fakeMovieDetailBundle,
        ),
      ),
      MovieDetailError(:final message) => _ErrorSection(
        message: message,
        onRetry: () {
          final movieId = int.tryParse(widget.movie.id);
          if (movieId != null) {
            context.read<MovieDetailBloc>().add(MovieDetailRequested(movieId));
          }
        },
      ),
      MovieDetailLoaded(:final bundle) => _LoadedSection(
        movie: widget.movie,
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
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.textFadedOf(context),
          ),
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
            Icon(
              Icons.access_time,
              size: 16,
              color: AppColors.textFadedOf(context),
            ),
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
  final Color iconColor;

  static const double size = 40;
  static const double iconSize = 20;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
