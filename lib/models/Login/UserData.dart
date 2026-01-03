import 'package:firebase_auth/firebase_auth.dart';

/// MODEL LAYER
/// Handles all Firebase Authentication logic
/// No UI logic, no validation logic
class UserData {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sends password reset email to the provided email address
  /// Returns true on success, false on failure
  /// Handles Firebase Authentication logic only
  Future<bool> sendPasswordReset(String email) async {
    try {
      // Send password reset email using Firebase Authentication
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      // Log the error for debugging purposes
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      // Catch any other unexpected errors
      print('Unexpected error: $e');
      return false;
    }
  }
}
