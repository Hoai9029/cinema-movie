# Luồng tự dừng video khi điều hướng sang trang chi tiết phim khác

## Vấn đề cần giải quyết

Ở `MovieDetailPage`, mục "Phim tương tự" bấm vào 1 phim sẽ `Navigator.push` một `MovieDetailPage` **mới** đè lên trên. Vì là `push` (không phải `pushReplacement`), trang cũ **không hề bị pop** — nó vẫn nằm nguyên phía dưới trong Navigator stack, chỉ bị che khuất bởi trang mới.

Do `dispose()` của `_MovieDetailViewState` chỉ chạy khi trang thật sự bị gỡ khỏi stack, `YoutubePlayerController` (và WebView bên trong nó) của trang cũ **vẫn tiếp tục phát**, kể cả khi người dùng đã không còn nhìn thấy nó. Trailer/video của trang mới thì tự autoplay khi `MovieDetailBloc` load xong (xem [luong-xem-trailer-xem-ngay.md](luong-xem-trailer-xem-ngay.md)). Kết quả: có 2 WebView cùng phát nhạc/tiếng một lúc, cho tới khi audio focus của hệ điều hành tình cờ "giành" quyền phát cho video mới — gây cảm giác phim cũ chỉ tắt tiếng muộn màng, không chủ động.

Giải pháp: dùng `RouteObserver` + mixin `RouteAware` (cơ chế chuẩn của Flutter) để trang chi tiết phim **tự biết** lúc nào nó bị 1 trang khác che lên trên, và chủ động `pause()` video ngay lúc đó — không phụ thuộc vào audio focus của OS.

## Các thành phần

| File | Vai trò |
|---|---|
| `lib/routes/app_router.dart` | Khai báo `routeObserver` — một `RouteObserver<PageRoute>` **dùng chung** cho toàn app (biến top-level, khởi tạo 1 lần). |
| `lib/main.dart` | Đăng ký `routeObserver` vào `navigatorObservers` của `MaterialApp` — bắt buộc phải có bước này thì `RouteAware` mới nhận được sự kiện. |
| `lib/pages/movie_detail_page.dart` | `_MovieDetailViewState` mixin `RouteAware`, subscribe/unsubscribe `routeObserver`, override `didPushNext()` để pause `_playerController`. |

## Luồng chạy từng bước

### 1. Đăng ký observer dùng chung, một lần duy nhất ở gốc app

```
main.dart → MaterialApp(
    navigatorObservers: [routeObserver],   // routeObserver từ app_router.dart
  )
```

Mọi `Navigator.push`/`pop` trong toàn app đều đi qua `Navigator` gắn với `MaterialApp` này, nên `routeObserver` nhìn thấy hết mọi thay đổi route, không riêng gì `MovieDetailPage`.

### 2. Trang chi tiết phim tự đăng ký lắng nghe route của chính nó

```
_MovieDetailViewState (with RouteAware)

didChangeDependencies()
   → routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute)
        // gắn State này với đúng PageRoute đang chứa nó

dispose()
   → routeObserver.unsubscribe(this)   // gỡ đăng ký trước khi state bị huỷ
   → _playerController?.dispose()
```

`didChangeDependencies()` được chọn thay vì `initState()` vì `ModalRoute.of(context)` cần `context` đã có `InheritedWidget` (Navigator) phía trên — chưa dùng được ngay trong `initState()`.

### 3. Bấm vào phim tương tự → trang cũ nhận được `didPushNext()` → pause ngay

```
Trang A (đang phát trailer) → bấm phim tương tự
   → Navigator.push(MaterialPageRoute(builder: (_) => MovieDetailPage(movie: B)))
        // route của trang B được đẩy lên TRÊN route của trang A

routeObserver phát hiện route mới đè lên route đang subscribe của trang A
   → gọi trang A: didPushNext()
        → _playerController?.pause()   // trailer/video trang A dừng NGAY LẬP TỨC

Trang B: BlocProvider mới → MovieDetailBloc mới → gọi API
   → khi Loaded, tự _startPlayback(trailer.key) như luồng bình thường
```

Trang A không hề bị dispose (vẫn nằm dưới stack, quay lại vẫn còn), chỉ video của nó bị pause chủ động — khác với trước đây là chờ audio focus hệ điều hành tự xử lý.

### 4. Bấm back quay lại trang cũ → KHÔNG tự phát lại

`_MovieDetailViewState` **không** override `didPopNext()`, nên khi trang B bị pop và trang A lộ ra trở lại, video giữ nguyên trạng thái `pause` — người dùng phải tự bấm play nếu muốn xem tiếp. Đây là lựa chọn có chủ đích (không phải thiếu sót): tránh video tự phát tiếng bất ngờ ngay khi vừa quay lại màn hình.

## Sơ đồ tổng thể

```
MaterialApp
  navigatorObservers: [routeObserver]  ← đăng ký 1 lần ở gốc app
        │
        │  theo dõi mọi push/pop trên toàn app
        ▼
┌─────────────────────────┐   Navigator.push    ┌─────────────────────────┐
│ MovieDetailPage (phim A)  │ ───────────────────▶ │ MovieDetailPage (phim B)  │
│  _playerController: playing │                     │  _playerController: null  │
└─────────────┬─────────────┘                     └─────────────┬─────────────┘
              │ routeObserver báo:                                │ MovieDetailLoaded
              │ didPushNext()                                      │ → autoplay trailer B
              ▼                                                    ▼
      _playerController?.pause()                          _startPlayback(trailer.key)
      (phim A im lặng ngay)                                (phim B bắt đầu phát)
```

## Điểm nên nhớ

- Nếu sau này có trang khác cũng nhúng `YoutubePlayerController` tương tự (không chỉ `MovieDetailPage`), áp dụng lại đúng 3 bước ở mục "Luồng chạy" (subscribe/unsubscribe + `didPushNext()`), không cần tạo `RouteObserver` mới — dùng chung `routeObserver` đã có trong `app_router.dart`.
- Nếu muốn đổi hành vi mục 4 (tự phát lại khi quay về), chỉ cần thêm override `didPopNext()` gọi `_playerController?.play()` — không cần đổi gì khác trong luồng.
- `routeObserver.subscribe()` yêu cầu route hiện tại phải là `PageRoute` (ép kiểu `as PageRoute` ở bước 2) — nếu sau này có nơi mở `MovieDetailPage` bằng route không phải `PageRoute` (ví dụ `showDialog`/`showModalBottomSheet`), đoạn ép kiểu này sẽ throw, cần soát lại.
