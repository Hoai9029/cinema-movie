# Luồng "Lịch sử xem" (Watch History)

## Vấn đề cần giải quyết

App cần ghi nhớ những phim người dùng đã xem trailer/xem ngay, hiển thị lại theo thứ tự **xem gần nhất lên đầu**, và cho phép xem lại hoặc xoá sạch lịch sử. Giải pháp tái sử dụng đúng kiến trúc đã có của tính năng Yêu thích (`WatchlistBloc`): một Bloc riêng, lưu xuống Hive theo từng tài khoản, provide ở gốc app để dùng chung được ở nhiều trang.

Khác với Yêu thích (không quan tâm thứ tự, mỗi phim là 1 key độc lập trong box), Lịch sử xem **bắt buộc giữ đúng thứ tự thời gian** nên toàn bộ danh sách được lưu chung dưới 1 key duy nhất trong box thay vì mỗi phim 1 key.

## Các thành phần

| File | Vai trò |
|---|---|
| `lib/bloc/history/history_event.dart` | `HistoryRecorded(Movie)`, `HistoryCleared()`, `HistoryAuthChanged(User?)` (event nội bộ). |
| `lib/bloc/history/history_state.dart` | `HistoryEntry` (movie + `watchedAt`), `HistoryState.history` (`List<HistoryEntry>`, đã đúng thứ tự gần nhất → xa nhất). |
| `lib/bloc/history/history_bloc.dart` | Xử lý logic, mở/đóng Hive box `history_<uid>` theo `authStateChanges()`, persist toàn bộ list dưới key `entries`. |
| `lib/main.dart` | `BlocProvider(create: (_) => HistoryBloc())` đặt ngang hàng với `WatchlistBloc` trong `MultiBlocProvider` ở gốc app. |
| `lib/pages/movie_detail_page.dart` | Nơi duy nhất bắn `HistoryRecorded` — trong `_startPlayback()`. |
| `lib/pages/profile_page.dart` | Thêm hàng "Lịch sử xem" (icon đồng hồ + chevron) ngay dưới "Chế độ tối". |
| `lib/pages/watch_history_page.dart` | Trang hiển thị danh sách, có nút xoá toàn bộ (có xác nhận). |

## Luồng chạy từng bước

### 1. Khởi tạo & nạp dữ liệu khi mở app / đăng nhập

```
main() → MultiBlocProvider
   → BlocProvider(create: (_) => HistoryBloc())
        HistoryBloc.constructor
           → đăng ký on<HistoryRecorded>, on<HistoryCleared>, on<HistoryAuthChanged>
           → firebaseAuth.authStateChanges().listen(user => add(HistoryAuthChanged(user)))

_onAuthChanged(event):
   → đóng box cũ (nếu có) để không lẫn dữ liệu người dùng trước
   → nếu user == null → emit HistoryState() rỗng, dừng
   → Hive.openBox('history_<uid>')
   → đọc box.get('entries') (List<Map> đã lưu trước đó)
   → map từng phần tử → HistoryEntry.fromJson
   → emit HistoryState(history: [...])
```

### 2. Ghi lịch sử khi trailer/xem ngay bắt đầu autoplay

Điểm ghi duy nhất là `_MovieDetailViewState._startPlayback(videoId)` trong `movie_detail_page.dart` — hàm này chỉ chạy khi video **thực sự bắt đầu phát** (trailer tự phát khi `MovieDetailLoaded`, hoặc khi bấm "Xem ngay" lần đầu), không chạy khi chỉ điều hướng vào trang chi tiết.

```
_startPlayback(videoId):
   → setState(() => _playerController = YoutubePlayerController(...))
   → context.read<HistoryBloc>().add(HistoryRecorded(widget.movie))

HistoryBloc._onRecorded(event):
   → history = List.from(state.history)
        ..removeWhere(entry => entry.movie.id == movie.id)   // bỏ bản ghi cũ nếu đã xem trước đó
   → history.insert(0, HistoryEntry(movie: movie, watchedAt: DateTime.now()))
   → emit(state.copyWith(history: history))
   → _persist(history)   // box.put('entries', history.map(toJson).toList())
```

Nhờ luôn xoá bản ghi cũ (nếu trùng `movie.id`) rồi chèn bản ghi mới vào **đầu** danh sách, thứ tự "gần nhất lên đầu" luôn đúng mà không cần sort lại khi đọc — kể cả khi xem lại 1 phim đã có trong lịch sử.

