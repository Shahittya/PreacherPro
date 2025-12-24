import '../../models/Registeration/UserData.dart';

// CONTROLLER - Acts as provider, validates and orchestrates the flow
class UserRegisterationController {
  // Validate all input fields before registration
  Map<String, dynamic> validateRegister(UserData userData) {
    // Validate Full Name
    if (userData.fullName.isEmpty) {
      return {'valid': false, 'message': 'Full name is required'};
    }
    if (userData.fullName.length < 3) {
      return {
        'valid': false,
        'message': 'Full name must be at least 3 characters',
      };
    }

    // Validate IC Number
    if (userData.icNumber == null || userData.icNumber!.isEmpty) {
      return {'valid': false, 'message': 'IC number is required'};
    }

    // Validate Phone Number
    if (userData.contact.isEmpty) {
      return {'valid': false, 'message': 'Phone number is required'};
    }
    if (userData.contact.length < 10) {
      return {
        'valid': false,
        'message': 'Phone number must be at least 10 digits',
      };
    }

    // Validate Address
    if (userData.address.isEmpty) {
      return {'valid': false, 'message': 'Address is required'};
    }

    // Validate Email
    if (userData.email.isEmpty) {
      return {'valid': false, 'message': 'Email is required'};
    }
    if (!_isValidEmail(userData.email)) {
      return {'valid': false, 'message': 'Please enter a valid email address'};
    }

    // Validate Password
    if (userData.password.isEmpty) {
      return {'valid': false, 'message': 'Password is required'};
    }
    if (userData.password.length < 6) {
      return {
        'valid': false,
        'message': 'Password must be at least 6 characters',
      };
    }

    // All validations passed
    return {'valid': true, 'message': 'Validation successful'};
  }

  // Register user - orchestrates the registration process
  Future<Map<String, dynamic>> userRegister(UserData userData) async {
    // Validation happens here
    Map<String, dynamic> validation = validateRegister(userData);

    if (validation['valid'] != true) {
      return {
        'success': false,
        'message': validation['message'] ?? 'Validation failed',
      };
    }

    // Pass data to Model to handle database operations
    return await userData.saveToDatabase();
  }

  // Email validation helper
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
