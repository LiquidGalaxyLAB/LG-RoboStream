import 'package:go_router/go_router.dart';
// Importamos la nueva LoginScreen
import 'package:robostream/app/login_screen.dart';
import 'package:robostream/app/home_screen.dart';

class AppRouter {
  static final router = GoRouter(
    // La ruta inicial ahora es '/login'
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      // La ruta '/connect' ahora es '/login' y apunta a LoginScreen
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
}