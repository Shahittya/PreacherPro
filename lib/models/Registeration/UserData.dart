import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// MODEL - Handles all database and Firebase operations
class UserData {
  final String? icNumber;
  final String fullName;
  final String email;
  final String contact;
  final String address;
  final String password;
  final String role;
  final String? district;
  final String? qualification;
  final File? profileImage;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserData({
    this.icNumber,
    required this.fullName,
    required this.email,
    required this.contact,
    required this.address,
    required this.password,
    required this.role,
    this.district,
    this.qualification,
    this.profileImage,
  });

  Map<String, dynamic> toMap() {
    return {
      'icNumber': icNumber,
      'fullName': fullName,
      'email': email,
      'contact': contact,
      'address': address,
      'password': password,
      'role': role,
      'district': district,
      'qualification': qualification,
      'profileImage': profileImage?.path,
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      icNumber: map['icNumber'],
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      contact: map['contact'] ?? '',
      address: map['address'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? '',
      district: map['district'],
      qualification: map['qualification'],
    );
  }

  // Register user in Firebase Auth and Firestore
  Future<Map<String, dynamic>> saveToDatabase() async {
    try {
      // Step 1: Create user with Firebase Authentication
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // Step 2: Create Firestore documents
      await _createFirestoreDocuments(uid);

      return {
        'success': true,
        'message': 'Registration successful! Awaiting approval.',
        'uid': uid,
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getAuthErrorMessage(e.code)};
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
        'role': 'PREACHER',
        'status': 'PENDING',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Document 2: preachers/{uid} - Preacher info and registration details
      DocumentReference preacherDoc = _firestore
          .collection('preachers')
          .doc(uid);
      batch.set(preacherDoc, {
        'fullName': fullName,
        'icNumber': icNumber,
        'phone': contact,
        'address': address,
        'district': district ?? '',
        'qualification': qualification ?? '',
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedBy': null,
        'reviewedAt': null,
        'rejectionReason': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Commit all documents at once
      await batch.commit();
    } catch (e) {
      // If Firestore write fails, delete the created auth user
      await _auth.currentUser?.delete();
      throw Exception('Failed to create user records: ${e.toString()}');
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
