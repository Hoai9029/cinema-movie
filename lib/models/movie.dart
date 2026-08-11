// Mô hình dữ liệu (Entity) cho một bộ phim trong ứng dụng XEM phim
// (không phải đặt vé, nên không có trường ghế/suất chiếu/rạp nữa).
class Movie {
  final String id;
  final String title;
  final String poster; // đường dẫn ảnh trong assets/images
  final String duration; // thời lượng phim, vd "2h 46m"
  final double rating; // điểm đánh giá trung bình, thang 10
  final String overview; // mô tả nội dung phim
  final String genre; // thể loại, dùng để nhóm phim theo hàng ngang

  Movie({
    required this.id,
    required this.title,
    required this.poster,
    required this.duration,
    required this.rating,
    required this.overview,
    required this.genre,
  });

  // Chỉ gồm các kiểu nguyên thuỷ (String/double) nên Hive lưu/đọc
  // trực tiếp được mà không cần đăng ký TypeAdapter riêng.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'poster': poster,
    'duration': duration,
    'rating': rating,
    'overview': overview,
    'genre': genre,
  };

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
    id: json['id'] as String,
    title: json['title'] as String,
    poster: json['poster'] as String,
    duration: json['duration'] as String,
    rating: (json['rating'] as num).toDouble(),
    overview: json['overview'] as String,
    genre: json['genre'] as String,
  );
}
