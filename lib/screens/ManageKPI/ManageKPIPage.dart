import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/PreacherData.dart';
import '../../providers/PreacherController.dart';
import 'KPIFilterModal.dart';
import 'ViewKPIModal.dart';
import 'AddEditKPIModal.dart';
import 'KPISavedDialog.dart';

class ManageKPIPage extends StatefulWidget {
  const ManageKPIPage({super.key});

  @override
  State<ManageKPIPage> createState() => _ManageKPIPageState();
}

class _ManageKPIPageState extends State<ManageKPIPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedDistrict = 'All';

  // Store KPI data per preacher (in a real app, this would be from Firebase)
  final Map<String, Map<String, dynamic>> _preacherKPIs = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal() {
    showDialog(
      context: context,
      builder: (context) => KPIFilterModal(
        initialDistrict: _selectedDistrict,
        onApply: (district) {
          setState(() {
            _selectedDistrict = district;
          });
        },
      ),
    );
  }

  void _viewKPI(PreacherData preacher) {
    // Get stored KPI or default
    final kpi = _preacherKPIs[preacher.id] ?? {
      'title': 'Monthly Sermons',
      'target': 12,
      'progress': 8,
    };

    showDialog(
      context: context,
      builder: (context) => ViewKPIModal(
        preacherName: preacher.fullName,
        title: kpi['title'],
        target: kpi['target'],
        progress: kpi['progress'],
        onEdit: () => _showAddEditKPI(preacher, isEdit: true),
        onAddNew: () => _showAddEditKPI(preacher, isEdit: false),
      ),
    );
  }

  void _showAddEditKPI(PreacherData preacher, {required bool isEdit}) {
    final existingKPI = _preacherKPIs[preacher.id];

    showDialog(
      context: context,
      builder: (context) => AddEditKPIModal(
        initialTitle: isEdit ? (existingKPI?['title'] as String?) : null,
        initialTarget: isEdit ? (existingKPI?['target'] as int?) : null,
        initialProgress: isEdit ? (existingKPI?['progress'] as int?) : null,
        onSave: (title, target, progress) {
          setState(() {
            _preacherKPIs[preacher.id] = {
              'title': title,
              'target': target,
              'progress': progress,
            };
          });
          // Show success dialog
          KPISavedDialog.show(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Manage Preacher KPI'),
        backgroundColor: Colors.amber.shade500,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search preacher...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(
                    Icons.tune,
                    color: _selectedDistrict != 'All'
                        ? const Color(0xFF7CB342)
                        : Colors.grey[600],
                  ),
                  onPressed: _showFilterModal,
                ),
              ],
            ),
          ),

          // Active Filter Chip
          if (_selectedDistrict != 'All')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Chip(
                    label: Text(_selectedDistrict),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => _selectedDistrict = 'All');
                    },
                    backgroundColor: const Color(0xFF7CB342).withOpacity(0.1),
                    labelStyle: const TextStyle(color: Color(0xFF7CB342)),
                    deleteIconColor: const Color(0xFF7CB342),
                  ),
                ],
              ),
            ),

          // Preachers List
          Expanded(
            child: StreamBuilder<List<PreacherData>>(
              stream: Provider.of<PreacherController>(context, listen: false).preachersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<PreacherData> preachers = snapshot.data ?? [];

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  preachers = preachers.where((p) =>
                    p.fullName.toLowerCase().contains(_searchQuery.toLowerCase())
                  ).toList();
                }

                // Apply district filter
                if (_selectedDistrict != 'All') {
                  preachers = preachers.where((p) =>
                    p.district.toLowerCase() == _selectedDistrict.toLowerCase()
                  ).toList();
                }

                if (preachers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No preachers found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: preachers.length,
                  itemBuilder: (context, index) {
                    final preacher = preachers[index];
                    return _buildPreacherCard(preacher);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreacherCard(PreacherData preacher) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preacher.fullName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'District: ${preacher.district}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _viewKPI(preacher),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B5998),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'View KPI',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
