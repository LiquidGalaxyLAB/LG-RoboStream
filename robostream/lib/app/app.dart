import 'package:flutter/material.dart';
import 'package:robostream/app/routes/app_router.dart'; // 1. Importar el router
import 'package:robostream/app/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RoboStream',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      // 2. Conectar la configuración del router a nuestra app
      routerConfig: AppRouter.router,
    );
  }
}