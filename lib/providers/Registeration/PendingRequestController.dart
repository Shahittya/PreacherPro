import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/Registeration/pendingRequestData.dart';

class PendingRequestController extends ChangeNotifier {
  final PendingRequestData _model = PendingRequestData();

  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _pendingPreachers = [];
  Map<String, dynamic>? _selectedPreacher;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get pendingPreachers => _pendingPreachers;
  Map<String, dynamic>? get selectedPreacher => _selectedPreacher;

  /// Load all pending preacher registration requests
  Future<void> loadPendingRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic> result = await _model.getPendingPreachers();

      if (result['success']) {
        _pendingPreachers = List<Map<String, dynamic>>.from(
          result['preachers'],
        );
        _errorMessage = null;
      } else {
        _errorMessage = result['message'];
      }
    } catch (e) {
      _errorMessage = 'Error loading pending requests: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// View details of a specific preacher request
  /// Returns 0 on success, -1 on failure
  Future<int> viewRequest(String preacherId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic> result = await _model.getPreacherDetails(preacherId);

      if (result['success']) {
        _selectedPreacher = result['preacher'];
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return 0; // Success
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return -1; // Failure
      }
    } catch (e) {
      _errorMessage = 'Error viewing request: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return -1; // Failure
    }
  }

  /// Approve a preacher registration request
  /// Returns 0 on success, -1 on failure
  Future<int> approveRequest(String preacherId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get current admin UID from Firebase Auth
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _errorMessage = 'Admin not authenticated';
        _isLoading = false;
        notifyListeners();
        return -1;
      }

      String adminUid = currentUser.uid;

      await _model.approvePreacherRequest(preacherId, adminUid);

      // Refresh the pending list
      await loadPendingRequests();

      _selectedPreacher = null; // Clear selected preacher
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return 0; // Success
    } catch (e) {
      _errorMessage = 'Error approving request: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return -1; // Failure
    }
  }

  /// Reject a preacher registration request with a reason
  /// Returns 0 on success, -1 on failure
  Future<int> rejectRequest(String preacherId, String rejectionReason) async {
    if (rejectionReason.trim().isEmpty) {
      _errorMessage = 'Rejection reason is required';
      notifyListeners();
      return -1; // Failure
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get current admin UID from Firebase Auth
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _errorMessage = 'Admin not authenticated';
        _isLoading = false;
        notifyListeners();
        return -1;
      }

      String adminUid = currentUser.uid;

      await _model.rejectPreacherRequest(preacherId, adminUid, rejectionReason);

      // Refresh the pending list
      await loadPendingRequests();

      _selectedPreacher = null; // Clear selected preacher
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return 0; // Success
    } catch (e) {
      _errorMessage = 'Error rejecting request: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return -1; // Failure
    }
  }

  /// Clear the selected preacher
  void clearSelectedPreacher() {
    _selectedPreacher = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
