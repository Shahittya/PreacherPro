import 'package:flutter/material.dart';

class PaymentStore {
  PaymentStore._internal() {
    // initialize with fake pending data
    pending.value = [
      {
        'id': 'APP001',
        'preacher': 'John Doe',
        'preacherId': 'F-3001',
        'eventName': 'Friday Sermon',
        'date': '2025-10-21',
        'address': 'Central Mosque, Kuantan',
        'amount': 200,
        'currency': 'RM',
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
        'amount': 150,
        'currency': 'RM',
        'description': 'Community Talk details',
        'status': 'Submitted',
        'viewed': false,
      },
    ];
    history.value = []; // start empty
  }

  static final PaymentStore _instance = PaymentStore._internal();
  factory PaymentStore() => _instance;

  final ValueNotifier<List<Map<String, dynamic>>> pending = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> history = ValueNotifier([]);

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
    // set approved and amount
    item['status'] = 'Approved';
    // parse amount
    final parsed = num.tryParse(amountStr.replaceAll(',', '')) ?? item['amount'];
    item['amount'] = parsed;

    // add to history
    final newHistory = List<Map<String, dynamic>>.from(history.value);
    newHistory.insert(0, item);
    history.value = newHistory;

    // remove from pending
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
