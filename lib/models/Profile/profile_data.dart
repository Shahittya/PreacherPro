import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ProfileData Model - Handles all profile-related database operations
/// Following MVC architecture: View → Controller → Model (this file) → Firestore
class ProfileData {
  // Properties
  String fullName;
  String email;
  String phoneNumber;
  String address;
  String role;
  String district;
  String qualification;

  // Constructor
  ProfileData({
    this.fullName = '',
    this.email = '',
    this.phoneNumber = '',
    this.address = '',
    this.role = '',
    this.district = '',
    this.qualification = '',
  });

  // Firebase instances
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user's profile from Firestore
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        return {
          'success': false,
          'message': 'No user logged in',
        };
      }

      // Get user document from Firestore
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        return {
          'success': false,
          'message': 'User profile not found',
        };
      }

      final userData = userDoc.data()!;
      String email = userData['email'] ?? currentUser.email ?? '';
      String fullName = userData['name'] ?? '';
      String role = userData['role'] ?? '';
      String phoneNumber = '';
      String address = '';
      String district = '';
      String qualification = '';

      // Load additional details based on role
      if (role.toUpperCase() == 'PREACHER') {
        final preacherDoc = await _firestore.collection('preachers').doc(currentUser.uid).get();
        if (preacherDoc.exists) {
          final preacherData = preacherDoc.data()!;
          fullName = preacherData['fullName'] ?? fullName;
          phoneNumber = preacherData['phone'] ?? '';
          address = preacherData['address'] ?? '';
          district = preacherData['district'] ?? '';
          qualification = preacherData['qualification'] ?? '';
        }
      } else if (role.toUpperCase() == 'OFFICER') {
        final officerDoc = await _firestore.collection('officers').doc(currentUser.uid).get();
        if (officerDoc.exists) {
          final officerData = officerDoc.data()!;
          fullName = officerData['fullName'] ?? fullName;
          phoneNumber = officerData['phone'] ?? '';
          address = officerData['address'] ?? '';
        }
      } else if (role.toUpperCase() == 'ADMIN') {
        final adminDoc = await _firestore.collection('admins').doc(currentUser.uid).get();
        if (adminDoc.exists) {
          final adminData = adminDoc.data()!;
          fullName = adminData['fullName'] ?? fullName;
          phoneNumber = adminData['phone'] ?? '';
          address = adminData['address'] ?? '';
        }
      }

      return {
        'success': true,
        'email': email,
        'fullName': fullName,
        'role': role,
        'phoneNumber': phoneNumber,
        'address': address,
        'district': district,
        'qualification': qualification,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error loading profile: ${e.toString()}',
      };
    }
  }

  /// Update current user's profile in Firestore
  static Future<Map<String, dynamic>> updateUserProfile({
    required String fullName,
    required String phoneNumber,
    required String address,
    required String role,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        return {
          'success': false,
          'message': 'No user logged in',
        };
      }

      // Update user document
      await _firestore.collection('users').doc(currentUser.uid).update({
        'name': fullName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update role-specific collection
      if (role.toUpperCase() == 'PREACHER') {
        await _firestore.collection('preachers').doc(currentUser.uid).update({
          'fullName': fullName,
          'phone': phoneNumber,
          'address': address,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (role.toUpperCase() == 'OFFICER') {
        await _firestore.collection('officers').doc(currentUser.uid).update({
          'fullName': fullName,
          'phone': phoneNumber,
          'address': address,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (role.toUpperCase() == 'ADMIN') {
        await _firestore.collection('admins').doc(currentUser.uid).set({
          'fullName': fullName,
          'phone': phoneNumber,
          'address': address,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return {
        'success': true,
        'message': 'Profile updated successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update profile: ${e.toString()}',
      };
    }
  }

  /// Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'role': role,
      'district': district,
      'qualification': qualification,
    };
  }

  /// Create ProfileData from Map
  factory ProfileData.fromMap(Map<String, dynamic> map) {
    return ProfileData(
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      role: map['role'] ?? '',
      district: map['district'] ?? '',
      qualification: map['qualification'] ?? '',
    );
  }
}
