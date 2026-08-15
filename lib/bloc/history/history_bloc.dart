import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import 'history_event.dart';
import 'history_state.dart';

// ============================================================
// Quản lý lịch sử xem toàn app bằng Bloc, theo đúng cách tổ chức
// của WatchlistBloc (bloc/watchlist/watchlist_bloc.dart).
//
// LƯU TRỮ: Hive (local, đồng bộ), mỗi tài khoản 1 box riêng tên
// "history_<uid>" để không lẫn dữ liệu giữa nhiều người dùng chung
// máy. Khác với WatchlistBloc (mỗi phim là 1 key riêng, thứ tự
// không quan trọng), lịch sử xem CẦN giữ đúng thứ tự "xem gần nhất
// lên đầu" nên toàn bộ danh sách được lưu chung dưới 1 key duy nhất.
// Bloc tự lắng nghe authStateChanges của Firebase để mở box đúng
// người dùng khi đăng nhập, và đóng box + xoá dữ liệu trong RAM khi
// đăng xuất/đổi tài khoản.
// ============================================================
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({firebase_auth.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
      super(const HistoryState()) {
    on<HistoryRecorded>(_onRecorded);
    on<HistoryCleared>(_onCleared);
    on<HistoryAuthChanged>(_onAuthChanged);

    // Đăng ký on<>() xong mới subscribe, vì add() gọi trước khi có
    // EventHandler đăng ký sẽ ném lỗi.
    _authSubscription = _firebaseAuth.authStateChanges().listen(
      (user) => add(HistoryAuthChanged(user)),
    );
  }

  final firebase_auth.FirebaseAuth _firebaseAuth;
  late final StreamSubscription<firebase_auth.User?> _authSubscription;

  Box? _box;

  static const _entriesKey = 'entries';

  static String _boxNameFor(String uid) => 'history_$uid';

  Future<void> _onAuthChanged(
    HistoryAuthChanged event,
    Emitter<HistoryState> emit,
  ) async {
    // Luôn đóng box cũ trước, để không bao giờ hiển thị nhầm dữ liệu
    // của người dùng trước đó.
    await _closeBox();

    final user = event.user;
    if (user == null) {
      emit(const HistoryState());
      return;
    }

    _box = await Hive.openBox(_boxNameFor(user.uid));
    final raw = _box!.get(_entriesKey) as List?;
    final history = raw == null
        ? <HistoryEntry>[]
        : raw
              .map(
                (item) =>
                    HistoryEntry.fromJson(Map<String, dynamic>.from(item as Map)),
              )
              .toList();
    emit(HistoryState(history: history));
  }

  Future<void> _closeBox() async {
    final box = _box;
    _box = null;
    if (box != null && box.isOpen) {
      await box.close();
    }
  }

  void _onRecorded(HistoryRecorded event, Emitter<HistoryState> emit) {
    final movie = event.movie;
    final history = List<HistoryEntry>.from(state.history)
      ..removeWhere((entry) => entry.movie.id == movie.id);
    history.insert(0, HistoryEntry(movie: movie, watchedAt: DateTime.now()));

    emit(state.copyWith(history: history));
    _persist(history);
  }

  void _onCleared(HistoryCleared event, Emitter<HistoryState> emit) {
    emit(const HistoryState());
    _persist(const []);
  }

  void _persist(List<HistoryEntry> history) {
    // Không await: Hive ghi xuống đĩa ở background, không cần chờ để
    // UI vẫn cập nhật tức thì.
    _box?.put(_entriesKey, history.map((entry) => entry.toJson()).toList());
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    await _box?.close();
    return super.close();
  }
}
