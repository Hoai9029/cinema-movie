import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../models/movie.dart';

sealed class WatchlistEvent extends Equatable {
  const WatchlistEvent();

  @override
  List<Object?> get props => [];
}

class WatchlistToggled extends WatchlistEvent {
  const WatchlistToggled(this.movie);

  final Movie movie;

  @override
  List<Object?> get props => [movie];
}

// Chỉ WatchlistBloc tự add() event này (từ authStateChanges() listener
// trong constructor) — đặt private để nơi khác không gọi nhầm.
class WatchlistAuthChanged extends WatchlistEvent {
  const WatchlistAuthChanged(this.user);

  final firebase_auth.User? user;

  @override
  List<Object?> get props => [user];
}
