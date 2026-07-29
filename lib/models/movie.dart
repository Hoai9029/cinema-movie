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
}
