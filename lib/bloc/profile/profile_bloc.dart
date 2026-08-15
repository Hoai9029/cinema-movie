import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth/firebase_auth_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

// Nguồn dữ liệu hồ sơ (tên/SĐT/avatar) DUY NHẤT cho toàn app. Header
// (HomePage AppBar) và ProfilePage đều watch cùng một instance này,
// nên khi EditProfilePage lưu thay đổi, cả hai nơi tự rebuild theo —
// không cần Navigator.pop(result) hay gọi lại Firestore ở nơi khác.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({FirebaseAuthRepository? repository})
    : _repository = repository ?? FirebaseAuthRepository(),
      super(const ProfileState()) {
    on<ProfileStarted>(_onStarted);
    on<ProfileUpdateRequested>(_onUpdateRequested);
  }

  final FirebaseAuthRepository _repository;

  Future<void> _onStarted(
    ProfileStarted event,
    Emitter<ProfileState> emit,
  ) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final data = await _repository.getUserProfile(user.uid);
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          name: data?['name'] as String? ?? user.displayName ?? 'Người dùng',
          phone: data?['phone'] as String? ?? '',
          email: user.email ?? '',
          avatarId: data?['avatarId'] as int? ?? 0,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Không tải được hồ sơ: $error',
        ),
      );
    }
  }

  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final previous = state;
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      await _repository.updateProfile(
        user.uid,
        name: event.name,
        avatarId: event.avatarId,
      );
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          name: event.name,
          avatarId: event.avatarId,
        ),
      );
    } catch (error) {
      // Giữ nguyên dữ liệu cũ khi lưu thất bại, chỉ báo lỗi — tránh
      // UI hiển thị sai vì state rơi về rỗng.
      emit(
        previous.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Lưu hồ sơ thất bại: $error',
        ),
      );
    }
  }
}
