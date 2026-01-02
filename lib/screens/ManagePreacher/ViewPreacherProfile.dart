import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/PreacherData.dart';
import '../../providers/PreacherController.dart';
import 'EditPreacherForm.dart';

class ViewPreacherProfile extends StatelessWidget {
  final String preacherId;

  const ViewPreacherProfile({super.key, required this.preacherId});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<PreacherController>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Modern Light Grey
      appBar: AppBar(
        title: const Text('Preacher Profile', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<PreacherData?>(
        future: controller.getPreacherById(preacherId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Preacher not found'));
          }

          final preacher = snapshot.data!;
          final isActive = preacher.status.toLowerCase() == 'active';

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600), // Constraint for Tablets/Web
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue[50],
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.person, size: 50, color: Colors.blue[700]),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            preacher.fullName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green[50] : Colors.red[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: isActive ? Colors.green[700] : Colors.red[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  preacher.status,
                                  style: TextStyle(
                                    color: isActive ? Colors.green[800] : Colors.red[800],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Information Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Personal Information",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildDetailItem(Icons.badge_outlined, 'IC Number', preacher.icNumber),
                          const Divider(height: 32),
                          _buildDetailItem(Icons.email_outlined, 'Email', preacher.email),
                          const Divider(height: 32),
                          _buildDetailItem(Icons.phone_outlined, 'Contact', preacher.phone),
                          const Divider(height: 32),
                          _buildDetailItem(Icons.location_city_outlined, 'District', preacher.district),
                          const Divider(height: 32),
                          _buildDetailItem(Icons.home_outlined, 'Address', preacher.address),
                          const Divider(height: 32),
                          _buildDetailItem(Icons.school_outlined, 'Qualification', preacher.qualification),
                          const Divider(height: 32),
                          _buildDetailItem(Icons.work_outline, 'Training Status', preacher.trainingStatus),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditPreacherForm(preacher: preacher),
                                ),
                              ).then((_) {
                                (context as Element).markNeedsBuild();
                              });
                            },
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            label: const Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _deletePreacher(context, controller, preacher.id),
                            icon: const Icon(Icons.delete_outline, size: 20),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red[700],
                              side: BorderSide(color: Colors.red[200]!),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.blue[800]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : 'N/A',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _deletePreacher(BuildContext context, PreacherController controller, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Preacher?'),
        content: const Text('This action cannot be undone. Are you sure you want to remove this preacher?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await controller.deletePreacher(id);
                if (context.mounted) {
                  Navigator.pop(context); // Go back to list
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
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ); 
  }
}
