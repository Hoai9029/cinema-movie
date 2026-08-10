import 'package:flutter/material.dart';

import '../models/movie.dart';

// ============================================================
// State dùng chung cho toàn app (thay cho BookingState của bản
// đặt vé cũ). Đây KHÔNG có trong danh sách khái niệm bắt buộc,
// nhưng vẫn giữ lại vì nó là ví dụ tốt cho việc chia sẻ dữ liệu
// giữa nhiều StatefulWidget khác nhau (Trang chủ, Chi tiết phim,
// Yêu thích) mà không cần truyền tay qua từng màn.
//
// ChangeNotifier: khi có thay đổi, gọi notifyListeners() để mọi
// widget đang "lắng nghe" (context.watch) tự vẽ lại.
//
// Lưu cả Movie (không chỉ id) vì dữ liệu phim đến từ TMDB — trang
// Yêu thích cần đủ thông tin (poster, tiêu đề, ...) để hiển thị mà
// không phải gọi lại API hay tra cứu trong danh sách phim mẫu.
// ============================================================
class WatchlistState extends ChangeNotifier {
  final Map<String, Movie> _favorites = {};

  // Chặn double-toggle khi người dùng bấm tim liên tiếp quá nhanh (vd
  // double-tap ngoài ý muốn) — theo dõi lần bấm gần nhất CHO TỪNG phim
  // riêng biệt, để bấm tim phim A không ảnh hưởng tới việc bấm tim
  // phim B ngay sau đó.
  final Map<String, DateTime> _lastToggleAt = {};
  static const _debounceWindow = Duration(milliseconds: 500);

  bool isFavorite(String movieId) => _favorites.containsKey(movieId);

  List<Movie> get favoriteMovies => _favorites.values.toList();

  // Trả về true nếu phim VỪA được thêm vào yêu thích, false nếu VỪA bị
  // xoá, hoặc null nếu lần bấm này bị bỏ qua vì đến quá nhanh sau lần
  // bấm trước (debounce) — UI dùng giá trị này để quyết định có hiện
  // toast hay không, tránh toast bắn liên tục khi bấm nhanh tay.
  bool? toggleFavorite(Movie movie) {
    final now = DateTime.now();
    final last = _lastToggleAt[movie.id];
    if (last != null && now.difference(last) < _debounceWindow) {
      return null;
    }
    _lastToggleAt[movie.id] = now;

    final bool isNowFavorite;
    if (_favorites.containsKey(movie.id)) {
      _favorites.remove(movie.id);
      isNowFavorite = false;
    } else {
      _favorites[movie.id] = movie;
      isNowFavorite = true;
    }
    notifyListeners();
    return isNowFavorite;
  }
}
