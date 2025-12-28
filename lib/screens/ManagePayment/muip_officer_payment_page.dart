import 'package:flutter/material.dart';
import '../../providers/ManagePayment/payment_store.dart';
import 'officer_approve_payment_page.dart';

class MuipOfficerPaymentPage extends StatelessWidget {
  const MuipOfficerPaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = PaymentStore();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            tooltip: 'Approve payments',
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () {
              // navigate to the approve page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OfficerApprovePaymentPage()),
              );
            },
          )
        ],
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: store.history,
        builder: (context, hist, _) {
          if (hist.isEmpty) {
            return const Center(child: Text('No payment history yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12.0),
            itemCount: hist.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final p = hist[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.payment_outlined, color: Colors.black54),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${p['preacher']} — ${p['currency'] ?? ''} ${p['amount']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text('ID: ${p['id'] ?? p['preacherId']} · ${p['date']}', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Text(p['status'] ?? 'Approved', style: TextStyle(color: Colors.green.shade700)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
