import '../../models/Registeration/OfficerData.dart';

// CONTROLLER - Validates officer registration data and orchestrates registration flow
class OfficerRegisterController {
  // Validate officer registration data
  Map<String, dynamic> validateOfficerRegister({
    required String employeeId,
    required String fullName,
    required String email,
    required String contact,
    required String department,
    required String position,
    required String password,
    required String confirmPassword,
  }) {
    // Validate Employee ID
    if (employeeId.isEmpty) {
      return {'valid': false, 'message': 'Employee ID is required'};
    }

    // Validate Full Name
    if (fullName.isEmpty) {
      return {'valid': false, 'message': 'Full name is required'};
    }
    if (fullName.length < 3) {
      return {'valid': false, 'message': 'Full name must be at least 3 characters'};
    }

    // Validate Email
    if (email.isEmpty) {
      return {'valid': false, 'message': 'Email is required'};
    }
    if (!_isValidEmail(email)) {
      return {'valid': false, 'message': 'Please enter a valid email address'};
    }

    // Validate Contact Number
    if (contact.isEmpty) {
      return {'valid': false, 'message': 'Contact number is required'};
    }
    if (!_isValidContact(contact)) {
      return {
        'valid': false,
        'message': 'Contact number must be 10-15 digits'
      };
    }

    // Validate Department
    if (department.isEmpty) {
      return {'valid': false, 'message': 'Department is required'};
    }

    // Validate Position
    if (position.isEmpty) {
      return {'valid': false, 'message': 'Position is required'};
    }

    // Validate Password
    if (password.isEmpty) {
      return {'valid': false, 'message': 'Password is required'};
    }
    if (password.length < 6) {
      return {
        'valid': false,
        'message': 'Password must be at least 6 characters'
      };
    }

    // Validate Confirm Password
    if (confirmPassword.isEmpty) {
      return {'valid': false, 'message': 'Please confirm your password'};
    }
    if (password != confirmPassword) {
      return {'valid': false, 'message': 'Passwords do not match'};
    }

    return {'valid': true, 'message': 'Validation successful'};
  }

  // Officer registration orchestration (called from View)
  Future<Map<String, dynamic>> officerRegister({
    required String employeeId,
    required String fullName,
    required String email,
    required String contact,
    required String department,
    required String position,
    required String password,
    required String confirmPassword,
  }) async {
    // Step 1: Validate all fields
    Map<String, dynamic> validation = validateOfficerRegister(
      employeeId: employeeId,
      fullName: fullName,
      email: email,
      contact: contact,
      department: department,
      position: position,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (!validation['valid']) {
      return validation;
    }

    // Step 2: Create OfficerData model
    OfficerData officer = OfficerData(
      employeeId: employeeId,
      fullName: fullName,
      email: email,
      contact: contact,
      department: department,
      position: position,
      password: password,
      role: 'OFFICER', // Fixed role
    );

    // Step 3: Pass to Model for Firebase operations
    return await officer.createOfficer();
  }

  // Email validation helper
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Contact number validation helper (10-15 digits)
  bool _isValidContact(String contact) {
    // Remove any spaces, dashes, or parentheses
    String cleanContact = contact.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^\d{10,15}$').hasMatch(cleanContact);
  }
}
