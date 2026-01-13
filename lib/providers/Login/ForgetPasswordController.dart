import '../../models/Login/UserData.dart';

/// CONTROLLER LAYER
/// Handles business logic, validation, and coordination
/// No Firebase logic, no UI logic
class ForgetPasswordController {
  final UserData _user = UserData();

  /// Resets password for the provided email address
  /// Validates input and coordinates with model layer
  /// Returns true on success, false on failure
  Future<bool> reset(String email) async {
    // Validate email format and empty field
    if (!validateEmail(email)) {
      return false;
    }

    // Call model layer to handle Firebase logic
    final result = await _user.sendPasswordReset(email);
    return result;
  }

  /// Validates email format
  /// Returns true if email is valid, false otherwise
  bool validateEmail(String email) {
    // Check if email is empty
    if (email.trim().isEmpty) {
      return false;
    }

    // Validate email format using regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return emailRegex.hasMatch(email.trim());
  }
}
