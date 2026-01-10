import 'package:flutter/material.dart';
import '../../providers/Registeration/PendingRequestController.dart';

class RegistrationRequestPage extends StatefulWidget {
  const RegistrationRequestPage({super.key});

  @override
  State<RegistrationRequestPage> createState() =>
      _RegistrationRequestPageState();
}

class _RegistrationRequestPageState extends State<RegistrationRequestPage> {
  final PendingRequestController _controller = PendingRequestController();
  String? selectedPreacherId;
  String currentStatus = 'PENDING';
  String? rejectionReason;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  /// Load all pending requests on page load
  Future<void> _loadPendingRequests() async {
    await _controller.loadPendingRequests();
    setState(() {});
  }

  /// View preacher details
  /// Returns 0 on success, -1 on failure
  Future<int> viewPreacherDetails(String preacherId) async {
    int result = await _controller.viewRequest(preacherId);

    if (result == 0) {
      if (_controller.selectedPreacher != null) {
        currentStatus = _controller.selectedPreacher!['status'] ?? 'PENDING';
        // Navigate to details page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _PreacherDetailsPage(
              preacher: _controller.selectedPreacher!,
              onApprove: () async {
                Navigator.pop(context);
                return await approvePreacher(preacherId);
              },
              onReject: (reason) async {
                Navigator.pop(context);
                return await rejectPreacher(preacherId, reason);
              },
            ),
          ),
        );
      }
    } else {
      _showErrorDialog(
        _controller.errorMessage ?? 'Error viewing preacher details',
      );
    }

    return result;
  }

  /// Approve a preacher
  /// Returns 0 on success, -1 on failure
  Future<int> approvePreacher(String preacherId) async {
    // Show confirmation dialog
    bool? confirm = await _showConfirmationDialog(
      'Approve Preacher',
      'Are you sure you want to approve this preacher registration?',
    );

    if (confirm != true) return -1;

    int result = await _controller.approveRequest(preacherId);

    if (result == 0) {
      setState(() {
        selectedPreacherId = null;
      });
      _showSuccessDialog('Preacher approved successfully');
    } else {
      _showErrorDialog(_controller.errorMessage ?? 'Error approving preacher');
    }

    return result;
  }

  /// Reject a preacher with reason
  /// Returns 0 on success, -1 on failure
  Future<int> rejectPreacher(String preacherId, String rejectionReason) async {
    if (rejectionReason.trim().isEmpty) {
      _showErrorDialog('Please provide a rejection reason');
      return -1;
    }

    int result = await _controller.rejectRequest(preacherId, rejectionReason);

    if (result == 0) {
      setState(() {
        selectedPreacherId = null;
      });
      _showSuccessDialog('Preacher rejected successfully');
    } else {
      _showErrorDialog(_controller.errorMessage ?? 'Error rejecting preacher');
    }

    return result;
  }

  /// Show rejection dialog to get reason
  Future<void> _showRejectionDialog(String preacherId) async {
    TextEditingController reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Preacher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              rejectPreacher(preacherId, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Show confirmation dialog
  Future<bool?> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show success dialog
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Pending Requests'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPendingRequestsList(),
    );
  }

  /// Build the list of pending requests
  Widget _buildPendingRequestsList() {
    if (_controller.pendingPreachers.isEmpty) {
      return const Center(
        child: Text(
          'No pending requests',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Pending Preacher\nRegistrations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _controller.pendingPreachers.length,
            itemBuilder: (context, index) {
              final preacher = _controller.pendingPreachers[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preacher['fullName'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${preacher['status'] ?? 'Pending'}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => viewPreacherDetails(preacher['uid']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('View'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Get color based on status
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'ACTIVE':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Separate page for preacher details
class _PreacherDetailsPage extends StatelessWidget {
  final Map<String, dynamic> preacher;
  final Future<int> Function() onApprove;
  final Future<int> Function(String) onReject;

  const _PreacherDetailsPage({
    required this.preacher,
    required this.onApprove,
    required this.onReject,
  });

  Future<void> _showRejectionDialog(BuildContext context) async {
    TextEditingController reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Preacher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (reasonController.text.trim().isNotEmpty) {
                onReject(reasonController.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPending = preacher['status'] == 'PENDING';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preacher Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preacher Registration\nDetails',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('Full Name', preacher['fullName'] ?? 'N/A'),
                  _buildDetailRow('IC Number', preacher['icNumber'] ?? 'N/A'),
                  _buildDetailRow('Phone Number', preacher['phone'] ?? 'N/A'),
                  _buildDetailRow('Address', preacher['address'] ?? 'N/A'),
                  _buildDetailRow(
                    'Background',
                    preacher['qualification'] ?? 'N/A',
                  ),
                  _buildDetailRow(
                    'Current Status',
                    preacher['status'] ?? 'N/A',
                    valueColor: _getStatusColor(preacher['status']),
                  ),
                ],
              ),
            ),
          ),
          if (isPending)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onApprove(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showRejectionDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'Pending':
        return Colors.orange;
      case 'ACTIVE':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
