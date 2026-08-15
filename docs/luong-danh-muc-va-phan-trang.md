# Luồng "Danh mục" (Categories): thể loại tiếng Việt & tải thêm phim (infinite scroll)

## Vấn đề cần giải quyết

Trang Danh mục (`categories_page.dart`) trước đây có 2 hạn chế:

1. Chip thể loại chỉ liệt kê 4 thể loại (Horror, Romance, Action, Fantasy) bằng tiếng Anh, trong khi phần còn lại của app đã dùng tiếng Việt — không đồng bộ và thiếu hẳn 15 thể loại chuẩn của TMDB.
2. Mỗi lần chọn thể loại hoặc tìm kiếm, `CategoriesBloc` chỉ gọi API với `page: 1` — TMDB trả tối đa 20 phim/trang, nên dù thể loại có hàng nghìn phim, người dùng chỉ thấy đúng ~20 phim rồi hết, không có cách nào xem thêm.

Giải pháp: dịch đầy đủ 19 thể loại phim chuẩn của TMDB sang tiếng Việt, và thêm cơ chế phân trang kiểu infinite scroll — tự động gọi trang tiếp theo khi người dùng cuộn gần chạm đáy danh sách.

## Các thành phần

| File | Vai trò |
|---|---|
| `lib/pages/categories_page.dart` | `_genres` map đầy đủ 19 thể loại (tên tiếng Việt → id TMDB); `_buildGrid` đổi từ `GridView.builder` sang `CustomScrollView` + `SliverGrid`, bọc `NotificationListener<ScrollNotification>` để phát hiện cuộn gần đáy. |
| `lib/bloc/categories/categories_event.dart` | Thêm `CategoriesLoadMoreRequested` — xin tải trang tiếp theo của truy vấn đang active. |
| `lib/bloc/categories/categories_state.dart` | `CategoriesLoaded` thêm `hasMore` (còn trang để tải không) và `isLoadingMore` (đang tải trang tiếp theo, để hiện spinner cuối lưới). |
| `lib/bloc/categories/categories_bloc.dart` | Theo dõi `_page`, `_totalPages`, `_movies` (danh sách tích luỹ); nối kết quả trang mới vào `_movies` thay vì ghi đè. |
| `lib/data/api/tmdb_api.dart` | `getMoviesByGenre` / `searchMovies` đã sẵn tham số `page` (Retrofit) — không cần đổi, chỉ được gọi với giá trị khác 1 từ giờ. |
| `lib/data/models/tmdb_movie_response.dart` | Parse thêm `page` và `total_pages` từ JSON trả về của TMDB để biết còn trang tiếp theo hay không. |

## Luồng chạy từng bước

### 1. Chọn thể loại hoặc gõ tìm kiếm → luôn nạp lại từ trang 1

```
CategoriesPage._onGenreSelected(genre) / _onSearchChanged(value)
   → bloc.add(CategoriesGenreSelected) hoặc CategoriesSearchChanged

CategoriesBloc._loadByGenre() / _search():
   → emit(CategoriesLoading())
   → _page = 1
   → gọi TmdbApi.getMoviesByGenre(genreId) / searchMovies(query)   // page mặc định = 1
   → _totalPages = response.totalPages
   → _movies = response.results.map(toMovie)      // GHI ĐÈ, không nối
   → emit(CategoriesLoaded(_movies, hasMore: _page < _totalPages))
```

Đổi thể loại/tìm kiếm luôn là một truy vấn mới nên `_movies` bị ghi đè hoàn toàn, không giữ lại kết quả của thể loại cũ.

### 2. Cuộn gần đáy danh sách → tự động xin trang tiếp theo

