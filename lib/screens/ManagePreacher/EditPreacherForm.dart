import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/PreacherData.dart';
import '../../providers/PreacherController.dart';

class EditPreacherForm extends StatefulWidget {
  final PreacherData? preacher; // If null, we are in "Add" mode

  const EditPreacherForm({super.key, this.preacher});

  @override
  State<EditPreacherForm> createState() => _EditPreacherFormState();
}

class _EditPreacherFormState extends State<EditPreacherForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _districtController;
  late TextEditingController _icNumberController; // New
  late TextEditingController _addressController; // New
  late TextEditingController _qualificationController; // New
  
  String _status = 'Active';
  String _trainingStatus = 'pending';

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data if editing
    _fullNameController = TextEditingController(text: widget.preacher?.fullName ?? '');
    _emailController = TextEditingController(text: widget.preacher?.email ?? '');
    _phoneController = TextEditingController(text: widget.preacher?.phone ?? '');
    _districtController = TextEditingController(text: widget.preacher?.district ?? '');
    _icNumberController = TextEditingController(text: widget.preacher?.icNumber ?? '');
    _addressController = TextEditingController(text: widget.preacher?.address ?? '');
    _qualificationController = TextEditingController(text: widget.preacher?.qualification ?? '');
    
    if (widget.preacher != null) {
      _status = widget.preacher!.status;
      _trainingStatus = widget.preacher!.trainingStatus;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _districtController.dispose();
    _icNumberController.dispose();
    _addressController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  Future<void> _savePreacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final controller = Provider.of<PreacherController>(context, listen: false);

      final preacher = PreacherData(
        id: widget.preacher?.id ?? '', // Service handles empty ID for new docs if using .add()
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        district: _districtController.text.trim(),
        icNumber: _icNumberController.text.trim(),
        address: _addressController.text.trim(),
        qualification: _qualificationController.text.trim(),
        status: _status,
        trainingStatus: _trainingStatus,
        activityCount: widget.preacher?.activityCount ?? 0,
      );

      if (widget.preacher == null) {
        await controller.addPreacher(preacher);
      } else {
        await controller.updatePreacher(preacher);
      }

      if (mounted) {
        Navigator.pop(context); // Go back to list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.preacher == null 
              ? 'Preacher added successfully!' 
              : 'Preacher updated successfully!'
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preacher: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.preacher != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Preacher' : 'Add Preacher'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _fullNameController,
                label: 'Full Name',
                icon: Icons.person,
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _icNumberController,
                label: 'IC Number',
                icon: Icons.badge,
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'IC Number is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                 validator: (v) => v!.isEmpty || !v.contains('@') ? 'Valid email required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.home,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _districtController,
                label: 'District',
                icon: Icons.location_city,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _qualificationController,
                label: 'Qualification',
                icon: Icons.school,
              ),
              const SizedBox(height: 24),
              
              // Dropdowns
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: ['Active', 'Inactive']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setState(() => _status = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _trainingStatus,
                      decoration: const InputDecoration(labelText: 'Training'),
                      items: ['completed', 'pending', 'in progress']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) => setState(() => _trainingStatus = val!),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _savePreacher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEditing ? 'Update Preacher' : 'Add Preacher',
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[800]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
