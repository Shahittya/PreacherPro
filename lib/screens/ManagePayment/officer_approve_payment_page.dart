import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/Profile&Payment/payment_controller.dart';
import '../../models/ActivityData.dart';
import 'payment_page.dart';

class OfficerApprovePaymentPage extends StatefulWidget {
  const OfficerApprovePaymentPage({super.key});

  @override
  State<OfficerApprovePaymentPage> createState() => _OfficerApprovePaymentPageState();
}

class _OfficerApprovePaymentPageState extends State<OfficerApprovePaymentPage> {
  final store = PaymentController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _approvedActivities = [];

  @override
  void initState() {
    super.initState();
    _loadApprovedActivities();
  }

  /// Load activities with status='approved' from Firestore
  void _loadApprovedActivities() {
    _db.collection('activities')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .listen((snapshot) async {
      final activities = <Map<String, dynamic>>[];
      
      // Get all existing payment activity IDs to filter out
      final paymentsSnapshot = await _db.collection('payments').get();
      final processedActivityIds = paymentsSnapshot.docs
          .map((doc) => doc.data()['activityId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      
      for (var doc in snapshot.docs) {
        final activity = ActivityData.fromDoc(doc);
        await activity.fetchDetails();
        
        // Only show activities that don't have a payment yet
        if (activity.assignment != null && 
            !processedActivityIds.contains(activity.activityId.toString())) {
          activities.add({
            'id': activity.activityId.toString(),
            'docId': activity.docId,
            'activityId': activity.activityId,
            'preacher': activity.preacherName ?? 'Unknown',
            'preacherId': activity.assignment!.preacherId,
            'eventName': activity.title,
            'date': activity.activityDate,
            'address': activity.locationAddress,
            'description': activity.description,
            'topic': activity.topic,
            'status': 'Submitted',
            'viewed': false,
            'amount': 0.00,
            'currency': 'RM',
          });
        }
      }
      
      if (mounted) {
        setState(() {
          _approvedActivities = activities;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approve Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _approvedActivities.isEmpty
            ? const Center(child: Text('No approved activities awaiting payment'))
            : ListView.builder(
                itemCount: _approvedActivities.length,
                itemBuilder: (context, index) {
                  final item = _approvedActivities[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.event, color: Colors.black54),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['preacher'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 6),
                                      Text('ID: ${item['preacherId']} · ${item['date']}', style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                                  child: Text(item['status'], style: TextStyle(color: Colors.green.shade700)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(child: Text(item['address'], style: const TextStyle(color: Colors.grey))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () async {
                                  await _showDetailModal(context, item);
                                },
                                child: const Text('View', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _showDetailModal(BuildContext context, Map<String, dynamic> item) async {
    final TextEditingController amountCtrl = TextEditingController();
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setStateModal) {
              final hasAmount = amountCtrl.text.trim().isNotEmpty;
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 8),
                          Text('Payment Details', style: Theme.of(context).textTheme.titleMedium),
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                        ],
                      ),
                      const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.event, color: Colors.black54),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['preacher'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 6),
                                  Text('ID: ${item['preacherId']} · ${item['date']}', style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                              child: Text(item['status'], style: TextStyle(color: Colors.green.shade700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(child: Text(item['address'], style: const TextStyle(color: Colors.grey))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Description', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(item['description'] ?? '', style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Amount to send', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixText: 'RM ',
                  ),
                  onChanged: (_) => setStateModal(() {}),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: hasAmount
                            ? () {
                                Navigator.pop(context);
                                _handleApprove(item, amountCtrl.text);
                              }
                            : null,
                        child: const Text('Approve and Send'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Reject report'),
                              content: const Text('Are you sure you want to reject this payment report?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reject', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            Navigator.pop(context);
                            _handleReject(item);
                          }
                        },
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _handleApprove(Map<String, dynamic> item, String amountStr) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Parse amount
    final amount = num.tryParse(amountStr.replaceAll(',', ''))?.toDouble() ?? 0.00;

    // Create payment document with status 'pending'
    await store.createPayment(
      activityId: item['activityId'].toString(),
      preacherId: item['preacherId'],
      preacherName: item['preacher'],
      eventName: item['eventName'],
      eventDate: item['date'],
      address: item['address'],
      description: item['description'] ?? '',
      topic: item['topic'] ?? '',
      status: 'pending',
      officerId: currentUser.uid,
      amount: amount,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment approved and sent to admin'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleReject(Map<String, dynamic> item) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reject Payment'),
          content: const Text('Are you sure you want to reject this payment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Create payment document with status 'rejected_by_officer'
    await store.createPayment(
      activityId: item['activityId'].toString(),
      preacherId: item['preacherId'],
      preacherName: item['preacher'],
      eventName: item['eventName'],
      eventDate: item['date'],
      address: item['address'],
      description: item['description'] ?? '',
      topic: item['topic'] ?? '',
      status: 'rejected_by_officer',
      officerId: currentUser.uid,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment rejected'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
