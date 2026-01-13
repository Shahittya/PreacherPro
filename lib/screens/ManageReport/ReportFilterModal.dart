import 'package:flutter/material.dart';

class ReportFilterModal extends StatefulWidget {
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final String initialCategory;
  final Function(DateTime?, DateTime?, String) onApply;

  const ReportFilterModal({
    super.key,
    this.initialFromDate,
    this.initialToDate,
    this.initialCategory = 'All',
    required this.onApply,
  });

  @override
  State<ReportFilterModal> createState() => _ReportFilterModalState();
}

class _ReportFilterModalState extends State<ReportFilterModal> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Activity', 'KPI', 'Payment'];

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _selectedCategory = widget.initialCategory;
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate 
          ? (_fromDate ?? DateTime.now()) 
          : (_toDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B5998),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _reset() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _selectedCategory = 'All';
    });
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
              'Filter Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // From Date
            GestureDetector(
              onTap: () => _selectDate(context, true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _fromDate != null ? _formatDate(_fromDate) : 'From (YYYY-MM-DD)',
                  style: TextStyle(
                    color: _fromDate != null ? Colors.black : const Color(0xFF3B5998),
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // To Date
            GestureDetector(
              onTap: () => _selectDate(context, false),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _toDate != null ? _formatDate(_toDate) : 'To (YYYY-MM-DD)',
                  style: TextStyle(
                    color: _toDate != null ? Colors.black : const Color(0xFF3B5998),
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category Dropdown
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset Button
                ElevatedButton(
                  onPressed: _reset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 16),
                // Apply Button
                ElevatedButton(
                  onPressed: () {
                    widget.onApply(_fromDate, _toDate, _selectedCategory);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B5998),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
