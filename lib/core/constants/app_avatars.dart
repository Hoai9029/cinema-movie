// Nguồn duy nhất khai báo các avatar mặc định có sẵn trong app.
// Firestore chỉ lưu avatarId (index trong danh sách này), không lưu
// ảnh — mọi nơi hiển thị avatar (header, ProfilePage, EditProfilePage)
// đều tra cứu qua đây để tránh lệch đường dẫn asset giữa các màn hình.
class AppAvatars {
  static const List<String> all = [
    'assets/images/avatar.png',
    'assets/images/avatar1.png',
    'assets/images/avatar2.png',
  ];

  static const int defaultId = 0;

  static String pathOf(int avatarId) {
    if (avatarId < 0 || avatarId >= all.length) return all[defaultId];
    return all[avatarId];
  }
}
