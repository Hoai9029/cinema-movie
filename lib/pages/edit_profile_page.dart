import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/profile/profile_bloc.dart';
import '../bloc/profile/profile_event.dart';
import '../bloc/profile/profile_state.dart';
import '../core/constants/app_avatars.dart';
import '../core/theme/app_colors.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nameController;
  late int _selectedAvatarId;

  @override
  void initState() {
    super.initState();
    // Đọc state HIỆN TẠI của ProfileBloc một lần để prefill form —
    // không watch ở đây vì trang này tự quản lý bản nháp riêng cho
    // tới khi người dùng bấm Lưu.
    final current = context.read<ProfileBloc>().state;
    _nameController = TextEditingController(text: current.name);
    _selectedAvatarId = current.avatarId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên')));
      return;
    }
    context.read<ProfileBloc>().add(
      ProfileUpdateRequested(name: name, avatarId: _selectedAvatarId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.backgroundOf(context),
        title: const Text('Cài đặt hồ sơ'),
      ),
      // BlocListener: phản ứng với KẾT QUẢ lưu (thành công/lỗi) mà
      // không vẽ lại UI — tách biệt với BlocBuilder (vẽ UI theo state).
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.loaded) {
            Navigator.of(context).pop();
          } else if (state.status == ProfileStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Có lỗi xảy ra')),
            );
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            final isSaving = state.status == ProfileStatus.loading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: AppColors.primary,
                        backgroundImage: AssetImage(
                          AppAvatars.pathOf(_selectedAvatarId),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: isSaving ? null : _showAvatarPicker,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.textOf(context),
                            child: Icon(
                              Icons.edit,
                              size: 18,
                              color: AppColors.backgroundOf(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tên hồ sơ',
                      style: TextStyle(
                        color: AppColors.textFadedOf(context),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    enabled: !isSaving,
                    style: TextStyle(color: AppColors.textOf(context)),
                    decoration: const InputDecoration(
                      hintText: 'Nhập tên hiển thị',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _handleSave,
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chọn avatar',
                style: TextStyle(
                  color: AppColors.textOf(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(AppAvatars.all.length, (index) {
                  final isSelected = index == _selectedAvatarId;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAvatarId = index);
                      Navigator.of(sheetContext).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary,
                        backgroundImage: AssetImage(AppAvatars.all[index]),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
