import 'package:flutter/material.dart';

class KPIFilterModal extends StatefulWidget {
  final String? initialDistrict;
  final Function(String) onApply;

  const KPIFilterModal({
    super.key,
    this.initialDistrict,
    required this.onApply,
  });

  @override
  State<KPIFilterModal> createState() => _KPIFilterModalState();
}

class _KPIFilterModalState extends State<KPIFilterModal> {
  String _selectedDistrict = 'All';

  final List<String> _districts = [
    'All',
    'Kuantan',
    'Temerloh',
    'Bentong',
    'Pekan',
    'Rompin',
    'Bera',
    'Maran',
    'Jerantut',
    'Lipis',
    'Raub',
    'Cameron Highlands',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDistrict = widget.initialDistrict ?? 'All';
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
              'Filter List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // District Dropdown
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDistrict,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _districts.map((String district) {
                    return DropdownMenuItem<String>(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedDistrict = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Apply Filter Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApply(_selectedDistrict);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5998),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Apply Filter',
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
