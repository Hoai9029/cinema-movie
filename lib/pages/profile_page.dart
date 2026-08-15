import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/profile/profile_bloc.dart';
import '../bloc/theme/theme_bloc.dart';
import '../bloc/theme/theme_event.dart';
import '../core/constants/app_avatars.dart';
import '../core/theme/app_colors.dart';
import '../data/auth/firebase_auth_repository.dart';
import '../routes/app_router.dart';
import '../widgets/responsive_container.dart';
import 'edit_profile_page.dart';
import 'watch_history_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuthRepository().signOut();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeBloc>().state;
    final profileState = context.watch<ProfileBloc>().state;

    return ResponsiveContainer(
      maxWidth: 700,
      child: Material(
        color: Colors.transparent,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Column: avatar + tên + SĐT + email + nút chỉnh sửa, canh
            // giữa theo chiều dọc. profileState đến từ ProfileBloc dùng
            // chung với header ở HomePage, nên đổi avatar/tên ở
            // EditProfilePage sẽ tự phản ánh ở cả hai nơi.
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary,
                    backgroundImage: AssetImage(
                      AppAvatars.pathOf(profileState.avatarId),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profileState.name.isEmpty
                        ? 'Người dùng'
                        : profileState.name,
                    style: TextStyle(
                      color: AppColors.textOf(context),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profileState.email,
                    style: TextStyle(
                      color: AppColors.textFadedOf(context),
                      fontSize: 14,
                    ),
                  ),
                  if (profileState.phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      profileState.phone,
                      style: TextStyle(
                        color: AppColors.textFadedOf(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Chỉnh sửa hồ sơ'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardOf(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chế độ tối',
                    style: TextStyle(
                      color: AppColors.textOf(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: themeState.isDark,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) =>
                        context.read<ThemeBloc>().add(ThemeToggled(value)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Material(
              color: AppColors.cardOf(context),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WatchHistoryPage(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: AppColors.textOf(context)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Lịch sử xem',
                          style: TextStyle(
                            color: AppColors.textOf(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textFadedOf(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout, color: AppColors.primary),
                label: const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
