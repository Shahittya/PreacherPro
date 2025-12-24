import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';

// MODEL - Handles Firebase authentication and database operations
class User {
  final String email;
  final String password;
  final String role;

  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User({required this.email, required this.password, required this.role});

  // Login user with Firebase Authentication and verify role & status
  Future<Map<String, dynamic>> login() async {
    try {
      // Step 1: Authenticate with Firebase Auth
      auth.UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // Step 2: Verify user role and status in Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'User data not found. Please contact support.',
        };
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String userRole = userData['role'] ?? '';
      String userStatus = userData['status'] ?? '';

      // Step 3: Check if role matches
      if (userRole.toUpperCase() != role.toUpperCase()) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Invalid role selected. Please select the correct role.',
        };
      }

      // Step 4: Check status for PREACHER role only
      if (userRole.toUpperCase() == 'PREACHER') {
        if (userStatus == 'PENDING') {
          await _auth.signOut();
          return {
            'success': false,
            'message':
                'Your account is pending approval. Please wait for admin approval.',
          };
        } else if (userStatus == 'REJECTED') {
          await _auth.signOut();
          return {
            'success': false,
            'message':
                'Your account has been rejected. Please contact admin for more information.',
          };
        } else if (userStatus != 'ACTIVE') {
          await _auth.signOut();
          return {
            'success': false,
            'message': 'Your account is not active. Please contact admin.',
          };
        }
      }

      // Step 5: Login successful
      return {
        'success': true,
        'message': 'Login successful!',
        'uid': uid,
        'role': userRole,
        'name': userData['name'] ?? 'User',
      };
    } on auth.FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    }
  }

  // Get user-friendly error messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      default:
        return 'Login failed. Please check your credentials.';
    }
  }
}
