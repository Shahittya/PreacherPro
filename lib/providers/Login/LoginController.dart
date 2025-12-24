import 'package:firebase_auth/firebase_auth.dart';
import '../../models/Login/User.dart' as UserModel;

// CONTROLLER - Validates credentials and orchestrates login flow
class LoginController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Logout user from Firebase
  Future<Map<String, dynamic>> logout() async {
    try {
      await _auth.signOut();
      return {'success': true, 'message': 'Logged out successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Logout failed: ${e.toString()}'};
    }
  }

  // Validate login credentials
  Map<String, dynamic> validateCredentials(
    String email,
    String password,
    String role,
  ) {
    // Validate Email
    if (email.isEmpty) {
      return {'valid': false, 'message': 'Email is required'};
    }
    if (!_isValidEmail(email)) {
      return {'valid': false, 'message': 'Please enter a valid email address'};
    }

    // Validate Password
    if (password.isEmpty) {
      return {'valid': false, 'message': 'Password is required'};
    }
    if (password.length < 6) {
      return {
        'valid': false,
        'message': 'Password must be at least 6 characters',
      };
    }

    // Validate Role
    if (role.isEmpty) {
      return {'valid': false, 'message': 'Please select a role'};
    }

    return {'valid': true, 'message': 'Validation successful'};
  }

  // Handle login process
  Future<Map<String, dynamic>> login(
    String email,
    String password,
    String role,
  ) async {
    // Step 1: Validate credentials
    Map<String, dynamic> validation = validateCredentials(
      email,
      password,
      role,
    );

    if (!validation['valid']) {
      return validation;
    }

    // Step 2: Create User model and attempt login
    UserModel.User user = UserModel.User(
      email: email,
      password: password,
      role: role,
    );

    // Step 3: Pass to Model for Firebase authentication
    return await user.login();
  }

  // Email validation helper
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
