import 'package:flutter/material.dart';
import '../../../models/ActivityData.dart';
import '../../../providers/ActvitiyController.dart';

class AdminActivityList extends StatefulWidget {
  const AdminActivityList({super.key});

  @override
  State<AdminActivityList> createState() => _AdminActivityListState();
}

class _AdminActivityListState extends State<AdminActivityList> {
  final ActivityController controller = ActivityController();
  String _searchQuery = '';
  String _statusFilter = 'All';

  final List<String> _statusOptions = const ['All', 'pending', 'assigned', 'checked_in', 'approved', 'rejected'];

  DateTime? _parseDate(String value) {
    try {
      if (value.contains('/')) {
        final parts = value.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      } else if (value.contains('-')) {
        final parts = value.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('approve')) return Colors.green;
    if (normalized.contains('pending')) return Colors.orange;
    if (normalized.contains('reject')) return Colors.red;
    if (normalized.contains('assigned')) return Colors.blueAccent;
    if (normalized.contains('check')) return Colors.cyan;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('All Activities'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Material(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  borderRadius: BorderRadius.circular(14),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by title, preacher, or location',
                      prefixIcon: Icon(Icons.search, color: scheme.primary),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: scheme.primary, width: 1.2),
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.trim()),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, index) {
                      final status = _statusOptions[index];
                      final isSelected = _statusFilter == status;
                      return ChoiceChip(
                        shape: StadiumBorder(
                          side: BorderSide(color: isSelected ? scheme.primary : scheme.outlineVariant),
                        ),
                        label: Text(status == 'All' ? 'All Status' : status.toUpperCase()),
                        selected: isSelected,
                        selectedColor: scheme.primary.withOpacity(0.16),
                        onSelected: (_) => setState(() => _statusFilter = status),
                        labelStyle: TextStyle(
                          color: isSelected ? scheme.primary : Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemCount: _statusOptions.length,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ActivityData>>(
              stream: controller.activitiesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var activities = snapshot.data ?? [];

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  activities = activities.where((a) =>
                    a.title.toLowerCase().contains(q) ||
                    a.locationName.toLowerCase().contains(q) ||
                    a.topic.toLowerCase().contains(q) ||
                    a.createdBy.toLowerCase().contains(q)
                  ).toList();
                }

                if (_statusFilter != 'All') {
                  activities = activities.where((a) => a.status.toLowerCase() == _statusFilter).toList();
                }

                activities.sort((a, b) {
                  final aDate = _parseDate(a.activityDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bDate = _parseDate(b.activityDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bDate.compareTo(aDate);
                });

                if (activities.isEmpty) {
                  return const Center(child: Text('No activities found'));
                }

                final totalCount = activities.length;

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 4),
                        child: Row(
                          children: [
                            Text(
                              'Showing $totalCount activities',
                              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.filter_list, size: 16, color: Colors.green),
                                  const SizedBox(width: 6),
                                  Text(
                                    _statusFilter == 'All' ? 'All statuses' : _statusFilter.toUpperCase(),
                                    style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final activity = activities[index - 1];
                    final parsedDate = _parseDate(activity.activityDate);
                    final statusColor = _statusColor(activity.status);
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 2,
                      shadowColor: Colors.black12,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showDetails(context, activity),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: Title + Status badge (right)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      activity.title,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      activity.status.toUpperCase(),
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Location
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      activity.locationName,
                                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Date + Time
                              Row(
                                children: [
                                  Icon(Icons.calendar_month, size: 16, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    parsedDate != null ? '${parsedDate.day}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}' : activity.activityDate,
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${activity.startTime}'' - ${activity.endTime}',
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                                 if (activity.topic.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.topic, size: 16, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Topic: ${activity.topic}',
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              if ((activity.preacherName ?? '').isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.record_voice_over, size: 16, color: Colors.teal),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Preacher: ${activity.preacherName}',
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                           
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: activities.length + 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, ActivityData activity) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final parsedDate = _parseDate(activity.activityDate);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Activity Details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(activity.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                    if (activity.topic.isNotEmpty)
                    Row(
                      children: [
                      Icon(Icons.topic, size: 16, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                        activity.topic,
                        style: const TextStyle(color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text(activity.description, style: TextStyle(color: Colors.black)),
                  const SizedBox(height: 12),
                  _DetailRow(icon: Icons.calendar_today, label: 'Date', value: parsedDate != null ? '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}' : activity.activityDate),
                  _DetailRow(icon: Icons.access_time, label: 'Time', value: '${activity.startTime} - ${activity.endTime}'),
                  _DetailRow(icon: Icons.location_on, label: 'Location', value: activity.locationName),
                  _DetailRow(icon: Icons.map, label: 'Address', value: activity.locationAddress),
                  _DetailRow(icon: Icons.person, label: 'Assigned By', value: activity.officerName ?? activity.createdBy),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _statusColor(activity.status).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Status: ${activity.status.toUpperCase()}',
                      style: TextStyle(color: _statusColor(activity.status), fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (activity.submissionRemarks != null && activity.submissionRemarks!.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Latest Submission', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(activity.submissionRemarks ?? ''),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _metaChip({required IconData icon, required String label, required Color color}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    ),
  );
}