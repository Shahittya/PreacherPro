import 'package:flutter/material.dart';

class GenerateSummaryModal extends StatefulWidget {
  final Function(String month, String district, String reportType) onExport;

  const GenerateSummaryModal({
    super.key,
    required this.onExport,
  });

  @override
  State<GenerateSummaryModal> createState() => _GenerateSummaryModalState();
}

class _GenerateSummaryModalState extends State<GenerateSummaryModal> {
  String _selectedMonth = 'January';
  String _selectedDistrict = 'All';
  String _selectedReportType = 'Activity';

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> _districts = [
    'All', 'Kuantan', 'Temerloh', 'Bentong', 'Pekan', 'Rompin',
    'Bera', 'Maran', 'Jerantut', 'Lipis', 'Raub', 'Cameron Highlands'
  ];

  final List<String> _reportTypes = ['Activity', 'KPI', 'Payment', 'All'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Generate Summary Report',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'The system displays filter options (Month, District, Report Type).',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The Officer selects the criteria and clicks <<Generate>>.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The system compiles KPI, Activity, and Payment data and displays the summarized report on screen.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),

              // Month Dropdown
              const Text(
                'Month',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                value: _selectedMonth,
                items: _months,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMonth = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // District Dropdown
              const Text(
                'District',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                value: _selectedDistrict,
                items: _districts,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedDistrict = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Report Type Dropdown
              const Text(
                'Report Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                value: _selectedReportType,
                items: _reportTypes,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedReportType = value);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel Button
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  // Export Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onExport(_selectedMonth, _selectedDistrict, _selectedReportType);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5998),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Export'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
