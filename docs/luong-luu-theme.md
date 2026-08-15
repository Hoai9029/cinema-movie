# Luồng "Lưu trạng thái Theme" (sáng/tối)

## Vấn đề cần giải quyết

Trước đây `ThemeBloc` chỉ giữ `isDark` trong RAM, luôn khởi tạo `false`. Mỗi lần thoát hẳn app rồi mở lại (kể cả đăng xuất/đăng nhập lại) theme luôn quay về sáng, mất lựa chọn của người dùng.

Giải pháp: lưu `isDark` xuống Hive **theo toàn thiết bị** (1 giá trị dùng chung cho mọi tài khoản), khác với `WatchlistBloc`/`HistoryBloc` vốn lưu riêng theo từng `uid`. Lý do chọn phạm vi thiết bị: nút "Chế độ tối" trong hồ sơ vốn không gắn với tài khoản nào (không có UI chọn "theme của riêng tôi"), nên không cần phức tạp hoá bằng cách nghe `authStateChanges()` như hai bloc kia.

## Các thành phần

| File | Vai trò |
|---|---|
| `lib/bloc/theme/theme_event.dart` | `ThemeToggled(bool isDark)` — không đổi. |
| `lib/bloc/theme/theme_state.dart` | `ThemeState.isDark` — không đổi. |
| `lib/bloc/theme/theme_bloc.dart` | Nhận `Box? settingsBox` qua constructor, đọc key `isDarkMode` làm state khởi tạo, ghi lại mỗi khi `ThemeToggled`. |
| `lib/main.dart` | Mở Hive box `'settings'` ngay sau `Hive.initFlutter()`, truyền vào `ThemeBloc(settingsBox: settingsBox)`. |
| `lib/pages/profile_page.dart` | `Switch` "Chế độ tối" — nơi duy nhất bắn `ThemeToggled` (không đổi so với trước). |

## Luồng chạy từng bước

### 1. Khởi tạo & nạp theme đã lưu khi mở app

```
main():
   → WidgetsFlutterBinding.ensureInitialized()
   → Hive.initFlutter()
   → settingsBox = await Hive.openBox('settings')   // mở TRƯỚC runApp, có await
   → runApp(MultiBlocProvider(
        providers: [..., BlocProvider(create: (_) => ThemeBloc(settingsBox: settingsBox)), ...],
     ))

ThemeBloc.constructor(settingsBox):
   → _settingsBox = settingsBox
   → super(ThemeState(
        isDark: settingsBox?.get('isDarkMode', defaultValue: false) ?? false
     ))
   → đăng ký on<ThemeToggled>
```

Vì `settingsBox` được mở bằng `await` trước `runApp()`, `ThemeBloc` đã có sẵn giá trị đã lưu ngay tại state khởi tạo — `MaterialApp` (`lib/main.dart` → `MyApp.build`) build đúng theme (`AppTheme.dark`/`AppTheme.light`) ngay từ frame đầu tiên, không bị nháy sáng rồi mới chuyển tối.

### 2. Người dùng bật/tắt "Chế độ tối"

```
ProfilePage → Switch "Chế độ tối"
   → onChanged(value) → context.read<ThemeBloc>().add(ThemeToggled(value))

ThemeBloc.on<ThemeToggled>(event, emit):
   → emit(ThemeState(isDark: event.isDark))          // UI đổi theme ngay
   → _settingsBox?.put('isDarkMode', event.isDark)    // ghi Hive nền, không await
```

`MyApp` dùng `context.watch<ThemeBloc>()` nên toàn bộ `MaterialApp` rebuild với `theme` mới ngay khi `emit`. `box.put` không `await` — cùng nguyên tắc với `WatchlistBloc._onToggled`/`HistoryBloc._persist`: ghi đĩa chạy nền, không cần chặn UI.

### 3. Mở lại app sau khi đã tắt hẳn (hoặc đăng xuất/đăng nhập lại)

Vì box `'settings'` không đóng theo phiên đăng nhập (khác `history_<uid>`/`favorites_<uid>`) và không phụ thuộc `authStateChanges()`, giá trị `isDarkMode` vẫn còn nguyên trên đĩa bất kể tài khoản nào đăng nhập. Lần mở app kế tiếp lặp lại đúng bước 1 → theme được khôi phục.

## Sơ đồ tổng thể

```
        main()
          │  await Hive.openBox('settings')
          ▼
   settingsBox.get('isDarkMode') ──────► ThemeBloc (state khởi tạo)
                                              │
                                              ▼
                                   MyApp: theme = isDark ? dark : light
                                              ▲
                                              │ context.watch<ThemeBloc>()
                                              │
   profile_page.dart: Switch "Chế độ tối"     │
          │ onChanged(value)                   │
          ▼                                     │
   add(ThemeToggled(value)) ──► ThemeBloc.emit ─┘
          │
          ▼
   settingsBox.put('isDarkMode', value)   // ghi nền, tồn tại độc lập với đăng nhập/đăng xuất
```

## Điểm nên nhớ

- Khác với `WatchlistBloc`/`HistoryBloc`, `ThemeBloc` **không** nghe `authStateChanges()` và **không** đóng/mở lại box khi đổi tài khoản — theme là cài đặt của thiết bị, không phải của từng người dùng.
- Nếu sau này cần theme riêng theo từng tài khoản (vd. mỗi người dùng chung máy muốn theme khác nhau), phải đổi sang mô hình box `settings_<uid>` và nghe `authStateChanges()` như hai bloc kia — đây là thay đổi có chủ đích, không nên làm ngầm.
- `settingsBox` được mở bằng `await` trong `main()` trước `runApp()` — nếu sau này thêm cài đặt khác (vd. ngôn ngữ), có thể tái sử dụng cùng box `'settings'` với key riêng, không cần mở box mới.
