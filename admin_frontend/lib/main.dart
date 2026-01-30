import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure system UI to show status bar globally
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
  
  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const MyAdminApp());
}

class MyAdminApp extends StatelessWidget {
  const MyAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Explicitly enforce system UI style at the root level
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, 
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light, 
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        title: 'Relivo Admin',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        // Launch into Splash Screen with Admin Mode flag
        home: const SplashScreen(isAdminApp: true),
      ),
    );
  }
}
