# 🎬 CineStream

**CineStream** là ứng dụng xem phim đa nền tảng xây dựng bằng Flutter, lấy dữ liệu phim thời gian thực từ **TMDB API**, xác thực người dùng qua **Firebase Authentication**, và quản lý toàn bộ state ứng dụng theo kiến trúc **BLoC**.

<p align="center">
  <img src="assets/images/CineStream_Logo.png" alt="CineStream Logo" width="140" />
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white" />
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black" />
  <img alt="State Management" src="https://img.shields.io/badge/State%20Management-BLoC-6E4CAF" />
  <img alt="License" src="https://img.shields.io/badge/license-MIT-green" />
</p>

---

## 📖 Giới thiệu

CineStream là project cá nhân mô phỏng một ứng dụng streaming phim thực thụ (kiểu Netflix/CGV), tập trung vào việc thực hành kiến trúc ứng dụng Flutter chuẩn production: tách lớp rõ ràng giữa UI – BLoC – Data, gọi API qua Retrofit/Dio, xác thực và lưu trữ người dùng qua Firebase, cache dữ liệu cục bộ bằng Hive.

Toàn bộ dữ liệu phim (banner, danh mục, chi tiết, diễn viên, trailer, phim tương tự...) được lấy trực tiếp từ [The Movie Database (TMDB)](https://www.themoviedb.org/), nên nội dung luôn cập nhật như một ứng dụng thật.

## ✨ Tính năng

- **Xác thực người dùng** — Đăng ký / đăng nhập bằng email & mật khẩu qua Firebase Authentication, tự động ghi nhớ phiên đăng nhập.
- **Trang chủ động** — Banner carousel tự động chuyển, danh sách "Thịnh hành", "Đề xuất cho bạn" và các dòng phim tương tự theo thể loại.
- **Danh mục & tìm kiếm** — Duyệt phim theo thể loại (chip selector) hoặc tìm kiếm theo từ khoá, hiển thị dạng lưới có phân trang.
- **Chi tiết phim** — Poster/backdrop, điểm đánh giá, thời lượng, thể loại, mô tả nội dung, danh sách diễn viên, và các phim tương tự.
- **Xem trailer trong app** — Trailer YouTube tự động phát khi vào trang chi tiết phim, hỗ trợ tua, toàn màn hình, tự tạm dừng khi chuyển trang.
- **Yêu thích (Watchlist)** — Đánh dấu/bỏ đánh dấu phim yêu thích, lưu cục bộ theo từng tài khoản bằng Hive.
- **Lịch sử xem** — Tự động ghi lại phim đã xem trailer, có thể xoá toàn bộ lịch sử.
- **Hồ sơ cá nhân** — Chỉnh sửa tên, số điện thoại, ảnh đại diện; đồng bộ với Cloud Firestore.
- **Giao diện Sáng/Tối** — Chuyển đổi theme, trạng thái được lưu lại giữa các lần mở app (Hive).
- **Loading mượt mà** — Shimmer skeleton loading và pull-to-refresh trên các màn hình danh sách.
- **Đa nền tảng** — Chạy được trên Android, iOS, Web, Windows, macOS và Linux.

## 📱 Ảnh chụp màn hình

| Trang chủ |  
<img width="639" height="976" alt="image" src="https://github.com/user-attachments/assets/cca1fd31-8fb4-4a0a-bab7-149e9b21e183" /> </p>
|Chi tiết phim|
<img width="456" height="967" alt="image" src="https://github.com/user-attachments/assets/fb1ebb2b-1bb7-475a-bf73-4f56e35d4c2d" /> </p>
| Danh mục |
<img width="460" height="970" alt="image" src="https://github.com/user-attachments/assets/a4849e29-8720-4c6e-8167-a4a6ccb46744" /> </p>

## 🏗️ Kiến trúc & Công nghệ

Ứng dụng theo kiến trúc **BLoC (Business Logic Component)**, tách biệt hoàn toàn UI khỏi logic nghiệp vụ và nguồn dữ liệu.
lib/
├── bloc/            # BLoC theo từng tính năng (auth, home, categories,
│                       movie_detail, watchlist, history, profile, theme)
├── core/            # Theme, màu sắc, hằng số dùng chung
├── data/
│   ├── api/         # TMDB API client (Dio + Retrofit)
│   ├── auth/         # Firebase Authentication repository
│   └── models/      # DTO / response models (json_serializable)
├── models/          # Domain model (Movie)
├── pages/           # Màn hình UI
├── routes/          # Định tuyến tập trung (onGenerateRoute)
├── widgets/         # Widget dùng chung
└── main.dart        # Điểm khởi động, khởi tạo Firebase, Hive, BLoC providers



