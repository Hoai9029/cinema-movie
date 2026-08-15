# Luồng "Ghi nhớ đăng nhập" (Persistent Login / Auto-login)

## Vấn đề cần giải quyết

Người dùng đăng nhập xong, tắt app rồi mở lại thì không phải đăng nhập lại. Trước đây `SplashPage` luôn đợi cố định 2 giây rồi **luôn** điều hướng sang `LoginPage`, bất kể người dùng đã đăng nhập từ trước hay chưa — đây là lỗi khiến app "không nhớ đăng nhập".

**Quyết định kiến trúc quan trọng:** đề xuất ban đầu là tự lưu token vào `flutter_secure_storage`. Nhưng app này xác thực hoàn toàn qua **Firebase Authentication**, không có backend riêng trả token — Firebase SDK đã tự lưu phiên đăng nhập an toàn trên máy (Android Keystore / iOS Keychain) và tự refresh token ngầm. Tự thêm một lớp lưu token thủ công song song sẽ dư thừa và có nguy cơ **desync** (token cũ vẫn còn trong storage dù Firebase đã signOut/revoke ở nơi khác). Vì vậy giải pháp là để `AuthBloc` hỏi thẳng Firebase, không tự quản lý token.

## Các thành phần

| File | Vai trò |
|---|---|
| `lib/bloc/auth/auth_event.dart` | `AuthCheckRequested` — event duy nhất, `SplashPage` bắn lúc khởi động. |
| `lib/bloc/auth/auth_state.dart` | `AuthInitial`, `AuthAuthenticated(User)`, `AuthUnauthenticated`. |
| `lib/bloc/auth/auth_bloc.dart` | Xử lý `AuthCheckRequested`: đợi `firebaseAuth.authStateChanges().first` rồi emit state tương ứng. |
| `lib/main.dart` | `BlocProvider(create: (_) => AuthBloc())` đặt trong `MultiBlocProvider` ở gốc app. |
| `lib/pages/splash_page.dart` | Bắn `AuthCheckRequested` trong `initState`, `BlocListener` điều hướng theo state. |
| `lib/pages/login_page.dart` | Không đổi — Firebase tự lưu phiên ngay khi `signInWithEmailAndPassword`/`createUserWithEmailAndPassword` thành công. |
| `lib/pages/profile_page.dart` | `_handleLogout` — đã có sẵn, gọi `signOut()` rồi `pushNamedAndRemoveUntil` xoá sạch stack. |

## Luồng chạy từng bước

### 1. Đăng nhập — không cần code thêm

```
LoginPage._handleAuth()
   → FirebaseAuthRepository().signInWithEmailAndPassword(email, password)
        → Firebase Auth xác thực, tự lưu phiên vào Keystore/Keychain
        → FirebaseAuth.instance.currentUser từ giờ luôn trả về user này,
          ở BẤT KỲ nơi nào trong app, kể cả sau khi tắt/mở lại app
   → Navigator.pushReplacementNamed(context, AppRoutes.home)
```

Không có bước "lưu token" thủ công nào — Firebase SDK làm việc này ngầm.

### 2. Mở lại app — SplashPage kiểm tra phiên đã lưu

```
main() → MultiBlocProvider → BlocProvider(create: (_) => AuthBloc())

SplashPage.initState():
   → context.read<AuthBloc>().add(const AuthCheckRequested())

AuthBloc._onCheckRequested(event):
   → user = await firebaseAuth.authStateChanges().first
        // đợi Firebase khôi phục xong phiên đã lưu (nếu có) rồi mới
        // phát giá trị đầu tiên — đọc currentUser ngay lập tức có
        // thể chưa kịp khôi phục xong lúc app vừa khởi động
   → emit(user != null ? AuthAuthenticated(user) : AuthUnauthenticated())

SplashPage.build(): BlocListener<AuthBloc, AuthState>
   → AuthAuthenticated   → Navigator.pushReplacementNamed(context, AppRoutes.home)
   → AuthUnauthenticated → Navigator.pushReplacementNamed(context, AppRoutes.login)
```

Trong lúc chờ, `SplashPage` hiển thị logo + `CircularProgressIndicator` (không có delay giả — thời gian hiển thị đúng bằng thời gian check auth thực tế, thường rất nhanh vì không cần gọi mạng, chỉ đọc phiên đã lưu local).

### 3. Đăng xuất

```
ProfilePage._handleLogout(context):
   → FirebaseAuthRepository().signOut()
        → Firebase xoá phiên đã lưu trên máy
   → Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false)
        // xoá sạch stack cũ → bấm back không quay lại được Trang chủ
```

Phần này đã có sẵn từ trước, đúng yêu cầu, không cần sửa.

## Sơ đồ tổng thể

```
[App khởi động]
      │
      ▼
 SplashPage.initState()
      │ add(AuthCheckRequested)
      ▼
   AuthBloc ──await firebaseAuth.authStateChanges().first──┐
      │                                                     │
      │ (đọc phiên đã lưu trong Keystore/Keychain,          │
      │  KHÔNG có storage token riêng của app)               │
      ▼                                                     │
 emit AuthAuthenticated(user)  hoặc  emit AuthUnauthenticated
      │                                    │
      ▼                                    ▼
 pushReplacement → HomePage        pushReplacement → LoginPage
                                            │
                                            ▼
                                    LoginPage đăng nhập thành công
                                    → Firebase tự lưu phiên mới
                                    → pushReplacement → HomePage

[Từ HomePage/ProfilePage] → bấm Đăng xuất
      → FirebaseAuthRepository().signOut() (Firebase xoá phiên đã lưu)
      → pushNamedAndRemoveUntil(LoginPage, xoá sạch stack)
```

## Điểm nên nhớ khi tự viết lại cho tính năng khác

- **Không tự lưu token khi đã có Firebase Auth** (hoặc bất kỳ SDK auth nào tự quản lý phiên) — hỏi thẳng SDK (`currentUser` / `authStateChanges()`) luôn là nguồn sự thật duy nhất, tránh 2 nơi lưu trạng thái đăng nhập bị lệch nhau.
- `authStateChanges().first` (một lần) phù hợp cho việc **check lúc khởi động** như `SplashPage`. Nếu cần cả app tự phản ứng real-time khi đăng xuất từ nơi khác (giống cách `WatchlistBloc`/`HistoryBloc` đang làm), phải **subscribe liên tục** bằng `.listen()` trong constructor thay vì chỉ đọc `.first` một lần — xem `lib/bloc/watchlist/watchlist_bloc.dart` làm ví dụ mẫu.
- Cân nhắc thêm delay tối thiểu cho `SplashPage` chỉ khi cần tránh "chớp nháy" do thời gian check không ổn định — với app này việc check chỉ đọc local nên không cần, thêm vào chỉ làm chậm cảm nhận hiệu năng không cần thiết (đúng khuyến cáo của Android Splash Screen API).
