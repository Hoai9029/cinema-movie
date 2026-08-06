import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cinema_movie/data/theme_mode_state.dart';
import 'package:cinema_movie/main.dart';
import 'package:cinema_movie/pages/profile_page.dart';

void main() {
  testWidgets('app shows the splash screen title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => ThemeModeState())],
        child: const MyApp(),
      ),
    );

    expect(find.text('CineStream'), findsOneWidget);
    expect(find.text('Xem phim mọi lúc, mọi nơi'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to continue'), findsOneWidget);
  });

  testWidgets('profile page contains a dark mode switch', (
    WidgetTester tester,
  ) async {
    final themeState = ThemeModeState();

    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeModeState>.value(
        value: themeState,
        child: const MaterialApp(home: ProfilePage()),
      ),
    );

    expect(find.byType(Switch), findsOneWidget);
    expect(themeState.isDark, isTrue);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(themeState.isDark, isFalse);
  });
}
