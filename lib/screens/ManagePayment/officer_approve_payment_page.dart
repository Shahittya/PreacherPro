import 'package:flutter/material.dart';
import '../../providers/Profile&Payment/payment_controller.dart';

class OfficerApprovePaymentPage extends StatefulWidget {
  const OfficerApprovePaymentPage({super.key});

  @override
  State<OfficerApprovePaymentPage> createState() => _OfficerApprovePaymentPageState();
}

class _OfficerApprovePaymentPageState extends State<OfficerApprovePaymentPage> {
  final store = PaymentController();

  void _approve(int index) {
    final id = store.pending.value[index]['id'];
    store.approvePending(index, store.pending.value[index]['amount']?.toString() ?? '0');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Approved $id')),
    );
  }

  void _reject(int index) {
    final id = store.pending.value[index]['id'];
    store.rejectPending(index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rejected $id')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preacher Approve Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: store.pending,
            builder: (context, allPending, _) {
              // Filter to show only Submitted status
              final pendingList = allPending.where((item) => 
                (item['status'] ?? '').toLowerCase() == 'submitted'
              ).toList();
              
              if (pendingList.isEmpty) return const Center(child: Text('No pending approvals'));
              return ListView.builder(
                itemCount: pendingList.length,
                itemBuilder: (context, index) {
                  final item = pendingList[index];
                  final viewed = item['viewed'] == true;
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
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  viewed ? '${item['currency'] ?? ''} ${item['amount']}' : '--',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                                child: TextButton(
                                onPressed: () async {
                                  // show detail as modal popup
                                  await _showDetailModal(context, item, index);
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
              );
            }),
      ),
    );
  }

  Future<void> _showDetailModal(BuildContext context, Map<String, dynamic> item, int displayIndex) async {
    // Find the actual index in the original pending list
    final actualIndex = store.pending.value.indexWhere((p) => p['id'] == item['id']);
    if (actualIndex == -1) return;
    
    store.markViewed(actualIndex);
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
                                  if (item['status'] != null)
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
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text('${item['currency'] ?? ''} ${item['amount']}', style: const TextStyle(fontWeight: FontWeight.w600)),
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
                        decoration: const InputDecoration(border: OutlineInputBorder(), prefixText: '₦ '),
                        onChanged: (_) => setStateModal(() {}),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: hasAmount
                                  ? () {
                                      // Find actual index in original pending list
                                      final actualIndex = store.pending.value.indexWhere((p) => p['id'] == item['id']);
                                      if (actualIndex != -1) {
                                        // approve and move to history
                                        store.approvePending(actualIndex, amountCtrl.text);
                                      }
                                      Navigator.pop(context);
                                    }
                                  : null,
                              child: const Text('Approve and Send'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
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
                                // Find actual index in original pending list
                                final actualIndex = store.pending.value.indexWhere((p) => p['id'] == item['id']);
                                if (actualIndex != -1) {
                                  store.rejectPending(actualIndex);
                                }
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Reject'),
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
}
