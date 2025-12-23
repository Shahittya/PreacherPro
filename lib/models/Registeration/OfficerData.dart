import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// MODEL - Handles all database and Firebase operations for Officer registration
class OfficerData {
  final String employeeId;
  final String fullName;
  final String email;
  final String contact;
  final String department;
  final String position;
  final String password;
  final String role;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  OfficerData({
    required this.employeeId,
    required this.fullName,
    required this.email,
    required this.contact,
    required this.department,
    required this.position,
    required this.password,
    required this.role,
  });

  // Convert OfficerData to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'fullName': fullName,
      'email': email,
      'contact': contact,
      'department': department,
      'position': position,
      'role': role,
    };
  }

  // Create OfficerData from Firestore Map
  factory OfficerData.fromMap(Map<String, dynamic> map) {
    return OfficerData(
      employeeId: map['employeeId'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      contact: map['contact'] ?? '',
      department: map['department'] ?? '',
      position: map['position'] ?? '',
      password: '', // Password not stored in Firestore
      role: map['role'] ?? 'OFFICER',
    );
  }

  // Register officer in Firebase Auth and Firestore
  Future<Map<String, dynamic>> createOfficer() async {
    try {
      // Step 1: Create officer with Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // Step 2: Create Firestore documents atomically
      await _createFirestoreDocuments(uid);

      return {
        'success': true,
        'message': 'Officer registered successfully!',
        'uid': uid,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }

  // Create all Firestore documents atomically
  Future<void> _createFirestoreDocuments(String uid) async {
    try {
      // Create batch write for atomic operation
      WriteBatch batch = _firestore.batch();

      // Document 1: users/{uid}
      DocumentReference userDoc = _firestore.collection('users').doc(uid);
      batch.set(userDoc, {
        'email': email,
        'name': fullName,
        'role': 'OFFICER',
        'status': 'ACTIVE',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Document 2: officers/{uid}
      DocumentReference officerDoc =
          _firestore.collection('officers').doc(uid);
      batch.set(officerDoc, {
        'employeeId': employeeId,
        'fullName': fullName,
        'email': email,
        'contact': contact,
        'department': department,
        'position': position,
        'hireDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Commit all documents at once
      await batch.commit();
    } catch (e) {
      // If Firestore write fails, delete the created auth user
      await _auth.currentUser?.delete();
      throw Exception('Failed to create officer records: ${e.toString()}');
    }
  }

  // Get Firebase Auth error messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'Registration failed. Please try again.';
    }
  }
}
