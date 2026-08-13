import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/theme_mode_state.dart';
import 'data/watchlist_state.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';

// Điểm bắt đầu của ứng dụng Flutter.
// ChangeNotifierProvider tạo WatchlistState MỘT LẦN ở gốc cây
// widget, để mọi màn hình con (Trang chủ, Chi tiết phim, Yêu
// thích...) đều đọc/ghi được cùng một dữ liệu yêu thích.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    debugPrint('Firebase initialization skipped: $error');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WatchlistState()),
        ChangeNotifierProvider(create: (_) => ThemeModeState()),
      ],
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
    final themeState = context.watch<ThemeModeState>();

    return MaterialApp(
      title: 'CineStream',
      debugShowCheckedModeBanner: false,
      theme: themeState.isDark ? AppTheme.dark : AppTheme.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
