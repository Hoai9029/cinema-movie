import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/movie.dart';

// ============================================================
// State dùng chung cho toàn app (thay cho BookingState của bản
// đặt vé cũ). Đây KHÔNG có trong danh sách khái niệm bắt buộc,
// nhưng vẫn giữ lại vì nó là ví dụ tốt cho việc chia sẻ dữ liệu
// giữa nhiều StatefulWidget khác nhau (Trang chủ, Chi tiết phim,
// Yêu thích) mà không cần truyền tay qua từng màn.
//
// ChangeNotifier: khi có thay đổi, gọi notifyListeners() để mọi
// widget đang "lắng nghe" (context.watch) tự vẽ lại.
//
// Lưu cả Movie (không chỉ id) vì dữ liệu phim đến từ TMDB — trang
// Yêu thích cần đủ thông tin (poster, tiêu đề, ...) để hiển thị mà
// không phải gọi lại API hay tra cứu trong danh sách phim mẫu.
//
// LƯU TRỮ: dùng Hive (local, đồng bộ, không cần chờ mạng). Mỗi
// tài khoản có một box riêng tên "favorites_<uid>" để dữ liệu
// không bị lẫn khi nhiều người dùng chung một máy/thiết bị. State
// tự lắng nghe authStateChanges của Firebase để mở box đúng người
// dùng khi đăng nhập, và đóng box + xoá dữ liệu trong RAM khi
// đăng xuất hoặc đổi tài khoản.
// ============================================================
class WatchlistState extends ChangeNotifier {
  WatchlistState({firebase_auth.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance {
    _authSubscription = _firebaseAuth.authStateChanges().listen(
      _onAuthChanged,
    );
  }

  final firebase_auth.FirebaseAuth _firebaseAuth;
  late final StreamSubscription<firebase_auth.User?> _authSubscription;

  Box? _box;
  final Map<String, Movie> _favorites = {};

  // Chặn double-toggle khi người dùng bấm tim liên tiếp quá nhanh (vd
  // double-tap ngoài ý muốn) — theo dõi lần bấm gần nhất CHO TỪNG phim
  // riêng biệt, để bấm tim phim A không ảnh hưởng tới việc bấm tim
  // phim B ngay sau đó.
  final Map<String, DateTime> _lastToggleAt = {};
  static const _debounceWindow = Duration(milliseconds: 500);

  bool isFavorite(String movieId) => _favorites.containsKey(movieId);

  List<Movie> get favoriteMovies => _favorites.values.toList();

  static String _boxNameFor(String uid) => 'favorites_$uid';

  // Chạy mỗi khi trạng thái đăng nhập Firebase thay đổi: đăng nhập,
  // đăng xuất, hoặc đổi sang tài khoản khác trên cùng thiết bị.
  Future<void> _onAuthChanged(firebase_auth.User? user) async {
    // Luôn đóng box cũ + xoá sạch bộ nhớ RAM trước, để không bao giờ
    // hiển thị nhầm dữ liệu của người dùng trước đó.
    await _closeBox();
    _favorites.clear();

    if (user != null) {
      _box = await Hive.openBox(_boxNameFor(user.uid));
      for (final raw in _box!.values) {
        final movie = Movie.fromJson(Map<String, dynamic>.from(raw as Map));
        _favorites[movie.id] = movie;
      }
    }

    notifyListeners();
  }

  Future<void> _closeBox() async {
    final box = _box;
    _box = null;
    if (box != null && box.isOpen) {
      await box.close();
    }
  }

  // Trả về true nếu phim VỪA được thêm vào yêu thích, false nếu VỪA bị
  // xoá, hoặc null nếu lần bấm này bị bỏ qua vì đến quá nhanh sau lần
  // bấm trước (debounce) — UI dùng giá trị này để quyết định có hiện
  // toast hay không, tránh toast bắn liên tục khi bấm nhanh tay.
  bool? toggleFavorite(Movie movie) {
    final now = DateTime.now();
    final last = _lastToggleAt[movie.id];
    if (last != null && now.difference(last) < _debounceWindow) {
      return null;
    }
    _lastToggleAt[movie.id] = now;

    final bool isNowFavorite;
    if (_favorites.containsKey(movie.id)) {
      _favorites.remove(movie.id);
      isNowFavorite = false;
      // Không await: Hive ghi xuống đĩa ở background, không cần chờ
      // mạng nên UI vẫn cập nhật tức thì.
      _box?.delete(movie.id);
    } else {
      _favorites[movie.id] = movie;
      isNowFavorite = true;
      _box?.put(movie.id, movie.toJson());
    }
    notifyListeners();
    return isNowFavorite;
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _box?.close();
    super.dispose();
  }
}
