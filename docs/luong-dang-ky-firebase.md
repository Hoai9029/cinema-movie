# Luồng đăng ký lưu Tên + SĐT vào Firebase

## Bước 1 — Người dùng bấm "Tạo tài khoản" trong `login_page.dart`

Form có `_formKey.currentState!.validate()` chạy tất cả validator (`_validateName`, `_validatePhone`, `_validateEmail`, `_validatePassword`). Nếu một ô sai, dừng lại, không gọi Firebase. Đây là nguyên tắc: **luôn validate ở client trước khi tốn 1 lượt gọi mạng**.

## Bước 2 — Gọi `FirebaseAuthRepository().registerWithEmailAndPassword(...)`

Đây là "repository pattern" — UI (`login_page.dart`) không gọi thẳng `firebase_auth`/`cloud_firestore`, mà gọi qua một lớp trung gian (`firebase_auth_repository.dart`). Lý do: sau này nếu đổi backend (vd. sang Supabase) chỉ cần sửa 1 file, UI không đổi gì.

## Bước 3 — Bên trong repository, có 2 việc tuần tự

(không song song, vì việc 2 cần kết quả của việc 1):

```
a) _firebaseAuth.createUserWithEmailAndPassword(email, password)
   → Firebase Auth tạo tài khoản, trả về "credential.user"
   → user.uid được sinh ra (một chuỗi id duy nhất, không đổi)

b) _firestore.collection('users').doc(user.uid).set({name, phone, email, createdAt})
   → tạo 1 "document" trong Firestore, path: users/<uid>
   → dùng CHÍNH uid làm document id → sau này biết uid là tra được đúng hồ sơ
```

Đây là điểm mấu chốt: **Auth và Firestore là 2 hệ thống tách biệt, được nối với nhau bằng `uid`**. Auth chỉ lo "ai đăng nhập được", Firestore lo "thông tin của người đó là gì".

## Bước 4 — Đăng nhập thành công → điều hướng sang Home

`Navigator.pushReplacementNamed(context, AppRoutes.home)`. Từ giờ, `FirebaseAuth.instance.currentUser` ở bất kỳ đâu trong app đều trả về user vừa tạo (Firebase tự lưu session).

## Bước 5 — Vào `profile_page.dart`, hiển thị thông tin thật

```
initState():
  uid = FirebaseAuth.instance.currentUser?.uid   // lấy uid đang đăng nhập
  _profileFuture = _repository.getUserProfile(uid)  // gọi 1 lần, không phải mỗi build

build():
  FutureBuilder<Map<String, dynamic>?>(
    future: _profileFuture,
    builder: (context, snapshot) { ... dùng snapshot.data ... }
  )
```

**Tại sao dùng `FutureBuilder` thay vì gọi trực tiếp trong `build()`:** đọc Firestore là bất đồng bộ (mất thời gian, qua mạng), không thể `await` ngay trong `build()`. `FutureBuilder` tự chạy lại UI khi Future hoàn tất — trước đó `snapshot.data` là `null` nên code có fallback: `profile?['name'] ?? currentUser?.displayName ?? 'Người dùng'`.

**Tại sao gọi `_repository.getUserProfile(uid)` trong `initState()` chứ không phải trong `build()`:** `build()` có thể chạy lại nhiều lần (đổi theme, rebuild...) — nếu gọi Firestore trong đó sẽ gửi request lặp lại vô ích. `initState()` chỉ chạy đúng 1 lần khi widget được tạo.

## Sơ đồ tổng thể

```
[Form đăng ký]
      │ validate() OK
      ▼
[FirebaseAuthRepository.registerWithEmailAndPassword]
      │
      ├─► Firebase Auth ──► sinh ra uid ──► lưu session (currentUser)
      │
      └─► Firestore: users/{uid} ──► lưu {name, phone, email}

[ProfilePage] ──uid từ currentUser──► Firestore.users/{uid} ──► FutureBuilder ──► hiển thị tên/SĐT thật
```

## Điểm nên nhớ khi tự viết lại cho tính năng khác (vd. cập nhật hồ sơ)

- Muốn sửa thông tin → gọi `.set(..., SetOptions(merge: true))` hoặc `.update()` trên đúng `users/{uid}`, không tạo doc mới.
- Muốn nghe thay đổi real-time (vd. tên đổi ở thiết bị khác cũng cập nhật ngay) → đổi `getUserProfile` (Future, gọi 1 lần) thành `Stream` bằng `.snapshots()`, và đổi `FutureBuilder` thành `StreamBuilder`.
