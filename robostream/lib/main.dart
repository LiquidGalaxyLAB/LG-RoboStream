import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:robostream/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure system UI for better visual experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const App());
}