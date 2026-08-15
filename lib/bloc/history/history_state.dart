import 'package:equatable/equatable.dart';

import '../../models/movie.dart';

// Một lượt xem: phim + mốc thời gian xem, để phục vụ sắp xếp "gần
// nhất lên đầu" và có thể hiển thị thời gian xem sau này nếu cần.
class HistoryEntry extends Equatable {
  const HistoryEntry({required this.movie, required this.watchedAt});

  final Movie movie;
  final DateTime watchedAt;

  Map<String, dynamic> toJson() => {
    'movie': movie.toJson(),
    'watchedAt': watchedAt.toIso8601String(),
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    movie: Movie.fromJson(Map<String, dynamic>.from(json['movie'] as Map)),
    watchedAt: DateTime.parse(json['watchedAt'] as String),
  );

  @override
  List<Object?> get props => [movie, watchedAt];
}

class HistoryState extends Equatable {
  const HistoryState({this.history = const []});

  // Đã được HistoryBloc giữ đúng thứ tự "xem gần nhất ở đầu" ngay khi
  // ghi nhận, nên nơi hiển thị dùng thẳng danh sách này mà không cần
  // sort lại.
  final List<HistoryEntry> history;

  HistoryState copyWith({List<HistoryEntry>? history}) {
    return HistoryState(history: history ?? this.history);
  }

  @override
  List<Object?> get props => [history];
}
