import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/movie.dart';

class WatchPage extends StatefulWidget {
  final Movie movie;
  const WatchPage({super.key, required this.movie});

  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  static const int _totalSeconds = 120;

  Timer? _timer;
  int _positionSeconds = 0;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) return;
      if (_positionSeconds >= _totalSeconds) {
        timer.cancel();
        _showFinishedMessage();
        return;
      }
      setState(() => _positionSeconds++);
    });
  }

  void _togglePlayPause() {
    setState(() => _isPlaying = !_isPlaying);
  }

  void _seekTo(double seconds) {
    setState(() => _positionSeconds = seconds.round());
  }

  void _showFinishedMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bạn đã xem xong phim! 🎬')));
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  color: Colors.black,
                  child: Opacity(
                    opacity: 0.5,
                    child: _buildPoster(widget.movie.poster),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: IconButton(
                iconSize: 64,
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white70,
                ),
                onPressed: _togglePlayPause,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  Text(
                    _formatTime(_positionSeconds),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Expanded(
                    child: Slider(
                      value: _positionSeconds.toDouble(),
                      min: 0,
                      max: _totalSeconds.toDouble(),
                      activeColor: AppColors.primary,
                      inactiveColor: Colors.white24,
                      onChanged: _seekTo,
                    ),
                  ),
                  Text(
                    _formatTime(_totalSeconds),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster(String posterPath) {
    if (posterPath.startsWith('http')) {
      return Image.network(
        posterPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox.expand(),
      );
    }

    if (posterPath.isNotEmpty) {
      return Image.asset(
        posterPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox.expand(),
      );
    }

    return const SizedBox.expand();
  }
}
