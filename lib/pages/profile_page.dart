import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../data/auth/firebase_auth_repository.dart';
import '../data/theme_mode_state.dart';
import '../routes/app_router.dart';
import '../widgets/responsive_container.dart';

// ============================================================
// StatelessWidget: trang hồ sơ chỉ hiển thị dữ liệu tĩnh (thông
// tin cá nhân giả, lịch sử xem giả) nên không cần state riêng.
// ============================================================
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
    final themeState = context.watch<ThemeModeState>();

    return ResponsiveContainer(
      maxWidth: 700,
      child: Material(
        color: Colors.transparent,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Column: avatar + tên + email canh giữa theo chiều dọc.
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nguyễn Văn A',
                    style: TextStyle(
                      color: AppColors.textOf(context),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'nguyenvana@email.com',
                    style: TextStyle(
                      color: AppColors.textFadedOf(context),
                      fontSize: 14,
                    ),
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
                    onChanged: (value) => themeState.toggleTheme(value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Đã xem gần đây',
              style: TextStyle(
                color: AppColors.textOf(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const _WatchHistoryItem(
              title: 'Dune: Part Two',
              subtitle: 'Đã xem 45 phút',
              progress: 0.6,
            ),
            const SizedBox(height: 12),
            const _WatchHistoryItem(
              title: 'Oppenheimer',
              subtitle: 'Đã xem xong',
              progress: 1.0,
            ),
            const SizedBox(height: 12),
            const _WatchHistoryItem(
              title: 'Wonka',
              subtitle: 'Đã xem 20 phút',
              progress: 0.25,
            ),

            const SizedBox(height: 28),

            // ----------------------------------------------------
            // Bảng tổng hợp các khái niệm Flutter đã áp dụng trong
            // app này — để người xem/giảng viên dễ đối chiếu lý
            // thuyết đã học với phần thực hành trong code.
            // ----------------------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardOf(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kiến thức Flutterr ',
                    style: TextStyle(
                      color: AppColors.textOf(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ' README.md để biết vị trí ',
                    style: TextStyle(
                      color: AppColors.textFadedOf(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const _ConceptCheck('--'),
                ],
              ),
            ),
            const SizedBox(height: 28),

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

// Một dòng trong bảng lịch sử xem, có thanh tiến trình xem dở.
class _WatchHistoryItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress; // 0.0 - 1.0

  const _WatchHistoryItem({
    required this.title,
    required this.subtitle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardOf(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.movie_creation_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textOf(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textFadedOf(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: AppColors.surfaceOf(context),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Một dòng check-list nhỏ, dùng Row: icon check + chữ mô tả.
class _ConceptCheck extends StatelessWidget {
  final String label;
  const _ConceptCheck(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.textOf(context), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
