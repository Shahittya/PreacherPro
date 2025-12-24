import 'package:flutter/material.dart';
import '../../providers/Registeration/OfficerRegisterController.dart';
import '../adminDashboard.dart';

class OfficerRegisterPage extends StatefulWidget {
  const OfficerRegisterPage({super.key});

  @override
  State<OfficerRegisterPage> createState() => _OfficerRegisterPageState();
}

class _OfficerRegisterPageState extends State<OfficerRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = OfficerRegisterController();

  // Text Controllers for form fields
  final _officerEmployeeIdController = TextEditingController();
  final _officerFullNameController = TextEditingController();
  final _officerEmailController = TextEditingController();
  final _officerContactController = TextEditingController();
  final _officerDepartmentController = TextEditingController();
  final _officerPositionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State variables
  String role = 'OFFICER'; // Fixed role
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _officerEmployeeIdController.dispose();
    _officerFullNameController.dispose();
    _officerEmailController.dispose();
    _officerContactController.dispose();
    _officerDepartmentController.dispose();
    _officerPositionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Main registration function - triggers controller
  Future<void> registerOfficer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Call controller's officerRegister() method
      Map<String, dynamic> result = await _controller.officerRegister(
        employeeId: _officerEmployeeIdController.text.trim(),
        fullName: _officerFullNameController.text.trim(),
        email: _officerEmailController.text.trim(),
        contact: _officerContactController.text.trim(),
        department: _officerDepartmentController.text.trim(),
        position: _officerPositionController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (result['success']) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Navigate back to admin dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Register MUIP Officer'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Icon(
                  Icons.person_add_alt_1,
                  size: 60,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Officer Registration',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a new MUIP officer account',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Employee ID Field
                _buildLabel('Employee ID'),
                TextFormField(
                  controller: _officerEmployeeIdController,
                  decoration: _buildInputDecoration('Enter employee ID'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter employee ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Full Name Field
                _buildLabel('Full Name'),
                TextFormField(
                  controller: _officerFullNameController,
                  decoration: _buildInputDecoration('Enter full name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter full name';
                    }
                    if (value.length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Field
                _buildLabel('Email Address'),
                TextFormField(
                  controller: _officerEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration('Enter email address'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Contact Field
                _buildLabel('Contact Number'),
                TextFormField(
                  controller: _officerContactController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration('Enter contact number'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter contact number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Department Field
                _buildLabel('Department'),
                TextFormField(
                  controller: _officerDepartmentController,
                  decoration: _buildInputDecoration('Enter department'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter department';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Position Field
                _buildLabel('Position'),
                TextFormField(
                  controller: _officerPositionController,
                  decoration: _buildInputDecoration('Enter position/title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter position';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                _buildLabel('Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _buildInputDecoration('Enter password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                _buildLabel('Confirm Password'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: _buildInputDecoration('Re-enter password')
                      .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Register Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : registerOfficer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'REGISTER OFFICER',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build label
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Helper method to build input decoration
  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
