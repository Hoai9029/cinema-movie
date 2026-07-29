import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_movie/main.dart';

void main() {
  testWidgets('app shows the splash screen title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('CineStream'), findsOneWidget);
    expect(find.text('Xem phim mọi lúc, mọi nơi'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });
}