```
CategoriesPage._buildGrid(movies, showLoadingMore):
   CustomScrollView bọc trong NotificationListener<ScrollNotification>
   onNotification(notification):
        nếu notification.metrics.extentAfter < 300   // còn <300px là chạm đáy
           → bloc.add(CategoriesLoadMoreRequested())
        return false   // không chặn notification lan tiếp (cho RefreshIndicator ở ngoài)

CategoriesBloc._onLoadMoreRequested(event):
   → nếu state không phải CategoriesLoaded, hoặc đang isLoadingMore,
     hoặc !hasMore → return (bỏ qua, không gọi API)
   → emit(CategoriesLoaded(_movies, hasMore: true, isLoadingMore: true))   // hiện spinner
   → nextPage = _page + 1
   → gọi lại đúng API đang active (genre hoặc search) với page: nextPage
   → _page = nextPage; _totalPages = response.totalPages
   → _movies = [..._movies, ...response.results.map(toMovie)]   // NỐI vào cuối
   → emit(CategoriesLoaded(_movies, hasMore: _page < _totalPages))
```

Vì `NotificationListener` bắn ra rất nhiều sự kiện scroll liên tiếp trong lúc cuộn, `_onLoadMoreRequested` phải tự chặn (guard) bằng `isLoadingMore`/`hasMore` ngay ở đầu hàm — gọi `add()` nhiều lần trong lúc cuộn là bình thường và vô hại.

### 3. Kéo để tải lại (pull-to-refresh)

```
RefreshIndicator.onRefresh → bloc.refresh()
   → add(CategoriesRefreshRequested())
   → _onRefreshRequested phát lại đúng _loadByGenre() hoặc _search()
     (Bloc tự nhớ truy vấn đang active) → _page reset về 1, _movies ghi đè lại từ đầu
```

### 4. Tải thêm thất bại (mất mạng giữa chừng)

```
CategoriesBloc._onLoadMoreRequested catch (e):
   → emit(CategoriesLoaded(_movies, hasMore: current.hasMore))   // tắt spinner
   // KHÔNG xoá _movies đã có, không chuyển sang CategoriesError
   // → người dùng vẫn thấy các phim đã tải, có thể cuộn thử lại để retry
```

## Sơ đồ tổng thể

```
┌─────────────────────────────────────────────────────────────────┐
│                         CategoriesBloc                            │
│   _page, _totalPages, _movies (danh sách tích luỹ)                 │
└───────┬───────────────┬───────────────┬───────────────┬──────────┘
        │ GenreSelected  │ SearchChanged  │ LoadMoreReq.   │ RefreshReq.
        │ (reset trang 1)│ (reset trang 1)│ (nối thêm trang)│ (reset trang 1)
        ▼               ▼               ▼               ▼
   emit CategoriesLoaded(_movies, hasMore, isLoadingMore)
        │
        ▼
categories_page.dart _buildGrid(movies, showLoadingMore)
   CustomScrollView
      ├─ SliverGrid: mỗi phim = _MovieGridTile
      └─ (nếu showLoadingMore) SliverToBoxAdapter: CircularProgressIndicator
   NotificationListener<ScrollNotification>
      → extentAfter < 300px → bloc.add(CategoriesLoadMoreRequested())
```

## Điểm nên nhớ

- `_genres` trong `categories_page.dart` dùng đúng 19 id thể loại chuẩn của TMDB (`/genre/movie/list`) — nếu TMDB đổi bộ thể loại, chỉ cần sửa map này, không đụng tới bloc/API.
- Đổi `GridView.builder` sang `CustomScrollView` + `SliverGrid` là bắt buộc để chèn được spinner tải-thêm chạy full chiều ngang bên dưới lưới (một item `GridView` bình thường sẽ bị bó vào 1 ô lưới, méo layout).
- TMDB giới hạn `total_pages` tối đa 500 dù thể loại có nhiều phim hơn — infinite scroll sẽ tự dừng (`hasMore = false`) khi chạm mốc đó, đây là giới hạn từ phía TMDB, không phải bug.
- Nếu sau này thêm bộ lọc mới (vd sort_by, năm phát hành) cho Danh mục, nhớ reset `_page = 1` và ghi đè `_movies` giống `_loadByGenre`/`_search`, tránh lẫn kết quả trang cũ của bộ lọc trước vào bộ lọc mới.
