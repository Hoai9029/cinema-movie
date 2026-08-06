import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class MovieCard extends StatelessWidget {
  final String title;
  final String rating;
  final String? imagePath;
  final double width;

  const MovieCard({
    super.key,
    required this.title,
    required this.rating,
    this.imagePath,
    this.width = 140,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    final isNetworkImage = hasImage && imagePath!.startsWith('http');

    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 190,
              width: width,
              color: AppColors.cardOf(context),
              child: hasImage
                  ? (isNetworkImage
                        ? Image.network(
                            imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _posterFallback(context);
                            },
                          )
                        : Image.asset(
                            imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _posterFallback(context);
                            },
                          ))
                  : _posterFallback(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textOf(context),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                rating,
                style: TextStyle(color: AppColors.textFadedOf(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _posterFallback(BuildContext context) {
    return Center(
      child: Icon(Icons.movie, size: 40, color: AppColors.textFadedOf(context)),
    );
  }
}
