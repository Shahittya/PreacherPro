import 'package:flutter/material.dart';
import '../../providers/Profile&Payment/payment_controller.dart';

class MuipOfficerPaymentPage extends StatelessWidget {
  const MuipOfficerPaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = PaymentController();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: store.history,
          builder: (context, historyList, _) {
            if (historyList.isEmpty) {
              return const Center(child: Text('No payment history yet'));
            }
            return ListView.builder(
              itemCount: historyList.length,
              itemBuilder: (context, index) {
                final item = historyList[index];
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
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8)
                                ),
                                child: const Icon(Icons.event, color: Colors.black54),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['preacher'] ?? '',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'ID: ${item['preacherId'] ?? item['id'] ?? ''} · ${item['date'] ?? ''}',
                                      style: const TextStyle(color: Colors.grey)
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12)
                                ),
                                child: Text(
                                  item['status'] ?? 'Approved',
                                  style: TextStyle(color: Colors.green.shade700)
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item['address'] ?? '',
                                  style: const TextStyle(color: Colors.grey)
                                )
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                '${item['currency'] ?? 'RM'} ${item['amount'] ?? '0'}',
                                style: const TextStyle(fontWeight: FontWeight.w600)
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                _showDetailModal(context, item);
                              },
                              child: const Text(
                                'View',
                                style: TextStyle(fontWeight: FontWeight.w600)
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        ),
      ),
    );
  }

  void _showDetailModal(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
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
                    Text(
                      'Payment Details',
                      style: Theme.of(context).textTheme.titleMedium
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)
                    ),
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
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: const Icon(Icons.event, color: Colors.black54),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['preacher'] ?? '',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'ID: ${item['preacherId'] ?? item['id'] ?? ''} · ${item['date'] ?? ''}',
                                    style: const TextStyle(color: Colors.grey)
                                  ),
                                ],
                              ),
                            ),
                            if (item['status'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12)
                                ),
                                child: Text(
                                  item['status'],
                                  style: TextStyle(color: Colors.green.shade700)
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item['address'] ?? '',
                                style: const TextStyle(color: Colors.grey)
                              )
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              '${item['currency'] ?? 'RM'} ${item['amount'] ?? '0'}',
                              style: const TextStyle(fontWeight: FontWeight.w600)
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Description',
                          style: TextStyle(fontWeight: FontWeight.w600)
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['description'] ?? 'No description available',
                          style: const TextStyle(color: Colors.black87)
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}