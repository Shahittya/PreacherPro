import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentController {
  PaymentController._internal() {
    // Load initial mock data (will be replaced with database later)
    pending.value = _getInitialPendingPayments();
    approved.value = [];
    rejected.value = [];
    history.value = [];

    // initialize role from current auth session (NOT profile)
    _initRoleListener();
  }

  static final PaymentController _instance = PaymentController._internal();
  factory PaymentController() => _instance;

  final ValueNotifier<List<Map<String, dynamic>>> pending = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> history = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> approved = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> rejected = ValueNotifier([]);

  /// Role read ONLY from authenticated session token claims (single source of truth).
  final ValueNotifier<String?> role = ValueNotifier(null);

  /// Track which Firebase UID the current `role.value` belongs to.
  String? _roleForUid;

  /// Get initial mock payment data (temporary - will be replaced with database)
  List<Map<String, dynamic>> _getInitialPendingPayments() {
    return [
      {
        'id': 'APP001',
        'preacher': 'John Doe',
        'preacherId': 'F-3001',
        'eventName': 'Friday Sermon',
        'date': '2025-10-21',
        'address': 'Central Mosque, Kuantan',
        'description': 'test 1',
        'status': 'Submitted',
        'adminStatus': 'Pending',
        'viewed': false,
      },
      {
        'id': 'APP002',
        'preacher': 'Community Talk',
        'preacherId': 'F-3002',
        'eventName': 'Community Talk',
        'date': '2025-10-19',
        'address': 'Masjid Al-Falah',
        'description': 'test 2',
        'status': 'Submitted',
        'adminStatus': 'Pending',
        'viewed': false,
      },
      {
        'id': 'APP003',
        'preacher': 'yousef Talk',
        'preacherId': 'F-3003',
        'eventName': 'yousef Talk',
        'date': '2025-10-19',
        'address': 'Masjid Al-Falah',
        'description': 'test 3',
        'status': 'Submitted',
        'adminStatus': 'Pending',
        'viewed': false,
      }
    ];
  }

  void _initRoleListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      // IMPORTANT: clear role immediately so old user's role can never be reused.
      role.value = null;
      _roleForUid = null;

      if (user == null) return;

      await _loadRoleFromToken(user, forceRefresh: true);
    });

    // initial load if already signed in
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      // Clear first to avoid stale data.
      role.value = null;
      _roleForUid = null;
      _loadRoleFromToken(current, forceRefresh: true);
    }
  }

  Future<void> _loadRoleFromToken(User user, {required bool forceRefresh}) async {
    try {
      // Read role from token claims ONLY
      final idTokenResult = await user.getIdTokenResult(forceRefresh);
      final claims = idTokenResult.claims ?? {};
      final dynamic roleClaim = claims['role'];

      _roleForUid = user.uid;

      if (roleClaim is String && roleClaim.trim().isNotEmpty) {
        role.value = roleClaim.trim();
        return;
      }
    } catch (_) {
      // ignore and keep role null
    }

    // If claim missing / error
    _roleForUid = user.uid;
    role.value = null;
  }

  /// Returns role ONLY if it belongs to the CURRENT signed-in Firebase user.
  /// If the controller still holds an old user's role, this returns null.
  String? getLoggedInRoleSync() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    if (_roleForUid != user.uid) return null; // prevent stale role leak
    return role.value;
  }

  /// Force refresh role from token claims for the CURRENT user and return it.
  /// This is the safest method to call before navigation.
  Future<String?> refreshLoggedInRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      role.value = null;
      _roleForUid = null;
      return null;
    }

    // Clear first so UI never uses stale role during refresh.
    role.value = null;
    _roleForUid = null;

    await _loadRoleFromToken(user, forceRefresh: true);
    return getLoggedInRoleSync();
  }

  void markViewed(int index) {
    final list = List<Map<String, dynamic>>.from(pending.value);
    if (index >= 0 && index < list.length) {
      list[index] = Map<String, dynamic>.from(list[index]);
      list[index]['viewed'] = true;
      pending.value = list;
    }
  }

  void approvePending(int index, String amountStr) {
    final list = List<Map<String, dynamic>>.from(pending.value);
    if (index < 0 || index >= list.length) return;

    final item = Map<String, dynamic>.from(list[index]);
    item['status'] = 'Approved';
    // Initialize adminStatus if not present
    if (!item.containsKey('adminStatus')) {
      item['adminStatus'] = 'Pending';
    }

    final parsed = num.tryParse(amountStr.replaceAll(',', '')) ?? item['amount'];
    item['amount'] = parsed;

    // Add to both history and approved lists
    final newHistory = List<Map<String, dynamic>>.from(history.value);
    newHistory.insert(0, item);
    history.value = newHistory;

    final newApproved = List<Map<String, dynamic>>.from(approved.value);
    newApproved.insert(0, item);
    approved.value = newApproved;

    list.removeAt(index);
    pending.value = list;
  }

  void rejectPending(int index, {String reason = ''}) {
    final list = List<Map<String, dynamic>>.from(pending.value);
    if (index < 0 || index >= list.length) return;

    final item = Map<String, dynamic>.from(list[index]);
    item['status'] = 'Rejected';
    // Initialize adminStatus if not present
    if (!item.containsKey('adminStatus')) {
      item['adminStatus'] = 'Pending';
    }
    if (reason.isNotEmpty) {
      item['rejectionReason'] = reason;
    }

    // Add to both history and rejected lists
    final newHistory = List<Map<String, dynamic>>.from(history.value);
    newHistory.insert(0, item);
    history.value = newHistory;

    final newRejected = List<Map<String, dynamic>>.from(rejected.value);
    newRejected.insert(0, item);
    rejected.value = newRejected;

    list.removeAt(index);
    pending.value = list;
  }

  void addToHistory(Map<String, dynamic> item) {
    final newHistory = List<Map<String, dynamic>>.from(history.value);
    newHistory.insert(0, Map<String, dynamic>.from(item));
    history.value = newHistory;
  }

  /// Admin-specific approve method - updates adminStatus field
  void adminApproveById(String itemId) {
    // Find item across all lists by ID
    Map<String, dynamic>? foundItem;
    
    for (var item in [...pending.value, ...approved.value, ...rejected.value, ...history.value]) {
      if (item['id'] == itemId) {
        foundItem = Map<String, dynamic>.from(item);
        break;
      }
    }
    
    if (foundItem == null) return;
    
    // Update adminStatus
    foundItem['adminStatus'] = 'Approved';
    
    // Remove from all existing lists
    _removeItemById(itemId);
    
    // Add only to history list (single source)
    final newHistory = List<Map<String, dynamic>>.from(history.value);
    newHistory.insert(0, foundItem);
    history.value = newHistory;
  }
  
  /// Helper to remove item by ID from all lists
  void _removeItemById(String itemId) {
    pending.value = pending.value.where((item) => item['id'] != itemId).toList();
    approved.value = approved.value.where((item) => item['id'] != itemId).toList();
    rejected.value = rejected.value.where((item) => item['id'] != itemId).toList();
    history.value = history.value.where((item) => item['id'] != itemId).toList();
  }

  /// Admin-specific reject method - updates adminStatus field
  void adminRejectById(String itemId, {String reason = ''}) {
    // Find item across all lists by ID
    Map<String, dynamic>? foundItem;
    
    for (var item in [...pending.value, ...approved.value, ...rejected.value, ...history.value]) {
      if (item['id'] == itemId) {
        foundItem = Map<String, dynamic>.from(item);
        break;
      }
    }
    
    if (foundItem == null) return;
    
    // Update adminStatus
    foundItem['adminStatus'] = 'Rejected';
    if (reason.isNotEmpty) {
      foundItem['adminRejectionReason'] = reason;
    }
    
    // Remove from all existing lists
    _removeItemById(itemId);
    
    // Add only to history list (single source)
    final newHistory = List<Map<String, dynamic>>.from(history.value);
    newHistory.insert(0, foundItem);
    history.value = newHistory;
  }
}
