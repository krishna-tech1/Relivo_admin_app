import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:admin_frontend/widgets/custom_button.dart';
import 'package:admin_frontend/widgets/custom_text_field.dart';
import 'package:admin_frontend/services/auth_services.dart';
import 'package:admin_frontend/screens/admin_dashboard_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_frontend/theme/app_theme.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authService = AuthService();
        // Login
        await authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Verify Admin Role
        final user = await authService.getCurrentUser();
        
        if (mounted) {
          if (user['role'] == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
            );
          } else {
            // Not an admin
            await authService.logout();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Access Denied: This account does not have admin privileges.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login Failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
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
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: AppTheme.adminGradient,
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                    child: Column(
                      children: [
                        const Spacer(),
                        // Branding Section
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'RELIVO ADMIN',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Text(
                                'SECURE PORTAL',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.8),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        
                        // Login Card
                        Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Administrator Sign In',
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.secondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  CustomTextField(
                                    label: 'Admin Email',
                                    hint: 'Enter your email',
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'Password',
                                    hint: '••••••••',
                                    controller: _passwordController,
                                    isPassword: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 28),
                                  CustomButton(
                                    text: 'LOGIN',
                                    onPressed: _handleLogin,
                                    isLoading: _isLoading,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(flex: 2),
                        
                        // Footer
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Text(
                            '© 2026 RELIVO. ALL RIGHTS RESERVED.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
