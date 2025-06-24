import 'package:flutter/material.dart';
import 'package:robostream/app/app_router.dart'; // 1. Importar el router
import 'package:robostream/assets/styles/app_styles.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RoboStream',
      theme: AppStyles.theme,
      debugShowCheckedModeBanner: false,
      // 2. Conectar la configuración del router a nuestra app
      routerConfig: AppRouter.router,
    );
  }
}