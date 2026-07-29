import 'package:flutter/material.dart';

// ============================================================
// State dùng chung cho toàn app (thay cho BookingState của bản
// đặt vé cũ). Đây KHÔNG có trong danh sách khái niệm bắt buộc,
// nhưng vẫn giữ lại vì nó là ví dụ tốt cho việc chia sẻ dữ liệu
// giữa nhiều StatefulWidget khác nhau (Trang chủ, Chi tiết phim,
// Yêu thích) mà không cần truyền tay qua từng màn.
//
// ChangeNotifier: khi có thay đổi, gọi notifyListeners() để mọi
// widget đang "lắng nghe" (context.watch) tự vẽ lại.
// ============================================================
class WatchlistState extends ChangeNotifier {
  final Set<String> _favoriteIds = {};

  bool isFavorite(String movieId) => _favoriteIds.contains(movieId);

  List<String> get favoriteIds => _favoriteIds.toList();

  void toggleFavorite(String movieId) {
    if (_favoriteIds.contains(movieId)) {
      _favoriteIds.remove(movieId);
    } else {
      _favoriteIds.add(movieId);
    }
    notifyListeners();
  }
}
