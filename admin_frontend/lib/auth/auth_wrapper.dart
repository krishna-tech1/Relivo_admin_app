import 'package:flutter/material.dart';
import '../screens/landing_screen.dart';
import '../screens/home_screen.dart';
import '../services/auth_services.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return FutureBuilder<bool>(
      future: authService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.data == true) {
          return const HomeScreen();
        }
        
        return const LandingScreen();
      },
    );
  }
}
