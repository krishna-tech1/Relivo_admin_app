import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_frontend/services/auth_services.dart';
import 'package:admin_frontend/theme/app_theme.dart';

import 'package:admin_frontend/screens/admin_login_screen.dart';
import 'package:admin_frontend/screens/admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool isAdminApp; // Always true for this app, but keeping for compat
  const SplashScreen({super.key, this.isAdminApp = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Start navigation logic
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for 2 seconds and check login status simultaneously
    final results = await Future.wait([
      AuthService().isLoggedIn(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    final isLoggedIn = results[0] as bool;

    if (!mounted) return;

    // --- Admin App Flow ---
    if (isLoggedIn) {
       try {
         final user = await AuthService().getCurrentUser();
         if (!mounted) return;
         
         if (user != null && user['role'] == 'admin') {
           Navigator.pushReplacement(
             context,
             MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
           );
         } else {
           // Logged in but not admin
           await AuthService().logout();
           if (!mounted) return;
           Navigator.pushReplacement(
             context,
             MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
           );
         }
       } catch (e) {
         await AuthService().logout();
         if (!mounted) return;
         Navigator.pushReplacement(
           context,
           MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
         );
       }
    } else {
      Navigator.pushReplacement(
         context,
         MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.adminGradient,
          ),
          child: Stack(
            children: [
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo Icon
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 25,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // App Name "RELIVO ADMIN"
                        Text(
                          'RELIVO ADMIN',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'MANAGEMENT PORTAL',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 4.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Subtitle at bottom
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'SECURE ACCESS',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
