import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentController {
  PaymentController._internal() {
    // initialize with fake pending data
    pending.value = [
      {
        'id': 'APP001',
        'preacher': 'John Doe',
        'preacherId': 'F-3001',
        'eventName': 'Friday Sermon',
        'date': '2025-10-21',
        'address': 'Central Mosque, Kuantan',
        'description': 'Short description about Friday Sermon activity',
        'status': 'Submitted',
        'viewed': false,
      },
      {
        'id': 'APP002',
        'preacher': 'Community Talk',
        'preacherId': 'F-3002',
        'eventName': 'Community Talk',
        'date': '2025-10-19',
        'address': 'Masjid Al-Falah',
        'description': 'Community Talk details',
        'status': 'Submitted',
        'viewed': false,
      },
    ];
    history.value = []; // start empty

    // initialize role from current auth session (NOT profile)
    _initRoleListener();
  }

  static final PaymentController _instance = PaymentController._internal();
  factory PaymentController() => _instance;

  final ValueNotifier<List<Map<String, dynamic>>> pending = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> history = ValueNotifier([]);

  /// Role read ONLY from authenticated session token claims (single source of truth).
  final ValueNotifier<String?> role = ValueNotifier(null);

  /// Track which Firebase UID the current `role.value` belongs to.
  String? _roleForUid;

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
      // Read role from token claims ONLY.
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

    final parsed = num.tryParse(amountStr.replaceAll(',', '')) ?? item['amount'];
    item['amount'] = parsed;

    final newHistory = List<Map<String, dynamic>>.from(history.value);
    newHistory.insert(0, item);
    history.value = newHistory;

    list.removeAt(index);
    pending.value = list;
  }

  void rejectPending(int index) {
    final list = List<Map<String, dynamic>>.from(pending.value);
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    pending.value = list;
  }

  void addToHistory(Map<String, dynamic> item) {
    final newHistory = List<Map<String, dynamic>>.from(history.value);
    newHistory.insert(0, Map<String, dynamic>.from(item));
    history.value = newHistory;
  }
}
