import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../pages/splash_page.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/movie_detail_page.dart';
import '../pages/watch_page.dart';
import '../models/movie.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const movie = '/movie'; // dynamic: /movie/:id
  static const watch = '/watch'; // dynamic: /watch/:id
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final name = settings.name ?? '';
    final args = settings.arguments;
    final isAuth = firebase_auth.FirebaseAuth.instance.currentUser != null;

    // Static routes
    if (name == AppRoutes.splash) {
      return MaterialPageRoute(builder: (_) => const SplashPage());
    }

    if (name == AppRoutes.login) {
      return MaterialPageRoute(builder: (_) => const LoginPage());
    }

    if (name == AppRoutes.home) {
      if (!isAuth) return MaterialPageRoute(builder: (_) => const LoginPage());
      return MaterialPageRoute(builder: (_) => const HomePage());
    }

    // Dynamic movie route: /movie/:id
    if (name.startsWith('${AppRoutes.movie}/')) {
      final id = name.split('/').last;
      if (args is Movie) {
        return MaterialPageRoute(builder: (_) => MovieDetailPage(movie: args));
      }
      return _unknownRoute('Movie not found: $id');
    }

    // Dynamic watch route: /watch/:id
    if (name.startsWith('${AppRoutes.watch}/')) {
      final id = name.split('/').last;
      if (args is Movie) {
        return MaterialPageRoute(builder: (_) => WatchPage(movie: args));
      }
      return _unknownRoute('Movie not found: $id');
    }

    // Allow calling /movie or /watch with Movie argument
    if (name == AppRoutes.movie && args is Movie) {
      return MaterialPageRoute(builder: (_) => MovieDetailPage(movie: args));
    }

    if (name == AppRoutes.watch && args is Movie) {
      return MaterialPageRoute(builder: (_) => WatchPage(movie: args));
    }

    return _unknownRoute('Unknown route: $name');
  }

  static MaterialPageRoute _unknownRoute(String message) => MaterialPageRoute(
    builder: (_) => Scaffold(body: Center(child: Text(message))),
  );
}
