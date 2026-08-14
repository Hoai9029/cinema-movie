# Luồng xem trailer + "Xem ngay" nhúng ngay trên trang chi tiết phim

## Vấn đề cần giải quyết

Trước đây bấm nút play ở giữa ảnh backdrop sẽ `Navigator.push` sang `TrailerPlayerPage` (trang riêng), còn nút "Xem ngay" thì `Navigator.push` sang `WatchPage` (trang giả lập bằng `Timer` đếm giây, không có video thật). Cả hai đều rời khỏi trang chi tiết phim.

Yêu cầu mới: video (trailer lẫn "xem ngay") phải phát **ngay tại khung ảnh 300px ở đầu `MovieDetailPage`**, giống YouTube app / Bilibili — không chuyển trang, có nút tua ±10s, có nút phóng to màn hình ngang và thu nhỏ lại đúng vị trí cũ. Giải pháp: dùng **1 `YoutubePlayerController` duy nhất**, sống trong `_MovieDetailViewState`, tái sử dụng package `youtube_player_flutter` đã có sẵn (không thêm dependency mới).

## Các thành phần

| File | Vai trò |
|---|---|
| `lib/pages/movie_detail_page.dart` | Toàn bộ logic nằm ở đây: `_MovieDetailView` (StatefulWidget) giữ `YoutubePlayerController`, `_buildHeader` quyết định hiển thị ảnh backdrop hay video. |
| `package:youtube_player_flutter` | `YoutubePlayerController` (play/pause/seekTo/load), `YoutubePlayer` (widget hiển thị + `bottomActions` tùy biến), `YoutubePlayerBuilder` (tự lo xoay ngang + fullscreen). |
| `lib/bloc/movie_detail/movie_detail_bloc.dart` | Nguồn cấp `trailerVideo.key` (id YouTube trailer lấy từ TMDB) qua state `MovieDetailLoaded`. |
| `_fakeFullMovieVideoId` (hằng số đầu file `movie_detail_page.dart`) | Id video giả lập cho "Xem ngay" — parse từ link YouTube thật bằng `YoutubePlayer.convertUrlToId(...)`, chỗ này sẽ thay bằng link phim thật khi có backend. |

`trailer_player_page.dart` và `watch_page.dart` (+ route `/watch/:id`) không còn được `movie_detail_page.dart` gọi tới nữa, nhưng vẫn giữ nguyên file (chưa xoá) để không ảnh hưởng phần khác nếu đang được dùng dở ở đâu đó.

## Luồng chạy từng bước

### 1. Vào trang chi tiết → trailer tự phát, không cần bấm nút play

```
MovieDetailPage → BlocProvider(MovieDetailBloc)
   → add(MovieDetailRequested(movieId))   // gọi TMDB API

_MovieDetailView.build()
   → BlocConsumer<MovieDetailBloc, MovieDetailState>
        listener: state is MovieDetailLoaded && _playerController == null
           → trailer = state.bundle.trailerVideo
           → _startPlayback(trailer.key)
                → setState(() => _playerController = YoutubePlayerController(
                      initialVideoId: trailer.key,
                      flags: YoutubePlayerFlags(autoPlay: true, mute: false),
                    ))
```

`_startPlayback` chỉ chạy **đúng 1 lần** (điều kiện `_playerController == null`) — dù `MovieDetailBloc` có emit lại state Loaded (ví dụ bấm "Thử lại" sau lỗi) cũng không tạo controller mới, không phát lại trailer từ đầu nếu người dùng đã chuyển sang xem phim đầy đủ.

### 2. Khung 300px hiển thị theo state của `_playerController`

```
build() → nếu _playerController == null:
             _buildScaffold(..., player: null)
                → _buildHeader hiện Hero(poster/backdrop) + gradient tối (như cũ)

          nếu _playerController != null:
             bọc bằng YoutubePlayerBuilder(
               player: YoutubePlayer(controller: ..., bottomActions: [...]),
               builder: (context, player) => _buildScaffold(..., player: player),
             )
                → _buildHeader hiện player, bọc Center + AspectRatio(16:9)
                  (để Stack.expand không ép méo hình video)
```

Nút back (góc trái) và nút yêu thích (góc phải) luôn nổi trên đầu, không phụ thuộc đang phát video hay không.

### 3. Điều khiển video: tua ±10s

`YoutubePlayer.bottomActions` được truyền tùy biến, thêm 2 `IconButton` (`Icons.replay_10` / `Icons.forward_10`) cạnh `CurrentPosition`/`ProgressBar`/`RemainingDuration` mặc định:

