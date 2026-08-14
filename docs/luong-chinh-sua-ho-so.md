# Luồng chỉnh sửa avatar + tên hồ sơ (ProfileBloc)

## Vấn đề cần giải quyết

Avatar hiển thị ở 2 nơi khác nhau trong cây widget: header AppBar (`home_page.dart`) và trang Hồ sơ (`profile_page.dart`). Nếu mỗi trang tự đọc Firestore riêng, đổi avatar ở trang Hồ sơ sẽ không tự cập nhật header. Giải pháp: dùng **1 Bloc duy nhất** (`ProfileBloc`) làm nguồn dữ liệu chung, mọi nơi cần hiển thị avatar/tên đều `watch` đúng 1 instance này.

## Các thành phần

| File | Vai trò |
|---|---|
| `lib/core/constants/app_avatars.dart` | Danh sách 3 avatar cố định (`avatar.png`, `avatar1.png`, `avatar2.png`). Firestore chỉ lưu `avatarId` (0/1/2), không lưu ảnh. |
| `lib/bloc/profile/profile_state.dart` | State: `status`, `name`, `phone`, `email`, `avatarId`, `errorMessage`. |
| `lib/bloc/profile/profile_event.dart` | 2 event: `ProfileStarted` (nạp hồ sơ), `ProfileUpdateRequested` (lưu tên + avatar mới). |
| `lib/bloc/profile/profile_bloc.dart` | Xử lý 2 event trên, gọi `FirebaseAuthRepository`. |
| `lib/data/auth/firebase_auth_repository.dart` | `getUserProfile(uid)` đọc Firestore, `updateProfile(uid, name, avatarId)` ghi Firestore + `updateDisplayName`. |
| `lib/pages/edit_profile_page.dart` | Màn hình chỉnh sửa: bottom sheet chọn avatar + ô nhập tên + nút Lưu. |
| `lib/pages/profile_page.dart` | Hiển thị avatar/tên/SĐT/email từ `ProfileBloc`, có nút "Chỉnh sửa hồ sơ". |
| `lib/pages/home_page.dart` | Avatar ở AppBar cũng đọc từ `ProfileBloc`. |
| `lib/main.dart` | `BlocProvider(create: (_) => ProfileBloc())` đặt ở gốc app, cùng cấp với `ThemeBloc`, `WatchlistBloc`. |

## Luồng chạy từng bước

### 1. Nạp hồ sơ khi vào Home

```
HomePage.initState()
   → context.read<ProfileBloc>().add(ProfileStarted())
        → ProfileBloc._onStarted:
             emit(loading)
             data = await repository.getUserProfile(uid)
             emit(loaded, name, phone, email, avatarId)
```

Chỉ gọi **một lần** trong `initState()` (không phải `build()`), vì `HomePage` chỉ được tạo 1 lần trong suốt phiên đăng nhập (nhờ `IndexedStack` giữ nguyên 4 tab).

### 2. Header và ProfilePage cùng hiển thị theo state đó

```
home_page.dart   → BlocBuilder<ProfileBloc, ProfileState>  → CircleAvatar(AppAvatars.pathOf(state.avatarId))
profile_page.dart → context.watch<ProfileBloc>().state      → hiện name/phone/email/avatar
```

Cả hai không tự gọi Firestore — chỉ đọc lại state đã có sẵn trong `ProfileBloc`.

### 3. Người dùng bấm "Chỉnh sửa hồ sơ"

```
ProfilePage → Navigator.push → EditProfilePage
```

`EditProfilePage.initState()` đọc `context.read<ProfileBloc>().state` (đọc 1 lần, không watch) để:
- prefill `TextEditingController` với tên hiện tại,
- prefill `_selectedAvatarId` với avatar hiện tại.

Đây là **bản nháp cục bộ** của riêng trang này — chưa động vào `ProfileBloc`/Firestore cho tới khi bấm Lưu.

### 4. Chọn avatar

Bấm icon bút chì trên avatar → `showModalBottomSheet` liệt kê `AppAvatars.all` → chọn 1 cái → chỉ `setState(() => _selectedAvatarId = index)` trong `EditProfilePage`, đóng bottom sheet. Vẫn chưa ghi Firestore.

### 5. Bấm "Lưu"

```
_handleSave()
   → validate tên không rỗng
   → context.read<ProfileBloc>().add(
       ProfileUpdateRequested(name: ..., avatarId: _selectedAvatarId)
     )

ProfileBloc._onUpdateRequested:
   emit(loading)
   await repository.updateProfile(uid, name, avatarId)
        → Firestore: users/{uid}.update({name, avatarId})   // .update(), không .set() → không đè mất phone/email
        → FirebaseAuth: currentUser.updateDisplayName(name)
   emit(loaded, name mới, avatarId mới)
```

### 6. Kết quả tự động lan tới mọi nơi đang watch

```
EditProfilePage → BlocListener<ProfileBloc, ProfileState>
   status == loaded → Navigator.pop()          // đóng trang, không cần trả dữ liệu qua pop()
   status == error  → hiện SnackBar, ở lại trang
```

Ngay khi `ProfileBloc` emit state mới, **home_page.dart** (header) và **profile_page.dart** đều tự rebuild vì cả hai đang `watch`/`BlocBuilder` cùng instance — không cần gọi lại Firestore, không cần truyền dữ liệu qua `Navigator.pop(result)`.

## Sơ đồ tổng thể

```
                          ┌─────────────────────────┐
                          │       ProfileBloc        │  ← 1 instance duy nhất
                          │  (state: name, phone,    │    (tạo ở main.dart)
                          │   email, avatarId)        │
                          └────────────┬─────────────┘
                     watch             │             watch
              ┌──────────────┐         │        ┌──────────────────┐
              │  home_page   │◄────────┴───────►│   profile_page    │
              │ (AppBar)     │                   │ (avatar/tên/SĐT)  │
              └──────────────┘                   └─────────┬─────────┘
                                                             │ push
                                                             ▼
                                                  ┌──────────────────────┐
                                                  │   edit_profile_page   │
                                                  │  chọn avatar + sửa tên │
                                                  │  → add(ProfileUpdateRequested)
                                                  └──────────────────────┘
```

## Điểm nên nhớ khi tự viết thêm field khác (vd. ngày sinh, giới tính)

- Thêm field vào `ProfileState` + `ProfileState.copyWith`.
- Thêm field vào `ProfileUpdateRequested` và vào map truyền cho `repository.updateProfile`.
- Không cần đổi header/ProfilePage nếu field đó không hiển thị ở đó — chỉ `EditProfilePage` cần thêm ô nhập.
