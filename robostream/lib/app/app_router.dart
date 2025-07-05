import 'package:go_router/go_router.dart';
import 'package:robostream/app/splash_screen.dart';
import 'package:robostream/app/login_screen.dart';
import 'package:robostream/app/home_screen.dart';

class AppRouter {
  AppRouter._();
  
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          final fromLogin = state.uri.queryParameters['fromLogin'] == 'true';
          return HomeScreen(fromLogin: fromLogin);
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
}