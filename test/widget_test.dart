import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_movie/bloc/theme/theme_bloc.dart';
import 'package:cinema_movie/bloc/watchlist/watchlist_bloc.dart';
import 'package:cinema_movie/main.dart';
import 'package:cinema_movie/pages/profile_page.dart';

void main() {
  testWidgets('app shows the splash screen title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeBloc()),
          BlocProvider(create: (_) => WatchlistBloc()),
        ],
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
    final themeBloc = ThemeBloc();
    addTearDown(themeBloc.close);

    await tester.pumpWidget(
      BlocProvider<ThemeBloc>.value(
        value: themeBloc,
        child: const MaterialApp(home: ProfilePage()),
      ),
    );

    expect(find.byType(Switch), findsOneWidget);
    expect(themeBloc.state.isDark, isTrue);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(themeBloc.state.isDark, isFalse);
  });
}
