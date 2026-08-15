import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';

// Kiểm tra phiên đăng nhập lúc mở app. Firebase Auth SDK đã tự lưu
// phiên đăng nhập an toàn trên máy (Keystore/Keychain) và tự refresh
// token ngầm, nên không cần app tự quản lý/lưu token riêng — chỉ cần
// hỏi lại Firebase là biết còn đăng nhập hay không.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({firebase_auth.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
      super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
  }

  final firebase_auth.FirebaseAuth _firebaseAuth;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // .first đợi Firebase khôi phục xong phiên đã lưu trước đó (nếu
    // có) rồi mới phát giá trị — đọc currentUser ngay lập tức có thể
    // chưa kịp khôi phục xong, nhất là ngay lúc app vừa khởi động.
    final user = await _firebaseAuth.authStateChanges().first;
    emit(
      user != null ? AuthAuthenticated(user) : const AuthUnauthenticated(),
    );
  }
}
