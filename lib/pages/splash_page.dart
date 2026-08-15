import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../core/theme/app_colors.dart';
import '../routes/app_router.dart';

// ============================================================
// KHÁI NIỆM: STATEFULWIDGET + VÒNG ĐỜI (LIFECYCLE)
// SplashPage cần chạy một hành động MỘT LẦN khi màn hình vừa
// xuất hiện (kiểm tra phiên đăng nhập đã lưu) — việc này phải
// đặt trong initState(), và initState() CHỈ tồn tại ở
// StatefulWidget, không có ở StatelessWidget.
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
    context.read<AuthBloc>().add(const AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else if (state is AuthUnauthenticated) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        // Center + Column: gom logo, tên app, vòng xoay loading và
        // canh chúng ra giữa màn hình theo chiều dọc trong lúc chờ
        // AuthBloc xác định trạng thái đăng nhập.
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
      ),
    );
  }
}
