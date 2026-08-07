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

  bool isFavorite(String movieId) => _favorites.containsKey(movieId);

  List<Movie> get favoriteMovies => _favorites.values.toList();

  void toggleFavorite(Movie movie) {
    if (_favorites.containsKey(movie.id)) {
      _favorites.remove(movie.id);
    } else {
      _favorites[movie.id] = movie;
    }
    notifyListeners();
  }
}
