import 'package:flutter/material.dart';
import 'package:admin_frontend/services/auth_services.dart';
import 'package:admin_frontend/widgets/custom_button.dart';
import 'package:admin_frontend/widgets/custom_text_field.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _handleReset() async {
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the verification code')),
      );
      return;
    }
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a new password')),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(
        email: widget.email,
        code: _codeController.text.trim(),
        newPassword: _passwordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully! Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create New Password',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the code sent to ${widget.email} and your new password.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            CustomTextField(
              label: 'Verification Code',
              hint: 'Enter 6-digit code',
              controller: _codeController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'New Password',
              hint: 'Enter your new password',
              controller: _passwordController,
              isPassword: true,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Confirm New Password',
              hint: 'Re-enter your new password',
              controller: _confirmPasswordController,
              isPassword: true,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Reset Password',
              onPressed: _handleReset,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
