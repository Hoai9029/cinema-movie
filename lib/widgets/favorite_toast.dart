import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/watchlist/watchlist_bloc.dart';
import '../bloc/watchlist/watchlist_state.dart';

// Bọc quanh nội dung của MỖI trang có nút tim (Movie Detail, Favorites
// page): mỗi khi WatchlistBloc phát ra 1 lượt bấm tim mới
// (state.lastToggle đổi), hiện SnackBar tương ứng.
//
// Cố ý KHÔNG đặt ở gốc app (MyApp) dù dùng chung được 1 chỗ: BlocListener
// đọc WatchlistBloc ngay trong initState() của nó, nên nếu đặt ở gốc,
// WatchlistBloc (và authStateChanges() bên trong) sẽ bị khởi tạo NGAY
// khi app mở — kể cả khi người dùng còn đang ở màn Splash/Login, chưa
// cần đến favorites. Đặt tại từng trang giữ đúng hành vi "khởi tạo khi
// cần" như WatchlistState (ChangeNotifier) trước đây.
//
// Cần có Scaffold tổ tiên (trang gọi widget này đã có, hoặc HomePage
// bọc ngoài với FavoritesPage) để ScaffoldMessenger.of(context) tìm
// được nơi hiện SnackBar.
class FavoriteToastListener extends StatelessWidget {
  const FavoriteToastListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<WatchlistBloc, WatchlistState>(
      listenWhen: (previous, current) =>
          previous.lastToggle != current.lastToggle,
      listener: (context, state) {
        final toggle = state.lastToggle;
        if (toggle == null) return;

        final messenger = ScaffoldMessenger.of(context);
        // Ẩn toast cũ trước khi hiện toast mới, để 2 lần bấm cách nhau
        // (nhưng ngoài cửa sổ debounce) không bị xếp hàng chờ hiện
        // lần lượt.
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              toggle.isFavorite
                  ? 'Đã thêm vào yêu thích'
                  : 'Đã xoá khỏi yêu thích',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: child,
    );
  }
}
