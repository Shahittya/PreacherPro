import 'package:flutter/material.dart';
import '../../providers/Profile&Payment/payment_controller.dart';

class MuipAdminPaymentPage extends StatefulWidget {
  const MuipAdminPaymentPage({super.key});

  @override
  State<MuipAdminPaymentPage> createState() => _MuipAdminPaymentPageState();
}

class _MuipAdminPaymentPageState extends State<MuipAdminPaymentPage> with SingleTickerProviderStateMixin {
  final store = PaymentController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
      case 'submitted':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green.shade50;
      case 'pending':
      case 'submitted':
        return Colors.orange.shade50;
      case 'rejected':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Widget _buildPaymentCard(Map<String, dynamic> item, bool showViewButton) {
    // For admin page, display adminStatus instead of officer status
    final displayStatus = item['adminStatus'] ?? 'Pending';
    
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
                      color: _getStatusColor(displayStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.event,
                      color: _getStatusColor(displayStatus),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['eventName'] ?? item['preacher'] ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Date: ${item['date']}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusBackgroundColor(displayStatus),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      displayStatus,
                      style: TextStyle(
                        color: _getStatusColor(displayStatus),
                        fontWeight: FontWeight.w600,
                      ),
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
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${item['currency'] ?? 'RM'} ${item['amount'] ?? '0.00'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (showViewButton) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _showDetailModal(context, item);
                    },
                    child: const Text(
                      'View',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getPendingPayments() {
    // Admin pending tab shows items approved by officer (status='approved') but not yet processed by admin (adminStatus='pending')
    final allItems = [...store.pending.value, ...store.approved.value, ...store.rejected.value, ...store.history.value];
    final filtered = allItems.where((item) {
      final status = (item['status'] ?? '').toLowerCase();
      final adminStatus = (item['adminStatus'] ?? 'pending').toLowerCase();
      return status == 'approved' && adminStatus == 'pending';
    }).toList();
    
    // Deduplicate by ID
    final seen = <String>{};
    return filtered.where((item) {
      final id = item['id']?.toString() ?? '';
      if (seen.contains(id)) return false;
      seen.add(id);
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _getApprovedPayments() {
    // Admin approved tab shows items approved by admin (adminStatus='approved')
    final allItems = [...store.pending.value, ...store.approved.value, ...store.rejected.value, ...store.history.value];
    final filtered = allItems.where((item) => 
      (item['adminStatus'] ?? '').toLowerCase() == 'approved'
    ).toList();
    
    // Deduplicate by ID
    final seen = <String>{};
    return filtered.where((item) {
      final id = item['id']?.toString() ?? '';
      if (seen.contains(id)) return false;
      seen.add(id);
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _getRejectedPayments() {
    // Admin rejected tab shows items rejected by admin (adminStatus='rejected')
    final allItems = [...store.pending.value, ...store.approved.value, ...store.rejected.value, ...store.history.value];
    final filtered = allItems.where((item) => 
      (item['adminStatus'] ?? '').toLowerCase() == 'rejected'
    ).toList();
    
    // Deduplicate by ID
    final seen = <String>{};
    return filtered.where((item) {
      final id = item['id']?.toString() ?? '';
      if (seen.contains(id)) return false;
      seen.add(id);
      return true;
    }).toList();
  }

  Widget _buildTabContent(List<Map<String, dynamic>> payments, String emptyMessage) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        return _buildPaymentCard(payments[index], true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Payment'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: store.pending,
        builder: (context, _, __) {
          return ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: store.approved,
            builder: (context, __, ___) {
              return ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: store.rejected,
                builder: (context, ___, ____) {
                  return ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: store.history,
                    builder: (context, ____, _____) {
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTabContent(_getPendingPayments(), 'No pending payments'),
                          _buildTabContent(_getApprovedPayments(), 'No approved payments'),
                          _buildTabContent(_getRejectedPayments(), 'No rejected payments'),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showDetailModal(BuildContext context, Map<String, dynamic> item) {
    // Check if this is a pending payment for admin (officer approved but admin hasn't processed yet)
    final status = (item['status'] ?? '').toLowerCase();
    final adminStatus = (item['adminStatus'] ?? 'pending').toLowerCase();
    final isPending = status == 'approved' && adminStatus == 'pending';
    
    // For admin modal, display adminStatus
    final displayStatus = item['adminStatus'] ?? 'Pending';
    
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
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
                                color: _getStatusColor(displayStatus).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.event,
                                color: _getStatusColor(displayStatus),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['eventName'] ?? item['preacher'] ?? '',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Date: ${item['date']}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusBackgroundColor(displayStatus),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                displayStatus,
                                style: TextStyle(
                                  color: _getStatusColor(displayStatus),
                                  fontWeight: FontWeight.w600,
                                ),
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
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              '${item['currency'] ?? 'RM'} ${item['amount'] ?? '0.00'}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Description',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['description'] ?? 'No description available',
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
                // Action buttons for pending payments
                if (isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _handleReject(item);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _handleApprove(item);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade50,
                            foregroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Approve and Send to Yayasan',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleApprove(Map<String, dynamic> item) {
    final itemId = item['id']?.toString();
    
    if (itemId == null || itemId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid payment ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    store.adminApproveById(itemId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment approved and sent to Yayasan'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleReject(Map<String, dynamic> item) {
    final itemId = item['id']?.toString();
    
    if (itemId == null || itemId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid payment ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show rejection reason dialog
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reject Payment'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Rejection Reason (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                store.adminRejectById(itemId, reason: reasonController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment rejected'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }
}
