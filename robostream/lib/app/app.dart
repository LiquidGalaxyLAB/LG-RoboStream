import 'package:flutter/material.dart';
import 'package:robostream/app/app_router.dart';
import 'package:robostream/assets/styles/app_styles.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RoboStream',
      theme: AppStyles.theme,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}