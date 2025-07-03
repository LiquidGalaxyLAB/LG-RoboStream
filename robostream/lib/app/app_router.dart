import 'package:go_router/go_router.dart';
import 'package:robostream/app/login_screen.dart';
import 'package:robostream/app/home_screen.dart';

class AppRouter {
  AppRouter._();
  
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
}