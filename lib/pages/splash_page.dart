import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'login_page.dart';
import '../routes/app_router.dart';

// ============================================================
// KHÁI NIỆM: STATEFULWIDGET + VÒNG ĐỜI (LIFECYCLE)
// SplashPage cần chạy một hành động MỘT LẦN khi màn hình vừa
// xuất hiện (đợi 2 giây rồi tự chuyển màn) — việc này phải đặt
// trong initState(), và initState() CHỈ tồn tại ở StatefulWidget,
// không có ở StatelessWidget.
// ============================================================
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // initState chạy đúng 1 lần khi widget được tạo ra.
    Future.delayed(const Duration(seconds: 2), () {
      // "mounted" kiểm tra widget còn tồn tại trên cây widget hay
      // không trước khi điều hướng, tránh lỗi nếu người dùng đã
      // thoát màn hình trước khi 2 giây trôi qua.
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      // Center + Column: gom logo, tên app, vòng xoay loading và
      // canh chúng ra giữa màn hình theo chiều dọc.
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_fill,
              size: 84,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'CineStream',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textOf(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Xem phim mọi lúc, mọi nơi',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textFadedOf(context),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
