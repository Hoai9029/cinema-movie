import 'package:equatable/equatable.dart';

import '../../core/constants/app_avatars.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.name = '',
    this.phone = '',
    this.email = '',
    this.avatarId = AppAvatars.defaultId,
    this.errorMessage,
  });

  final ProfileStatus status;
  final String name;
  final String phone;
  final String email;
  final int avatarId;
  final String? errorMessage;

  ProfileState copyWith({
    ProfileStatus? status,
    String? name,
    String? phone,
    String? email,
    int? avatarId,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarId: avatarId ?? this.avatarId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    name,
    phone,
    email,
    avatarId,
    errorMessage,
  ];
}
