import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ActivityData.dart';

class PaymentController {
  PaymentController._internal() {
    // Initialize empty lists - data will be loaded from Firestore
    pending.value = [];
    approved.value = [];
    rejected.value = [];
    history.value = [];

    // initialize role from current auth session (NOT profile)
    _initRoleListener();
    
    // Load approved activities from Firestore
    _loadApprovedActivities();
  }

  static final PaymentController _instance = PaymentController._internal();
  factory PaymentController() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ValueNotifier<List<Map<String, dynamic>>> pending = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> history = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> approved = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> rejected = ValueNotifier([]);

  /// Role read ONLY from authenticated session token claims (single source of truth).
  final ValueNotifier<String?> role = ValueNotifier(null);

  /// Track which Firebase UID the current `role.value` belongs to.
  String? _roleForUid;

  /// Load payments from Firestore payments collection
  Future<void> _loadApprovedActivities() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      debugPrint('🔥 SETTING UP PAYMENTS LISTENER');
      debugPrint('   Collection: payments');
      
      // Listen to all payments in real-time
      _db.collection('payments')
          .snapshots()
          .listen((snapshot) {
        debugPrint('📡 PAYMENTS SNAPSHOT RECEIVED');
        debugPrint('   Document count: ${snapshot.docs.length}');
        
        final payments = <Map<String, dynamic>>[];
        
        for (var doc in snapshot.docs) {
          debugPrint('   📄 Payment doc: ${doc.id}');
          final data = doc.data();
          payments.add({
            'id': doc.id,
            'paymentId': doc.id,
            'docId': doc.id,
            'activityId': data['activityId'] ?? '',
            'preacher': data['preacherName'] ?? 'Unknown',
            'preacherId': data['preacherId'] ?? '',
            'eventName': data['eventName'] ?? '',
            'date': data['eventDate'] ?? '',
            'address': data['address'] ?? '',
            'description': data['description'] ?? '',
            'topic': data['topic'] ?? '',
            'status': data['status'] ?? 'pending',
            'adminStatus': data['status'] ?? 'pending', // Map status to adminStatus for compatibility
            'viewed': false,
            'amount': data['amount'] ?? 0.00,
            'currency': data['currency'] ?? 'RM',
            'requestedDate': data['requestedDate'],
            'approvedDate': data['approvedDate'],
            'rejectedDate': data['rejectedDate'],
            'officerId': data['officerId'] ?? '',
            'adminId': data['adminId'] ?? '',
          });
        }
        
        debugPrint('✅ Loaded ${payments.length} payments into pending.value');
        pending.value = payments;
      });
    } catch (e) {
      debugPrint('❌ Error loading payments: $e');
    }
  }

  /// Create a payment document when officer approves an activity
  Future<void> createPayment({
    required String activityId,
    required String preacherId,
    required String preacherName,
    required String eventName,
    required String eventDate,
    required String address,
    required String description,
    required String topic,
    required String status, // 'pending' or 'rejected_by_officer'
    required String officerId,
    double? amount,
  }) async {
    try {
      debugPrint('🔥 CREATING PAYMENT DOCUMENT IN FIRESTORE');
      debugPrint('   Collection: payments');
      debugPrint('   Activity ID: $activityId');
      debugPrint('   Preacher: $preacherName (ID: $preacherId)');
      debugPrint('   Status: $status');
      debugPrint('   Amount: ${amount ?? 0.00}');
      
      final docRef = await _db.collection('payments').add({
        'activityId': activityId,
        'preacherId': preacherId,
        'preacherName': preacherName,
        'eventName': eventName,
        'eventDate': eventDate,
        'address': address,
        'description': description,
        'topic': topic,
        'amount': amount ?? 0.00,
        'currency': 'RM',
        'status': status,
        'requestedDate': FieldValue.serverTimestamp(),
        'officerId': officerId,
      });
      
      debugPrint('✅ PAYMENT CREATED SUCCESSFULLY!');
      debugPrint('   Document ID: ${docRef.id}');
      debugPrint('   Path: payments/${docRef.id}');
    } catch (e) {
      debugPrint('❌ ERROR CREATING PAYMENT: $e');
      debugPrint('   Full error: ${e.toString()}');
    }
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

  /// Admin-specific approve method - updates payment status in Firestore
  Future<void> adminApproveById(String paymentId) async {
    try {
      await _db.collection('payments').doc(paymentId).update({
        'status': 'approved',
        'approvedDate': FieldValue.serverTimestamp(),
        'adminId': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
      debugPrint('Payment approved by admin: $paymentId');
    } catch (e) {
      debugPrint('Error approving payment: $e');
    }
  }
  
  /// Helper to remove item by ID from all lists
  void _removeItemById(String itemId) {
    pending.value = pending.value.where((item) => item['id'] != itemId).toList();
    approved.value = approved.value.where((item) => item['id'] != itemId).toList();
    rejected.value = rejected.value.where((item) => item['id'] != itemId).toList();
    history.value = history.value.where((item) => item['id'] != itemId).toList();
  }

  /// Admin-specific reject method - updates payment status in Firestore
  Future<void> adminRejectById(String paymentId) async {
    try {
      await _db.collection('payments').doc(paymentId).update({
        'status': 'rejected_by_admin',
        'rejectedDate': FieldValue.serverTimestamp(),
        'adminId': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
      debugPrint('Payment rejected by admin: $paymentId');
    } catch (e) {
      debugPrint('Error rejecting payment: $e');
    }
  }
}
