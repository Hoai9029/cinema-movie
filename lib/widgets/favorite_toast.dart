import 'package:flutter/material.dart';

import '../data/watchlist_state.dart';
import '../models/movie.dart';

// Dùng chung cho mọi nút trái tim trong app (chi tiết phim, trang Yêu
// thích, ...): bấm tim -> đổi trạng thái yêu thích -> báo bằng SnackBar.
// Tách thành hàm riêng để 2 nơi gọi không copy lại cùng một đoạn hiện
// SnackBar, và để hành vi (nội dung toast, thời lượng) đồng nhất.
void handleFavoriteToggle(
  BuildContext context,
  WatchlistState watchlist,
  Movie movie,
) {
  // toggleFavorite trả về null khi lần bấm này bị debounce (đến quá
  // nhanh sau lần bấm trước) — bỏ qua, không hiện toast.
  final isNowFavorite = watchlist.toggleFavorite(movie);
  if (isNowFavorite == null) return;

  final messenger = ScaffoldMessenger.of(context);
  // Ẩn toast cũ trước khi hiện toast mới, để 2 lần bấm cách nhau
  // (nhưng ngoài cửa sổ debounce) không bị xếp hàng chờ hiện lần lượt.
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        isNowFavorite ? 'Đã thêm vào yêu thích' : 'Đã xoá khỏi yêu thích',
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}