**Công nghệ chính:**

| Hạng mục | Công nghệ |
| --- | --- |
| Framework | [Flutter](https://flutter.dev) 3.x / Dart 3.12 |
| State Management | [flutter_bloc](https://pub.dev/packages/flutter_bloc), [equatable](https://pub.dev/packages/equatable) |
| Networking | [Dio](https://pub.dev/packages/dio) + [Retrofit](https://pub.dev/packages/retrofit) |
| Dữ liệu phim | [TMDB API](https://developer.themoviedb.org/docs) |
| Xác thực & CSDL | [Firebase Auth](https://firebase.google.com/products/auth), [Cloud Firestore](https://firebase.google.com/products/firestore) |
| Lưu trữ cục bộ | [Hive](https://pub.dev/packages/hive) |
| Phát video | [youtube_player_flutter](https://pub.dev/packages/youtube_player_flutter) |
| UI/UX | [carousel_slider](https://pub.dev/packages/carousel_slider), [skeletonizer](https://pub.dev/packages/skeletonizer) |
| Kiểm thử | flutter_test, [bloc_test](https://pub.dev/packages/bloc_test) |

## 🚀 Bắt đầu

### Yêu cầu

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>= 3.x` (Dart `^3.12.2`)
- Một [dự án Firebase](https://console.firebase.google.com/) đã bật **Authentication** (Email/Password) và **Cloud Firestore**
- API Key của [TMDB](https://www.themoviedb.org/settings/api) (miễn phí)

### 1. Clone dự án

```bash
git clone https://github.com/Hoai9029/cinema-movie.git
cd cinema-movie
2. Cài đặt dependencies

flutter pub get
3. Cấu hình TMDB API Key
Sao chép file mẫu và điền key của bạn:


cp lib/config/tmdb_secrets.example.dart lib/config/tmdb_secrets.dart

// lib/config/tmdb_secrets.dart
class TmdbSecrets {
  static const String apiKey = 'YOUR_TMDB_API_KEY';
  static const String accessToken = 'YOUR_TMDB_READ_ACCESS_TOKEN';
}
File này đã được thêm vào .gitignore — key của bạn sẽ không bao giờ bị commit lên repository.

4. Cấu hình Firebase
Cài FlutterFire CLI và kết nối dự án Firebase của riêng bạn:


dart pub global activate flutterfire_cli
flutterfire configure
Lệnh trên sẽ tự sinh ra file lib/firebase_options.dart phù hợp với từng nền tảng bạn build.

5. Chạy ứng dụng

flutter run
Chọn thiết bị/nền tảng mong muốn (Android, iOS, Chrome, Windows...) khi được hỏi, hoặc chỉ định trực tiếp:


flutter run -d chrome     # Web
flutter run -d windows    # Windows Desktop
6. Build bản phát hành

flutter build apk --release      # Android
flutter build ios --release      # iOS
flutter build web --release      # Web
🧪 Kiểm thử

flutter test
🗺️ Định hướng phát triển
 Tích hợp nguồn phim thật (hiện dùng video mô phỏng cho tính năng "Xem ngay")
 Thông báo đẩy (push notification) cho phim mới
 Đánh giá & bình luận phim
 Đồng bộ danh sách yêu thích lên Cloud Firestore (hiện chỉ lưu cục bộ)
🤝 Đóng góp
Mọi đóng góp đều được chào đón! Vui lòng fork repository, tạo nhánh mới cho thay đổi của bạn và mở Pull Request.

Fork dự án
Tạo nhánh tính năng (git checkout -b feature/ten-tinh-nang)
Commit thay đổi (git commit -m 'Add: mô tả ngắn gọn')
Push lên nhánh (git push origin feature/ten-tinh-nang)
Mở Pull Request
📄 Giấy phép
Dự án được cấp phép theo giấy phép MIT.

🙏 Ghi nhận
Dữ liệu phim được cung cấp bởi The Movie Database (TMDB). Dự án này sử dụng TMDB API nhưng không được TMDB xác nhận hay chứng thực.
<p align="center">Được xây dựng với ❤️ bằng Flutter</p> ```
Vài lưu ý khi bạn dán lên GitHub:


