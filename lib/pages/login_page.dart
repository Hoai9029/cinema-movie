import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'home_page.dart';

// ============================================================
// KHÁI NIỆM: FORMS & VALIDATION
// Đây là màn hình minh họa rõ nhất cho chủ đề này. Ba mảnh ghép
// bắt buộc phải có khi làm Form trong Flutter:
//   1. Một `GlobalKey<FormState>` để "nắm" toàn bộ form.
//   2. Một widget `Form` bọc quanh các ô nhập, gắn key vào đó.
//   3. Mỗi ô nhập dùng `TextFormField` (không phải TextField
//      thường) vì chỉ TextFormField mới có `validator`.
//
// Khi bấm nút Đăng nhập, ta gọi `_formKey.currentState!.validate()`
// -> Flutter tự chạy validator của TỪNG ô, hiện lỗi đỏ ngay dưới
// ô nếu có, và trả về false nếu BẤT KỲ ô nào sai.
//
// Vì có logic (controller, trạng thái loading) và cần dùng
// GlobalKey, màn hình này phải là StatefulWidget.
// ============================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Key để điều khiển và kiểm tra toàn bộ Form.
  final _formKey = GlobalKey<FormState>();

  // Controller đọc/ghi nội dung người dùng gõ vào ô nhập.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true; // ẩn/hiện mật khẩu
  bool _isLoading = false;

  @override
  void dispose() {
    // Luôn hủy controller khi màn hình bị đóng để tránh rò rỉ bộ nhớ.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validator cho ô Email: không được để trống + phải có dạng email.
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không đúng định dạng';
    }
    return null; // null nghĩa là hợp lệ
  }

  // Validator cho ô Mật khẩu: không trống + tối thiểu 6 ký tự.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  void _handleLogin() {
    // validate() chạy TẤT CẢ validator trong Form.
    // Nếu có lỗi, Flutter tự hiện chữ đỏ dưới từng ô sai.
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    setState(() => _isLoading = true);

    // Giả lập gọi API đăng nhập mất 1 giây.
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            // Giới hạn chiều rộng form khi chạy trên web/màn rộng,
            // để ô nhập không bị kéo dài hết màn hình.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                // autovalidateMode: kiểm tra lại NGAY khi người dùng
                // gõ tiếp, sau lần bấm Đăng nhập đầu tiên bị lỗi.
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.play_circle_fill,
                      size: 56,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Đăng nhập',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Đăng nhập để tiếp tục xem phim',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textFaded),
                    ),
                    const SizedBox(height: 32),

                    // Ô nhập Email + validator.
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.text),
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ô nhập Mật khẩu + validator + nút ẩn/hiện.
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppColors.text),
                      validator: _validatePassword,
                      decoration: InputDecoration(
                        hintText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nút Đăng nhập: disable khi đang loading để
                    // tránh người dùng bấm nhiều lần.
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Đăng nhập',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
