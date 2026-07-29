import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/watchlist_state.dart';
import 'pages/splash_page.dart';

// Điểm bắt đầu của ứng dụng Flutter.
// ChangeNotifierProvider tạo WatchlistState MỘT LẦN ở gốc cây
// widget, để mọi màn hình con (Trang chủ, Chi tiết phim, Yêu
// thích...) đều đọc/ghi được cùng một dữ liệu yêu thích.
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => WatchlistState(),
      child: const MyApp(),
    ),
  );
}

// ============================================================
// KHÁI NIỆM: WIDGET TREE + STATELESSWIDGET
// MyApp là widget GỐC của toàn bộ cây widget (widget tree). Nó
// không tự thay đổi theo thời gian (chỉ cấu hình theme + màn
// hình đầu tiên MỘT LẦN) nên là StatelessWidget. Mọi widget khác
// trong app (SplashPage, LoginPage, HomePage...) đều là "con
// cháu" được vẽ bên trong MaterialApp này.
// ============================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineStream',
      debugShowCheckedModeBanner: false,
      // THEME: áp dụng theme tối cho toàn bộ ứng dụng ngay tại gốc.
      theme: AppTheme.dark,
      // NAVIGATION: màn hình đầu tiên khi mở app.
      home: const SplashPage(),
    );
  }
}
