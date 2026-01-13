import 'package:flutter/material.dart';

class AddEditKPIModal extends StatefulWidget {
  final String? initialTitle;
  final int? initialTarget;
  final int? initialProgress;
  final Function(String title, int target, int progress) onSave;

  const AddEditKPIModal({
    super.key,
    this.initialTitle,
    this.initialTarget,
    this.initialProgress,
    required this.onSave,
  });

  @override
  State<AddEditKPIModal> createState() => _AddEditKPIModalState();
}

class _AddEditKPIModalState extends State<AddEditKPIModal> {
  late TextEditingController _titleController;
  late TextEditingController _targetController;
  late TextEditingController _progressController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _targetController = TextEditingController(
      text: widget.initialTarget?.toString() ?? '',
    );
    _progressController = TextEditingController(
      text: widget.initialProgress?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final target = int.tryParse(_targetController.text) ?? 0;
    final progress = int.tryParse(_progressController.text) ?? 0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a KPI title'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pop(context);
    widget.onSave(title, target, progress);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add / Edit KPI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // KPI Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'KPI Title',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Target Value
            TextField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Target Value',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Progress
            TextField(
              controller: _progressController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Progress',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            Center(
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5998),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