```
bấm nút tua tới/lùi
   → _seekBy(Duration(seconds: ±10))
        → target = controller.value.position + offset
        → clamp [0, controller.metadata.duration]
        → controller.seekTo(target)   // seekTo tự gọi play() luôn
```

### 4. Bấm "Xem ngay" → đổi nguồn video ngay trong cùng khung, KHÔNG tải lại API detail

```
ElevatedButton "Xem ngay" → onPressed: _playFullMovie

_playFullMovie():
   nếu _playerController == null   (phim không có trailer, chưa từng phát gì)
       → _startPlayback(_fakeFullMovieVideoId)   // tạo controller mới, autoplay
   nếu _playerController != null   (đang phát trailer)
       → controller.load(_fakeFullMovieVideoId)  // đổi nguồn ngay trên player đang chạy
```

`controller.load()` chỉ gọi `loadById()` của YouTube IFrame Player API bên trong WebView đã nhúng sẵn — **không** đụng tới `MovieDetailBloc`, không gọi lại `TmdbApi`, không mất vị trí cuộn của `ListView`, không tạo `WebView` mới.

### 5. Phóng to màn hình ngang / thu nhỏ lại

`FullScreenButton` (widget có sẵn trong `bottomActions` mặc định của package) gọi `controller.toggleFullScreenMode()`:

```
bấm icon fullscreen
   → controller.toggleFullScreenMode()
        → SystemChrome.setPreferredOrientations([landscapeLeft, landscapeRight])

YoutubePlayerBuilder lắng nghe didChangeMetrics (kích thước màn hình đổi do xoay)
   → vật lý màn hình rộng hơn cao → set isFullScreen = true
        → SystemChrome.setEnabledSystemUIMode(immersiveSticky)  // ẩn status bar
        → OrientationBuilder đổi sang hiện player CHIẾM TOÀN MÀN HÌNH,
          thay cho toàn bộ _buildScaffold() (ẩn tạm cast/mô tả/nút Xem ngay)

bấm back hệ thống / bấm lại icon fullscreen khi đang fullscreen
   → PopScope trong YoutubePlayerBuilder chặn pop, tự toggleFullScreenMode() về false
        → SystemChrome.setPreferredOrientations([portraitUp])
        → didChangeMetrics bắn lại → isFullScreen = false
        → OrientationBuilder quay lại hiện _buildScaffold() như cũ,
          video vẫn đang phát đúng vị trí embed trong trang detail (không mất tiến trình)
```

Toàn bộ phần khoá xoay/ẩn status bar/pop-to-collapse này nằm sẵn trong `YoutubePlayerBuilder` của package — không tự viết `SystemChrome`/`OrientationBuilder` tay.

## Sơ đồ tổng thể

```
                    ┌───────────────────────────────────────┐
                    │      _MovieDetailViewState              │
                    │  _playerController: YoutubePlayerController?  │  ← 1 instance
                    └───────────────┬─────────────────────────┘    dùng chung
                                    │
        ┌───────────────────────────┼────────────────────────────┐
        │ null (chưa có video)       │ khác null (đang phát)       │
        ▼                            ▼
┌───────────────────┐     ┌─────────────────────────────────────┐
│ Hero(poster) +      │     │ YoutubePlayerBuilder                 │
│ gradient tối         │     │  ├─ portrait: player nhúng trong     │
│ (như trước đây)      │     │  │   khung 300px của MovieDetailPage │
└───────────────────┘     │  └─ landscape/fullscreen: player       │
                            │      chiếm toàn màn hình               │
                            └─────────────────────────────────────┘
                                    ▲                    ▲
                          trailer tự động           bấm "Xem ngay"
                          phát khi MovieDetailLoaded  → controller.load(id khác)
```

## Điểm nên nhớ khi thay `_fakeFullMovieVideoId` bằng dữ liệu thật

- Khi backend/TMDB cấp link phim thật cho từng phim, thay hằng số `_fakeFullMovieVideoId` (đầu file) bằng giá trị lấy từ `state.bundle` (ví dụ thêm field `fullMovieVideoId` vào `MovieDetailBundle`), rồi truyền id đó vào `_playFullMovie()` thay vì hằng số cố định.
- Không cần đổi gì ở phần `YoutubePlayerBuilder`/`bottomActions`/`_seekBy` — các phần đó không phụ thuộc video đang phát là trailer hay phim đầy đủ.
- Nếu sau này thêm tính năng "Lịch sử xem phim", nên bắn event ghi lịch sử ngay trong `_playFullMovie()` (hoặc lắng nghe `controller` chuyển sang trạng thái `playing` thực sự), không ghi ở nơi khác — vì đây là điểm duy nhất biết chính xác lúc nào người dùng bắt đầu xem phim đầy đủ.
