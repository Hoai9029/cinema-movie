import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../models/movie.dart';
import 'watchlist_event.dart';
import 'watchlist_state.dart';

// ============================================================
// Quản lý favorites toàn app bằng Bloc (thay cho WatchlistState
// ChangeNotifier trước đây). Lưu cả Movie (không chỉ id) vì dữ liệu
// phim đến từ TMDB — trang Yêu thích cần đủ thông tin (poster, tiêu
// đề, ...) để hiển thị mà không phải gọi lại API.
//
// LƯU TRỮ: Hive (local, đồng bộ). Mỗi tài khoản có 1 box riêng tên
// "favorites_<uid>" để dữ liệu không lẫn khi nhiều người dùng chung
// một máy/thiết bị. Bloc tự lắng nghe authStateChanges của Firebase
// (add WatchlistAuthChanged) để mở box đúng người dùng khi đăng
// nhập, và đóng box + xoá dữ liệu trong RAM khi đăng xuất/đổi
// tài khoản.
// ============================================================
class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  WatchlistBloc({firebase_auth.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
      super(const WatchlistState()) {
    on<WatchlistToggled>(_onToggled);
    on<WatchlistAuthChanged>(_onAuthChanged);

    // Đăng ký on<>() xong mới subscribe, vì add() gọi trước khi có
    // EventHandler đăng ký sẽ ném lỗi.
    _authSubscription = _firebaseAuth.authStateChanges().listen(
      (user) => add(WatchlistAuthChanged(user)),
    );
  }

  final firebase_auth.FirebaseAuth _firebaseAuth;
  late final StreamSubscription<firebase_auth.User?> _authSubscription;

  Box? _box;

  // Chặn double-toggle khi người dùng bấm tim liên tiếp quá nhanh (vd
  // double-tap ngoài ý muốn) — theo dõi lần bấm gần nhất CHO TỪNG phim
  // riêng biệt, để bấm tim phim A không ảnh hưởng tới việc bấm tim
  // phim B ngay sau đó.
  final Map<String, DateTime> _lastToggleAt = {};
  static const _debounceWindow = Duration(milliseconds: 500);

  static String _boxNameFor(String uid) => 'favorites_$uid';

  Future<void> _onAuthChanged(
    WatchlistAuthChanged event,
    Emitter<WatchlistState> emit,
  ) async {
    // Luôn đóng box cũ trước, để không bao giờ hiển thị nhầm dữ liệu
    // của người dùng trước đó.
    await _closeBox();

    final user = event.user;
    if (user == null) {
      emit(const WatchlistState());
      return;
    }

    _box = await Hive.openBox(_boxNameFor(user.uid));
    final favorites = <String, Movie>{};
    for (final raw in _box!.values) {
      final movie = Movie.fromJson(Map<String, dynamic>.from(raw as Map));
      favorites[movie.id] = movie;
    }
    emit(WatchlistState(favorites: favorites));
  }

  Future<void> _closeBox() async {
    final box = _box;
    _box = null;
    if (box != null && box.isOpen) {
      await box.close();
    }
  }

  void _onToggled(WatchlistToggled event, Emitter<WatchlistState> emit) {
    final movie = event.movie;
    final now = DateTime.now();
    final last = _lastToggleAt[movie.id];
    if (last != null && now.difference(last) < _debounceWindow) {
      // Bị debounce: không emit gì cả -> BlocListener sẽ không chạy,
      // tương đương hành vi trả về null như bản ChangeNotifier cũ.
      return;
    }
    _lastToggleAt[movie.id] = now;

    final favorites = Map<String, Movie>.from(state.favorites);
    final bool isNowFavorite;
    if (favorites.containsKey(movie.id)) {
      favorites.remove(movie.id);
      isNowFavorite = false;
      // Không await: Hive ghi xuống đĩa ở background, không cần chờ
      // mạng nên UI vẫn cập nhật tức thì.
      _box?.delete(movie.id);
    } else {
      favorites[movie.id] = movie;
      isNowFavorite = true;
      _box?.put(movie.id, movie.toJson());
    }

    emit(
      WatchlistState(
        favorites: favorites,
        lastToggle: FavoriteToggle(
          movieId: movie.id,
          isFavorite: isNowFavorite,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    await _box?.close();
    return super.close();
  }
}
