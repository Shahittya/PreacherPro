import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/Profile/profile_data.dart';

class ProfileController extends ChangeNotifier {
  // Firebase instances
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Properties matching UML diagram
  String _fullName = '';
  String _email = '';
  String _phoneNumber = '';
  String _address = '';
  String _role = '';
  String _district = '';
  String _qualification = '';
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Getters
  String get fullName => _fullName;
  String get email => _email;
  String get phoneNumber => _phoneNumber;
  String get address => _address;
  String get role => _role;
  String get district => _district;
  String get qualification => _qualification;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  // Get role-based color
  Color getRoleColor() {
    switch (_role.toUpperCase()) {
      case 'ADMIN':
        return Colors.deepPurple;
      case 'OFFICER':
        return Colors.amber.shade300; // Light yellow
      case 'PREACHER':
        return Colors.lightGreen;
      default:
        return Colors.deepPurple;
    }
  }

  // Get role display name
  String getRoleDisplayName() {
    switch (_role.toUpperCase()) {
      case 'ADMIN':
        return 'MUIP Admin';
      case 'OFFICER':
        return 'MUIP Officer';
      case 'PREACHER':
        return 'Preacher';
      default:
        return 'User';
    }
  }

  // Load current user profile from Firestore
  Future<void> loadCurrentUserProfile() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Get user document from Firestore
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final userData = userDoc.data()!;
      _email = userData['email'] ?? currentUser.email ?? '';
      _fullName = userData['name'] ?? '';
      _role = userData['role'] ?? '';
      String phoneNumber = '';
      String address = '';
      String district = '';
      String qualification = '';

      // Load additional details based on role
      if (_role.toUpperCase() == 'PREACHER') {
        final preacherDoc = await _firestore.collection('preachers').doc(currentUser.uid).get();
        if (preacherDoc.exists) {
          final preacherData = preacherDoc.data()!;
          _fullName = preacherData['fullName'] ?? _fullName;
          phoneNumber = preacherData['phone'] ?? '';
          address = preacherData['address'] ?? '';
          district = preacherData['district'] ?? '';
          qualification = preacherData['qualification'] ?? '';
        }
      } else if (_role.toUpperCase() == 'OFFICER') {
        final officerDoc = await _firestore.collection('officers').doc(currentUser.uid).get();
        if (officerDoc.exists) {
          final officerData = officerDoc.data()!;
          _fullName = officerData['fullName'] ?? _fullName;
          phoneNumber = officerData['phone'] ?? '';
          address = officerData['address'] ?? '';
        }
      } else if (_role.toUpperCase() == 'ADMIN') {
        final adminDoc = await _firestore.collection('admins').doc(currentUser.uid).get();
        if (adminDoc.exists) {
          final adminData = adminDoc.data()!;
          _fullName = adminData['fullName'] ?? _fullName;
          phoneNumber = adminData['phone'] ?? '';
          address = adminData['address'] ?? '';
        }
      }

      _phoneNumber = phoneNumber;
      _address = address;
      _district = district;
      _qualification = qualification;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update current user profile in Firestore
  Future<Map<String, dynamic>> updateCurrentUserProfile({
    required String fullName,
    required String phoneNumber,
    required String address,
  }) async {
    _isLoading = true;
    notifyListeners();

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
      if (_role.toUpperCase() == 'PREACHER') {
        await _firestore.collection('preachers').doc(currentUser.uid).update({
          'fullName': fullName,
          'phone': phoneNumber,
          'address': address,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (_role.toUpperCase() == 'OFFICER') {
        await _firestore.collection('officers').doc(currentUser.uid).update({
          'fullName': fullName,
          'phone': phoneNumber,
          'address': address,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (_role.toUpperCase() == 'ADMIN') {
        await _firestore.collection('admins').doc(currentUser.uid).set({
          'fullName': fullName,
          'phone': phoneNumber,
          'address': address,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Update local state
      _fullName = fullName;
      _phoneNumber = phoneNumber;
      _address = address;

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'message': 'Profile updated successfully!',
      };
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      return {
        'success': false,
        'message': 'Failed to update profile: ${e.toString()}',
      };
    }
  }

  // Clear profile data (on logout)
  void clearProfile() {
    _fullName = '';
    _email = '';
    _phoneNumber = '';
    _address = '';
    _role = '';
    _district = '';
    _qualification = '';
    _isLoading = false;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }
}
