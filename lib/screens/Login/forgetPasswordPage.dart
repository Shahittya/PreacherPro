import 'package:flutter/material.dart';
import '../../providers/Login/ForgetPasswordController.dart';

/// UI LAYER
/// Handles user interface and user interactions
/// No Firebase logic, no business logic
class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  // Controller for managing email input
  final TextEditingController _emailController = TextEditingController();
  
  // Controller instance for handling business logic
  final ForgetPasswordController _controller = ForgetPasswordController();
  
  // State variables
  bool isRequesting = false;
  String userEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Handles the reset password action
  /// Validates input, calls controller, and displays result
  Future<void> onResetPassword() async {
    // Update state to show loading
    setState(() {
      isRequesting = true;
      userEmail = _emailController.text.trim();
    });

    // Check if email field is empty
    if (userEmail.isEmpty) {
      _showErrorMessage('Please enter your email address');
      setState(() {
        isRequesting = false;
      });
      return;
    }

    // Call controller to handle reset password logic
    final success = await _controller.reset(userEmail);

    // Update UI based on result
    setState(() {
      isRequesting = false;
    });

    if (success) {
      _showSuccessMessage('Password reset email sent! Please check your inbox.');
    } else {
      _showErrorMessage('Failed to send reset email. Please check your email address.');
    }
  }

  /// Displays success message using Snackbar
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Displays error message using Snackbar
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reset Password',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              const Text(
                'Reset Your Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Email Input Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isRequesting,
                decoration: const InputDecoration(
                  labelText: 'Registered Email Address',
                  hintText: 'admin@gmail.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: isRequesting ? null : onResetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isRequesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'SUBMIT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Back to Login Link
              TextButton(
                onPressed: isRequesting
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                child: const Text(
                  '← Back to Login',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
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
