import 'package:flutter/material.dart';
import '../../models/PreacherData.dart';

class ViewKPIPage extends StatefulWidget {
  final PreacherData preacher;

  const ViewKPIPage({
    super.key,
    required this.preacher,
  });

  @override
  State<ViewKPIPage> createState() => _ViewKPIPageState();
}

class _ViewKPIPageState extends State<ViewKPIPage> {
  // KPI Targets (editable)
  int _activityTarget = 10;
  int _trainingTarget = 5;
  int _reportTarget = 8;

  @override
  Widget build(BuildContext context) {
    final preacher = widget.preacher;
    
    // Calculate KPI progress
    final activityProgress = preacher.activityCount / _activityTarget;
    final trainingProgress = preacher.trainingStatus.toLowerCase() == 'completed' ? 1.0 : 0.5;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Preacher KPI'),
        backgroundColor: const Color(0xFF7CB342),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preacher Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7CB342),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      preacher.fullName.isNotEmpty ? preacher.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7CB342),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preacher.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'District: ${preacher.district}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Status: ${preacher.status}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // KPI Section Title
            const Text(
              'KPI Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Activity KPI
            _buildKPICard(
              title: 'Monthly Activities',
              current: preacher.activityCount,
              target: _activityTarget,
              icon: Icons.event,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),

            // Training KPI
            _buildKPICard(
              title: 'Training Completion',
              current: preacher.trainingStatus.toLowerCase() == 'completed' ? 1 : 0,
              target: 1,
              icon: Icons.school,
              color: Colors.orange,
              customLabel: preacher.trainingStatus,
            ),
            const SizedBox(height: 12),

            // Report KPI
            _buildKPICard(
              title: 'Monthly Reports',
              current: preacher.activityCount > 3 ? preacher.activityCount - 2 : 1,
              target: _reportTarget,
              icon: Icons.description,
              color: Colors.purple,
            ),
            const SizedBox(height: 24),

            // Set KPI Target Section
            const Text(
              'Set KPI Targets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Container(
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
                children: [
                  _buildTargetRow('Activity Target', _activityTarget, (val) {
                    setState(() => _activityTarget = val);
                  }),
                  const Divider(),
                  _buildTargetRow('Training Target', _trainingTarget, (val) {
                    setState(() => _trainingTarget = val);
                  }),
                  const Divider(),
                  _buildTargetRow('Report Target', _reportTarget, (val) {
                    setState(() => _reportTarget = val);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('KPI targets saved successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7CB342),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save KPI Targets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required int current,
    required int target,
    required IconData icon,
    required Color color,
    String? customLabel,
  }) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toInt();

    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                customLabel ?? '$current / $target',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetRow(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: value > 1 ? () => onChanged(value - 1) : null,
                color: const Color(0xFF7CB342),
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => onChanged(value + 1),
                color: const Color(0xFF7CB342),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
