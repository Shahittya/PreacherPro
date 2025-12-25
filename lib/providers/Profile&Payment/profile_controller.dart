import 'package:flutter/material.dart';
import '../../models/Profile/profile_data.dart';

class ProfileController extends ChangeNotifier {
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
        return Colors.blue;
      case 'OFFICER':
        return Colors.amber.shade300; // Light yellow
      case 'PREACHER':
        return Colors.lightGreen;
      default:
        return Colors.blue;
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

  // Load current user profile using ProfileData model
  Future<void> loadCurrentUserProfile() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      // Call ProfileData model to get profile data (MVC pattern)
      Map<String, dynamic> result = await ProfileData.getUserProfile();

      if (result['success'] == true) {
        _email = result['email'] ?? '';
        _fullName = result['fullName'] ?? '';
        _role = result['role'] ?? '';
        _phoneNumber = result['phoneNumber'] ?? '';
        _address = result['address'] ?? '';
        _district = result['district'] ?? '';
        _qualification = result['qualification'] ?? '';
      } else {
        throw Exception(result['message']);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update current user profile using ProfileData model
  Future<Map<String, dynamic>> updateCurrentUserProfile({
    required String fullName,
    required String phoneNumber,
    required String address,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Call ProfileData model to update profile (MVC pattern)
      Map<String, dynamic> result = await ProfileData.updateUserProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        address: address,
        role: _role,
      );

      if (result['success'] == true) {
        // Update local state
        _fullName = fullName;
        _phoneNumber = phoneNumber;
        _address = address;
      }

      _isLoading = false;
      notifyListeners();

      return result;
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
