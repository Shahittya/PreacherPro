import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/PreacherData.dart';
import '../../providers/PreacherController.dart';
import 'EditPreacherForm.dart';
import 'ViewPreacherProfile.dart';

class PreacherManagementPage extends StatefulWidget {
  const PreacherManagementPage({super.key});

  @override
  State<PreacherManagementPage> createState() => _PreacherManagementPageState();
}

class _PreacherManagementPageState extends State<PreacherManagementPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Access the controller via Provider
    final preacherController = Provider.of<PreacherController>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Preachers'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search preachers...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      // Implement filter logic here if needed
                    },
                  ),
                ),
              ],
            ),
          ),

          // List of Preachers
          Expanded(
            child: StreamBuilder<List<PreacherData>>(
              stream: preacherController.preachersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final preachers = snapshot.data ?? [];
                
                // Filter logic
                final filteredPreachers = preachers.where((preacher) {
                  return preacher.fullName.toLowerCase().contains(_searchQuery) ||
                         preacher.email.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredPreachers.isEmpty) {
                  return const Center(child: Text('No preachers found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredPreachers.length,
                  itemBuilder: (context, index) {
                    final preacher = filteredPreachers[index];
                    return _buildPreacherCard(context, preacher, preacherController);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreacherCard(BuildContext context, PreacherData preacher, PreacherController controller) {
    bool isActive = preacher.status.toLowerCase() == 'active';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewPreacherProfile(preacherId: preacher.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.blue[800],
                    child: Text(
                      preacher.fullName.isNotEmpty ? preacher.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              preacher.fullName, // Updated from name
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green[100] : Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                preacher.status,
                                style: TextStyle(
                                  color: isActive ? Colors.green[800] : Colors.red[800],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          preacher.email,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        
                        // Details Row
                        _buildIconText(Icons.phone, preacher.phone), // Updated from phoneNumber
                        const SizedBox(height: 4),
                        _buildIconText(
                          Icons.school, 
                          preacher.trainingStatus, 
                          color: _getTrainingColor(preacher.trainingStatus)
                        ),
                        const SizedBox(height: 4),
                        _buildIconText(Icons.assignment, '${preacher.activityCount} activities'),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(),
              ),
              // Action Buttons
              Row(
                children: [
                  _buildActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: Colors.blue[800]!,
                    onTap: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPreacherForm(preacher: preacher),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: isActive ? Icons.block : Icons.check_circle_outline,
                    label: isActive ? 'Deactivate' : 'Activate',
                    color: isActive ? Colors.orange[800]! : Colors.green[800]!,
                    onTap: () => _confirmStatusChange(context, preacher, controller),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: Colors.red[800]!,
                    onTap: () => _confirmDelete(context, preacher, controller),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: color ?? Colors.grey[800],
            fontWeight: color != null ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Color _getTrainingColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'in progress': return Colors.orange;
      case 'pending': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmStatusChange(BuildContext context, PreacherData preacher, PreacherController controller) {
    bool isActive = preacher.status.toLowerCase() == 'active';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isActive ? 'Deactivate Account' : 'Activate Account'),
        content: Text('Are you sure you want to ${isActive ? 'deactivate' : 'activate'} ${preacher.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await controller.updatePreacherStatus(
                  preacher.id, 
                  isActive ? 'Inactive' : 'Active'
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Account ${isActive ? 'deactivated' : 'activated'} successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating status: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, PreacherData preacher, PreacherController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Preacher'),
        content: Text('Are you sure you want to delete ${preacher.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              try {
                await controller.deletePreacher(preacher.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preacher deleted successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting preacher: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