### 3. Vào trang Lịch sử xem từ Profile

```
ProfilePage → Row "Lịch sử xem" (icon Icons.history + chevron)
   → InkWell.onTap → Navigator.push(WatchHistoryPage())

WatchHistoryPage → _HistoryList
   → context.watch<HistoryBloc>().state.history
   → rỗng  → empty-state (icon + "Chưa có phim nào trong lịch sử xem")
   → có dữ liệu → ListView.builder: mỗi item = poster + tên phim + chevron
        onTap → Navigator.push(MovieDetailPage(movie: entry.movie))
```

Vì dùng `context.watch`, danh sách tự cập nhật ngay khi `HistoryBloc` emit state mới (ví dụ vừa xem xong 1 trailer ở trang khác rồi quay lại trang Lịch sử) — không cần load lại thủ công.

### 4. Xoá toàn bộ lịch sử

```
WatchHistoryPage → icon Icons.delete_outline (góc phải header)
   → onTap → _confirmClear(context)
        → showDialog<bool>(AlertDialog "Xoá toàn bộ lịch sử xem?")
        → bấm "Huỷ"  → Navigator.pop(false) → không làm gì
        → bấm "Xoá"  → Navigator.pop(true)
             → context.read<HistoryBloc>().add(HistoryCleared())

HistoryBloc._onCleared(event):
   → emit(HistoryState())         // list rỗng trong RAM
   → _persist(const [])           // box.put('entries', [])
```

Việc bắt buộc qua `AlertDialog` trước khi dispatch `HistoryCleared()` tránh xoá nhầm do bấm lộn icon thùng rác.

## Sơ đồ tổng thể

```
                 ┌────────────────────────────────────────────┐
                 │                HistoryBloc                   │
                 │   state.history: List<HistoryEntry>           │  ← 1 instance dùng
                 │   (đã sắp: gần nhất → xa nhất)                 │    chung toàn app
                 └───────┬─────────────────────────┬────────────┘
                         │ add(HistoryRecorded)      │ add(HistoryCleared)
                         │                            │
        ┌────────────────┴───────────┐      ┌─────────┴─────────────┐
        │ movie_detail_page.dart       │      │ watch_history_page.dart │
        │  _startPlayback(videoId)     │      │  icon thùng rác          │
        │  (trailer hoặc "Xem ngay"    │      │  → AlertDialog xác nhận  │
        │   thực sự bắt đầu phát)      │      │  → HistoryCleared()      │
        └──────────────────────────────┘      └───────────────────────┘
                         │
                         ▼ persist xuống Hive box "history_<uid>", key "entries"
                 (đồng bộ khi mở lại app / đổi tài khoản, theo authStateChanges)
                         │
                         ▼
        ┌───────────────────────────────────────────────────────┐
        │                    watch_history_page.dart               │
        │  context.watch<HistoryBloc>().state.history               │
        │  rỗng → empty-state | có dữ liệu → ListView (poster+tên)  │
        │  tap item → MovieDetailPage(movie: entry.movie)            │
        └───────────────────────────────────────────────────────┘
                         ▲
                 profile_page.dart: hàng "Lịch sử xem" (dưới "Chế độ tối")
                 Navigator.push → WatchHistoryPage
```

## Điểm nên nhớ

- Nếu sau này thêm nguồn ghi lịch sử khác (vd xem phim đầy đủ thật sự khi có backend, thay vì `_fakeFullMovieVideoId`), vẫn bắn `HistoryRecorded` ở đúng điểm biết chắc video đã bắt đầu phát — không ghi ở bước điều hướng, tránh lịch sử bị "ghi khống" cho phim chỉ mới xem trang chi tiết mà chưa bấm play.
- `HistoryEntry.watchedAt` đã được lưu sẵn (không dùng để sort, vì thứ tự chèn đã đảm bảo đúng) — có thể tận dụng để hiển thị "Xem lúc..." trên UI nếu cần mà không phải đổi schema lưu trữ.
- Cùng cơ chế Hive theo `uid` như `WatchlistBloc`: đăng xuất/đổi tài khoản sẽ tự đóng box cũ và mở box mới, không lẫn lịch sử giữa các tài khoản dùng chung thiết bị.
