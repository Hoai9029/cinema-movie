import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../models/movie.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class HistoryRecorded extends HistoryEvent {
  const HistoryRecorded(this.movie);

  final Movie movie;

  @override
  List<Object?> get props => [movie];
}

class HistoryCleared extends HistoryEvent {
  const HistoryCleared();
}

// Chỉ HistoryBloc tự add() event này (từ authStateChanges() listener
// trong constructor) — đặt private để nơi khác không gọi nhầm.
class HistoryAuthChanged extends HistoryEvent {
  const HistoryAuthChanged(this.user);

  final firebase_auth.User? user;

  @override
  List<Object?> get props => [user];
}
