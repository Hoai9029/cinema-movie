import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/movie.dart';

// ============================================================
// KHÁI NIỆM: STATEFULWIDGET + VÒNG ĐỜI (initState / dispose)
// Đây là màn hình "xem phim" thật sự — thay cho toàn bộ luồng
// chọn ghế/thanh toán của bản app đặt vé cũ. Vì phải chạy một bộ
// đếm thời gian liên tục (mô phỏng video đang phát) và người
// dùng có thể rời màn hình bất cứ lúc nào, đây là ví dụ RÕ NHẤT
// cho lý do StatefulWidget cần cả initState (bắt đầu Timer) LẪN
// dispose (dừng Timer) — quên dispose sẽ khiến Timer chạy mãi kể
// cả khi màn hình đã bị đóng, gây rò rỉ bộ nhớ.
// ============================================================
class WatchPage extends StatefulWidget {
  final Movie movie;
  const WatchPage({super.key, required this.movie});

  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  static const int _totalSeconds = 120; // "thời lượng" giả lập: 2 phút

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
    // Bắt buộc phải hủy Timer khi rời màn hình, nếu không nó vẫn
    // chạy ngầm dù người dùng đã quay lại Trang chủ.
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
      // setState: mỗi giây trôi qua, cập nhật lại thanh tiến trình.
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bạn đã xem xong phim! 🎬')),
    );
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
      // ----------------------------------------------------------
      // KHÁI NIỆM: LAYOUT — STACK
      // Toàn màn hình xem phim là MỘT Stack lớn:
      //   Lớp 1: vùng "video" (ở đây là ảnh poster làm nền tạm).
      //   Lớp 2: thanh điều khiển (back, tiêu đề) neo trên cùng.
      //   Lớp 3: nút play/pause lớn neo giữa màn hình.
      //   Lớp 4: thanh tiến trình + thời gian neo dưới cùng.
      // Nếu không có Stack, 4 lớp này sẽ phải xếp CẠNH nhau bằng
      // Column, làm mất hiệu ứng "nổi trên video" đặc trưng của
      // mọi trình phát video thực tế.
      // ----------------------------------------------------------
      body: SafeArea(
        child: Stack(
          children: [
            // Lớp 1: vùng video giả lập.
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  color: Colors.black,
                  child: Opacity(
                    opacity: 0.5,
                    child: Image.asset(
                      widget.movie.poster,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.expand();
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Lớp 2: thanh trên cùng — nút back + tên phim.
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              // Row: icon back và tên phim nằm cạnh nhau theo chiều ngang.
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  // Expanded: tên phim chiếm hết khoảng trống còn lại,
                  // tự động cắt bớt (...) nếu tên phim quá dài.
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

            // Lớp 3: nút play / pause lớn ở giữa màn hình.
            Center(
              child: IconButton(
                iconSize: 64,
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Colors.white70,
                ),
                onPressed: _togglePlayPause,
              ),
            ),

            // Lớp 4: thanh tiến trình + thời gian, neo đáy màn hình.
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
                  // Expanded: thanh Slider chiếm hết khoảng trống còn
                  // lại giữa 2 mốc thời gian.
                  Expanded(
                    child: Slider(
                      value: _positionSeconds.toDouble(),
                      min: 0,
                      max: _totalSeconds.toDouble(),
                      activeColor: AppColors.primary,
                      inactiveColor: Colors.white24,
                      onChanged: _seekTo, // kéo để tua nhanh/lùi
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
}
