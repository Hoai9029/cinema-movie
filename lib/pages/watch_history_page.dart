import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/history/history_bloc.dart';
import '../bloc/history/history_event.dart';
import '../core/theme/app_colors.dart';
import '../widgets/responsive_container.dart';
import 'movie_detail_page.dart';

class WatchHistoryPage extends StatelessWidget {
  const WatchHistoryPage({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xoá toàn bộ lịch sử xem?'),
        content: const Text(
          'Hành động này sẽ xoá toàn bộ lịch sử xem và không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Xoá',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<HistoryBloc>().add(const HistoryCleared());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.textOf(context)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Lịch sử xem',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textOf(context),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppColors.textOf(context),
                    ),
                    onPressed: () => _confirmClear(context),
                  ),
                ],
              ),
            ),
            const Expanded(child: _HistoryList()),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryBloc>().state.history;

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 56,
              color: AppColors.textFadedOf(context),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có phim nào trong lịch sử xem',
              style: TextStyle(color: AppColors.textOf(context), fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Phim bạn xem trailer sẽ tự động xuất hiện ở đây',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textFadedOf(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ResponsiveContainer(
      maxWidth: 800,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final movie = history[index].movie;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovieDetailPage(movie: movie),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardOf(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 80,
                        child: _buildPoster(context, movie.poster),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            style: TextStyle(
                              color: AppColors.textOf(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${movie.genre} • ${movie.duration}',
                            style: TextStyle(
                              color: AppColors.textFadedOf(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textFadedOf(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPoster(BuildContext context, String posterPath) {
    Widget fallback() => Container(
      color: AppColors.surfaceOf(context),
      child: Icon(Icons.movie, color: AppColors.textFadedOf(context)),
    );

    if (posterPath.isEmpty) return fallback();

    if (posterPath.startsWith('http')) {
      return Image.network(
        posterPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback(),
      );
    }

    return Image.asset(
      posterPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback(),
    );
  }
}
