import 'package:flutter/material.dart';
import '../../../models/ActivityData.dart';
import '../../../providers/ActivityController.dart';
import 'viewReportAdmin.dart';

class AdminActivityList extends StatefulWidget {
  const AdminActivityList({super.key});

  @override
  State<AdminActivityList> createState() => _AdminActivityListState();
}

class _AdminActivityListState extends State<AdminActivityList> {
  final ActivityController controller = ActivityController();
  String _searchQuery = '';
  String _statusFilter = 'All';

  final List<String> _statusOptions = const [
    'All',
    'assigned',
    'checked_in',
    'pending_report',
    'pending_report_review',
    'pending_officer_review',
    'pending_absence_review',
    'check_in_missed',
    'absent',
    'approved',
    'rejected',
    'cancelled'
  ];

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
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'assigned':
        return Colors.blueAccent;
      case 'checked_in':
        return Colors.cyan;
      case 'pending_report':
      case 'pending':
        return Colors.orange;
      case 'pending_officer_review':
        return Colors.purple;
      case 'pending_absence_review':
        return Colors.blue;
      case 'check_in_missed':
        return Colors.redAccent;
      case 'rejected':
        return Colors.red;
      case 'absent':
        return Colors.red.shade700;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green.shade100;
      case 'assigned':
        return Colors.blue.shade100;
      case 'checked_in':
        return Colors.cyan.shade100;
      case 'pending_report':
      case 'pending':
        return Colors.orange.shade100;
      case 'pending_officer_review':
        return Colors.purple.shade50;
      case 'pending_absence_review':
        return Colors.blue.shade50;
      case 'check_in_missed':
        return Colors.red.shade50;
      case 'rejected':
        return Colors.red.shade100;
      case 'absent':
        return Colors.red.shade100;
      case 'cancelled':
        return Colors.grey.shade300;
      default:
        return Colors.grey.shade200;
    }
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return 'All Activities';
      case 'assigned':
        return 'Assigned';
      case 'checked_in':
        return 'Checked-In';
      case 'check_in_missed':
        return 'Attendance Missed';
      case 'pending_officer_review':
        return 'Late Attendance Review';
      case 'pending_absence_review':
        return 'Absence Review';
      case 'pending_report':
      case 'pending':
        return 'Report Submission';
      case 'approved':
        return 'Approved / Completed';
      case 'rejected':
        return 'Rejected (Requires Fix)';
      case 'absent':
        return 'Absent';
      case 'cancelled':
        return 'Cancelled';
      default:
        return _formatStatus(status);
    }
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
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scheme.primary.withOpacity(0.3)),
                    ),
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      icon: Icon(Icons.expand_more, color: scheme.primary),
                      menuMaxHeight: 400,
                      items: _statusOptions
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                _getStatusDisplayName(s),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _statusFilter = v!),
                      isExpanded: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ActivityData>>(
              stream: controller.allActivitiesStream(),
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
                    final statusBg = _statusBgColor(activity.status);
                    final statusLower = activity.status.toLowerCase();
                    final canViewReport = statusLower == 'pending_report_review' || 
                                          statusLower == 'approved' || 
                                          statusLower == 'rejected' ||
                                          statusLower == 'absent';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border(
                          left: BorderSide(color: statusColor, width: 4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                            color: Colors.black.withOpacity(0.08),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _showDetails(context, activity),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and Status Badge
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    activity.title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    _getStatusDisplayName(activity.status),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Location
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 17, color: Colors.red.shade400),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    activity.locationName,
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Date and Time Container
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Colors.green.shade600),
                                  const SizedBox(width: 8),
                                  Text(
                                    parsedDate != null
                                        ? '${parsedDate.day}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}'
                                        : activity.activityDate,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.access_time, size: 16, color: Colors.blue.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${activity.startTime} - ${activity.endTime}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            if (activity.topic.isNotEmpty || (activity.preacherName ?? '').isNotEmpty) ...[
                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  if (activity.topic.isNotEmpty) ...[
                                    Icon(Icons.topic, size: 15, color: Colors.amber.shade700),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        activity.topic,
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                            if ((activity.preacherName ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.person, size: 15, color: Colors.teal.shade600),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      activity.preacherName!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.teal.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (canViewReport) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: Icon(
                                    statusLower == 'absent' 
                                        ? Icons.cancel 
                                        : Icons.description,
                                    size: 18,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: statusLower == 'absent'
                                        ? Colors.red.shade100
                                        : statusLower == 'approved'
                                            ? Colors.green.shade100
                                            : statusLower == 'rejected'
                                                ? Colors.orange.shade100
                                                : Colors.blue.shade100,
                                    foregroundColor: statusLower == 'absent'
                                        ? Colors.red.shade700
                                        : statusLower == 'approved'
                                            ? Colors.green.shade700
                                            : statusLower == 'rejected'
                                                ? Colors.orange.shade700
                                                : Colors.blue.shade700,
                                    minimumSize: const Size(0, 42),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ViewReportAdminScreen(activity: activity),
                                      ),
                                    );
                                  },
                                  label: Text(
                                    statusLower == 'absent' 
                                        ? 'View Absence Details' 
                                        : statusLower == 'approved'
                                            ? 'View Approved Report'
                                            : statusLower == 'rejected'
                                                ? 'View Rejected Report'
                                                : 'View Submission',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ],
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
      backgroundColor: Colors.transparent,
      builder: (_) {
        final parsedDate = _parseDate(activity.activityDate);
        final statusColor = _statusColor(activity.status);
        final statusBg = _statusBgColor(activity.status);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.event_note,
                                  color: scheme.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Activity Details',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey.shade100,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Title and Status
                          Text(
                            activity.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getStatusDisplayName(activity.status),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (activity.topic.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.topic, size: 18, color: Colors.amber.shade700),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      activity.topic,
                                      style: TextStyle(
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (activity.description.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              activity.description,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          _sectionTitle('Schedule'),
                          const SizedBox(height: 10),
                          _DetailRow(
                            icon: Icons.calendar_today,
                            label: 'Date',
                            value: parsedDate != null
                                ? '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}'
                                : activity.activityDate,
                            color: Colors.green,
                          ),
                          _DetailRow(
                            icon: Icons.access_time,
                            label: 'Time',
                            value: '${activity.startTime} - ${activity.endTime}',
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle('Location'),
                          const SizedBox(height: 10),
                          _DetailRow(
                            icon: Icons.location_on,
                            label: 'Venue',
                            value: activity.locationName,
                            color: Colors.red,
                          ),
                          _DetailRow(
                            icon: Icons.map,
                            label: 'Address',
                            value: activity.locationAddress,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle('Assignment'),
                          const SizedBox(height: 10),
                          if ((activity.preacherName ?? '').isNotEmpty)
                            _DetailRow(
                              icon: Icons.person,
                              label: 'Preacher',
                              value: activity.preacherName!,
                              color: Colors.teal,
                            ),
                          _DetailRow(
                            icon: Icons.person_outline,
                            label: 'Assigned By',
                            value: activity.officerName ?? activity.createdBy,
                            color: Colors.purple,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Colors.grey.shade600,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
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