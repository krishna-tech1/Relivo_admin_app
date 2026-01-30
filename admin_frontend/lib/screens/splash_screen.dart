import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Stack(
        children: [
          // Background Gradient or Subtle Decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

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
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.volunteer_activism_rounded,
                        size: 60,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // App Name "Relivo"
                    Text(
                      'Relivo',
                      style: GoogleFonts.inter(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin Portal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.mediumGray,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
