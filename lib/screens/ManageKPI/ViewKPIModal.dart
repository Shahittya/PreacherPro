import 'package:flutter/material.dart';

class ViewKPIModal extends StatelessWidget {
  final String preacherName;
  final String title;
  final int target;
  final int progress;
  final VoidCallback onEdit;
  final VoidCallback onAddNew;

  const ViewKPIModal({
    super.key,
    required this.preacherName,
    required this.title,
    required this.target,
    required this.progress,
    required this.onEdit,
    required this.onAddNew,
  });

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
            // Title
            Text(
              "$preacherName's KPI",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // KPI Details
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  const TextSpan(
                    text: 'Title: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: title),
                ],
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  const TextSpan(
                    text: 'Target: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7CB342),
                    ),
                  ),
                  TextSpan(
                    text: '$target',
                    style: const TextStyle(color: Color(0xFF7CB342)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  const TextSpan(
                    text: 'Progress: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B5998),
                    ),
                  ),
                  TextSpan(
                    text: '$progress',
                    style: const TextStyle(color: Color(0xFF3B5998)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B5998),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onAddNew();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Add New'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Close link
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
