import 'package:flutter/material.dart';

// ============================================================
// KHÁI NIỆM: RESPONSIVE UI
// Đây là widget quan trọng nhất cho việc chạy app dưới dạng WEB.
// Trên điện thoại, nội dung nên chiếm toàn bộ chiều ngang màn
// hình. Nhưng trên trình duyệt máy tính (màn hình rộng), nếu để
// nội dung kéo dài hết 1920px sẽ rất khó đọc (chữ bị kéo dài quá
// mức, ảnh méo). Cách xử lý phổ biến: giới hạn nội dung ở một
// chiều rộng tối đa và canh giữa — giống hệt cách các trang báo,
// Netflix web, YouTube web vẫn làm.
//
// LayoutBuilder cho ta biết `constraints` (khoảng không gian
// tối đa mà widget cha cấp cho widget con) NGAY TẠI THỜI ĐIỂM
// build, để quyết định vẽ giao diện khác nhau tùy kích thước:
//   - Điện thoại / màn hẹp (< breakpoint): nội dung full-width.
//   - Máy tính / màn rộng (>= breakpoint): giới hạn maxWidth và
//     canh giữa bằng Center.
// ============================================================
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double breakpoint;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 900,
    this.breakpoint = 900,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= breakpoint;

        if (!isWideScreen) {
          // Màn hẹp (điện thoại): dùng toàn bộ chiều rộng sẵn có.
          return child;
        }

        // Màn rộng (web/tablet ngang): giới hạn chiều rộng + canh giữa.
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------
// Hàm tiện ích dùng ở nhiều nơi: tính số cột của một GridView
// dựa trên chiều rộng màn hình hiện có. Càng rộng, càng nhiều cột.
// Đây cũng là một cách làm Responsive UI phổ biến khác, áp dụng
// cho lưới ảnh (ví dụ màn Danh mục phim).
// ------------------------------------------------------------
int responsiveGridColumns(double width) {
  if (width >= 1200) return 6; // màn desktop rất rộng
  if (width >= 900) return 5; // desktop / laptop
  if (width >= 600) return 4; // tablet ngang
  return 2; // điện thoại
}
