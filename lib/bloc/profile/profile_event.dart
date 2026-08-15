import 'package:equatable/equatable.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

// Nạp hồ sơ người dùng đang đăng nhập từ Firestore. Gọi một lần khi
// vào HomePage, không gọi lại mỗi lần build.
class ProfileStarted extends ProfileEvent {
  const ProfileStarted();
}

// Người dùng lưu thay đổi tên/avatar ở EditProfilePage.
class ProfileUpdateRequested extends ProfileEvent {
  const ProfileUpdateRequested({required this.name, required this.avatarId});

  final String name;
  final int avatarId;

  @override
  List<Object?> get props => [name, avatarId];
}
