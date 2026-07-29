import '../models/movie.dart';

// Danh sách phim giả để dựng giao diện trước khi có API/CSDL thật.
// Có nhiều thể loại khác nhau để màn Trang chủ có nhiều hàng ngang,
// và màn Danh mục có đủ dữ liệu để lọc.
final List<Movie> fakeMovies = [
  Movie(
    id: '1',
    title: 'Dune: Part Two',
    poster: 'assets/images/poster1.png',
    duration: '2h 46m',
    rating: 8.5,
    overview:
        'Paul Atreides hợp nhất với người Fremen để trả thù những kẻ đã '
        'hủy diệt gia đình mình. Đối mặt với một lựa chọn giữa tình yêu '
        'của đời mình và số phận của cả vũ trụ, anh phải ngăn chặn một '
        'tương lai khủng khiếp mà chỉ mình anh có thể nhìn thấy trước.',
    genre: 'Khoa học viễn tưởng',
  ),
  Movie(
    id: '2',
    title: 'The Batman',
    poster: 'assets/images/poster2.png',
    duration: '2h 56m',
    rating: 7.9,
    overview:
        'Batman điều tra chuỗi án mạng bí ẩn ở Gotham, dần lộ ra tham '
        'nhũng ăn sâu trong thành phố và mối liên hệ với chính quá khứ '
        'gia đình Wayne.',
    genre: 'Hành động',
  ),
  Movie(
    id: '3',
    title: 'Avatar',
    poster: 'assets/images/poster3.png',
    duration: '3h 12m',
    rating: 8.1,
    overview:
        'Trở lại thế giới Pandora, Jake Sully cùng gia đình phải chiến '
        'đấu để bảo vệ hành tinh của mình trước một mối đe dọa mới.',
    genre: 'Khoa học viễn tưởng',
  ),
  Movie(
    id: '4',
    title: 'Inside Out 2',
    poster: 'assets/images/poster1.png',
    duration: '1h 36m',
    rating: 8.0,
    overview:
        'Riley bước vào tuổi dậy thì, và cùng với đó là những cảm xúc '
        'mới xuất hiện trong "trụ sở chính", làm đảo lộn mọi thứ.',
    genre: 'Hoạt hình',
  ),
  Movie(
    id: '5',
    title: 'Oppenheimer',
    poster: 'assets/images/poster2.png',
    duration: '3h 0m',
    rating: 8.9,
    overview:
        'Câu chuyện về nhà vật lý J. Robert Oppenheimer và vai trò của '
        'ông trong việc phát triển bom nguyên tử.',
    genre: 'Tiểu sử',
  ),
  Movie(
    id: '6',
    title: 'Wonka',
    poster: 'assets/images/poster3.png',
    duration: '1h 56m',
    rating: 7.2,
    overview:
        'Câu chuyện về những ngày đầu của Willy Wonka, trước khi ông trở '
        'thành chủ nhân xưởng socola nổi tiếng nhất thế giới.',
    genre: 'Hoạt hình',
  ),
];

// Hàm tiện ích: lấy danh sách thể loại duy nhất từ toàn bộ phim.
List<String> get allGenres =>
    fakeMovies.map((m) => m.genre).toSet().toList();

// Hàm tiện ích: lọc phim theo thể loại.
List<Movie> moviesByGenre(String genre) =>
    fakeMovies.where((m) => m.genre == genre).toList();
