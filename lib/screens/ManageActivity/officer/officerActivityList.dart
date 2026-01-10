import 'package:flutter/material.dart';
import '../../../models/ActivityData.dart';
import '../../../providers/ActivityController.dart';
import 'assignActivity.dart';
import 'editActivity.dart';
import 'editMapScreen.dart';
import 'reviewReport.dart';
import '../../../utils/image_utils.dart';

class OfficerActivityList extends StatefulWidget {
  const OfficerActivityList({super.key});

  @override
  State<OfficerActivityList> createState() => _OfficerActivityListState();
}

class _OfficerActivityListState extends State<OfficerActivityList> {
  final controller = ActivityController();
  String searchText = '';
  String selectedStatus = 'All';
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    // Activities are now filtered by current officer by default in the controller
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.amber.shade300,
        title: const Text(
          'Activities',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Assign Activity',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssignActivityForm(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Showing activities you created or assigned, sorted by priority',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search and filter row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search activities...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchText = value.trim().toLowerCase();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusFilterChip(),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        Icons.calendar_month,
                        color: selectedDate != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                    if (selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => selectedDate = null);
                        },
                      ),
                  ],
                ),
              ),
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

                // Search filter
                if (searchText.isNotEmpty) {
                  activities = activities
                      .where(
                        (a) =>
                            a.title.toLowerCase().contains(searchText) ||
                            a.locationName.toLowerCase().contains(searchText) ||
                            a.createdBy.toLowerCase().contains(searchText) ||
                            a.locationAddress.toLowerCase().contains(
                              searchText,
                            ),
                      )
                      .toList();
                }

                // Status filter
                if (selectedStatus != 'All') {
                  activities = activities
                      .where(
                        (a) =>
                            a.status.toLowerCase() ==
                            selectedStatus.toLowerCase(),
                      )
                      .toList();
                }

                // Date filter
                if (selectedDate != null) {
                  activities = activities.where((a) {
                    try {
                      final parts = a.activityDate.contains('/')
                          ? a.activityDate.split('/')
                          : a.activityDate.split('-');

                      final parsedDate = a.activityDate.contains('/')
                          ? DateTime(
                              int.parse(parts[2]),
                              int.parse(parts[1]),
                              int.parse(parts[0]),
                            )
                          : DateTime(
                              int.parse(parts[0]),
                              int.parse(parts[1]),
                              int.parse(parts[2]),
                            );

                      return parsedDate.year == selectedDate!.year &&
                          parsedDate.month == selectedDate!.month &&
                          parsedDate.day == selectedDate!.day;
                    } catch (_) {
                      return false;
                    }
                  }).toList();
                }

                if (activities.isEmpty) {
                  return _emptyState();
                }

                return FutureBuilder<List<ActivityData>>(
                  future: ActivityData.fetchMultipleDetails(activities),
                  builder: (context, detailsSnapshot) {
                    if (detailsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = detailsSnapshot.data ?? activities;

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: data.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final a = data[index];
                        return _activityCard(context, a);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Check if activity has started or passed
  bool _hasActivityStarted(ActivityData activity) {
    try {
      DateTime activityDateTime;

      // Parse date (handles both DD/MM/YYYY and YYYY-MM-DD formats)
      if (activity.activityDate.contains('/')) {
        final parts = activity.activityDate.split('/');
        activityDateTime = DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
        );
      } else {
        final parts = activity.activityDate.split('-');
        activityDateTime = DateTime(
          int.parse(parts[0]), // year
          int.parse(parts[1]), // month
          int.parse(parts[2]), // day
        );
      }

      // Parse time (handles both "HH:mm" and "hh:mm AM/PM" formats)
      String timeStr = activity.startTime.trim();
      int hour = 0;
      int minute = 0;

      if (timeStr.contains('AM') || timeStr.contains('PM')) {
        // 12-hour format with AM/PM
        final isAM = timeStr.contains('AM');
        timeStr = timeStr.replaceAll('AM', '').replaceAll('PM', '').trim();
        final timeParts = timeStr.split(':');

        if (timeParts.length >= 2) {
          hour = int.parse(timeParts[0]);
          minute = int.parse(timeParts[1]);

          // Convert to 24-hour format
          if (!isAM && hour != 12) {
            hour += 12;
          } else if (isAM && hour == 12) {
            hour = 0;
          }
        }
      } else {
        // 24-hour format
        final timeParts = timeStr.split(':');
        if (timeParts.length >= 2) {
          hour = int.parse(timeParts[0]);
          minute = int.parse(timeParts[1]);
        }
      }

      activityDateTime = DateTime(
        activityDateTime.year,
        activityDateTime.month,
        activityDateTime.day,
        hour,
        minute,
      );

      // Check if current time is past activity start time
      return DateTime.now().isAfter(activityDateTime);
    } catch (e) {
      print('Error parsing activity date/time: $e');
      return false; // If parsing fails, allow editing
    }
  }

  Widget _statusFilterChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButton<String>(
        value: selectedStatus,
        underline: const SizedBox(),
        items:
            [
                  'All',
                  'assigned',
                  'checked_in',
                  'pending_report_review',
                  'approved',
                  'rejected',
                  'check_in_missed',
                  'pending_absence_review',
                  'pending_officer_review',
                  'absent',
                  'cancelled',
                ]
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s == 'All' ? 'All Activities' : _formatStatus(s)),
                  ),
                )
                .toList(),
        onChanged: (v) => setState(() => selectedStatus = v!),
      ),
    );
  }

  Widget _activityCard(BuildContext context, ActivityData a) {
    final statusLower = a.status.toLowerCase();
    final canReviewReport = statusLower == 'pending_report_review';
    final canEditActivity = statusLower == 'assigned' && !_hasActivityStarted(a);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: Colors.amber.shade400, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _statusChip(a.status),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: _infoRow(Icons.calendar_month, a.activityDate)),
              Expanded(
                child: _infoRow(
                  Icons.access_time,
                  '${a.startTime} - ${a.endTime}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.amber,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    a.locationName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showDetailsPopup(context, a),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade400,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
              if (canEditActivity) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit),
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditActivityForm(
                          activityToEdit: a,
                          assignmentDocId: a.assignment?.docId ?? '',
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  onPressed: () => _showDeleteConfirmation(context, a),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.amber.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No activities found',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ================= STATUS =================

  Color _statusBgColor(String status) {
    switch (status.toUpperCase()) {
      case "CHECKED_IN":
      case "PENDING_REPORT":
      case "PENDING_REPORT_REVIEW":
      case "ASSIGNED":
        return Colors.yellow.shade100;
      case "NO_SHOW":
        return Colors.red.shade50;
      case "PENDING_OFFICER_REVIEW":
        return Colors.purple.shade50;
      case "PENDING_ABSENCE_REVIEW":
        return Colors.blue.shade50;
      case "ABSENT":
        return Colors.red.shade100;
      case "CANCELLED":
        return Colors.grey.shade300;
      case "APPROVED":
        return Colors.green.shade100;
      case "PENDING":
      case "PENDING_REPORT":
        return Colors.orange.shade100;
      case "REJECTED":
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  bool _canCancel(String statusLower) {
    return statusLower == 'assigned' ||
        statusLower == 'pending_officer_review' ||
        statusLower == 'pending_absence_review';
  }

  bool _canReschedule(ActivityData activity) {
    final statusLower = activity.status.toLowerCase();
    const allowedStatuses = {
      'assigned',
      'check_in_missed',
      'pending_officer_review',
      'pending_absence_review',
      'cancelled',
    };
    return allowedStatuses.contains(statusLower);
  }

  String _formatStatus(String? status) {
    if (status == null || status.isEmpty) return 'Unknown';
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toUpperCase())
        .join(' ');
  }

  Color _statusTextColor(String status) {
    switch (status.toUpperCase()) {
      case "CHECKED_IN":
      case "PENDING_REPORT":
      case "PENDING_REPORT_REVIEW":
      case "ASSIGNED":
        return Colors.orange.shade800;
      case "NO_SHOW":
        return Colors.red.shade800;
      case "PENDING_OFFICER_REVIEW":
        return Colors.purple.shade800;
      case "PENDING_ABSENCE_REVIEW":
        return Colors.blue.shade800;
      case "ABSENT":
        return Colors.red.shade700;
      case "CANCELLED":
        return Colors.grey.shade800;
      case "APPROVED":
        return Colors.green.shade800;
      case "PENDING":
      case "PENDING_REPORT":
        return Colors.orange.shade900;
      case "REJECTED":
        return Colors.red.shade800;
      default:
        return Colors.grey.shade700;
    }
  }


  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return 'All Activities';
      case 'assigned':
        return 'ASSIGNED';
      case 'checked_in':
      case 'pending_report':
        return 'CHECKED IN';
      case 'check_in_missed':
        return 'ATTENDANCE MISSED';
      case 'pending_officer_review':
        return 'LATE ATTENDANCE REVIEW';
      case 'pending_absence_review':
        return 'ABSENCE REVIEW';
      case 'pending_report_review':
        return 'PENDING REVIEW';
      case 'approved':
        return 'APPROVED / COMPLETED';
      case 'rejected':
        return 'REJECTED (REQUIRES FIX)';
      case 'absent':
        return 'ABSENT';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return _formatStatus(status);
    }
  }
  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _statusBgColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
      _getStatusDisplayName(status),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: _statusTextColor(status),
        ),
      ),
    );
  }

  // ================= DETAILS & DELETE =================

  void _showDetailsPopup(BuildContext context, ActivityData a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final statusLower = a.status.toLowerCase();
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.6,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // ===== Drag Handle =====
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // ===== Header =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Text(
                          'Activity Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      children: [
                        // ===== STATUS =====
                        Row(
                          children: [
                            _statusBadge(a.status),
                            const SizedBox(width: 10),
                            if (a.status.toLowerCase() == 'checked_in')
                              _gpsVerifiedBadge(),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _sectionTitle('Basic Information'),
                        _detailTile(
                          icon: Icons.topic,
                          color: Colors.blue,
                          label: 'Title',
                          value: a.title,
                        ),
                        _detailTile(
                          icon: Icons.person,
                          color: Colors.deepPurple,
                          label: 'Preacher',
                          value: a.preacherName ?? 'Not assigned',
                        ),
                        _detailTile(
                          icon: Icons.admin_panel_settings,
                          color: Colors.teal,
                          label: 'Officer',
                          value: a.officerName ?? a.createdBy,
                        ),

                        const SizedBox(height: 16),
                        _sectionTitle('Date & Time'),
                        _detailTile(
                          icon: Icons.calendar_month,
                          color: Colors.orange,
                          label: 'Date',
                          value: a.activityDate,
                        ),
                        _detailTile(
                          icon: Icons.access_time,
                          color: Colors.indigo,
                          label: 'Time',
                          value: '${a.startTime} - ${a.endTime}',
                        ),

                        const SizedBox(height: 16),
                        _sectionTitle('Location'),
                        _detailTile(
                          icon: Icons.location_on,
                          color: Colors.red,
                          label: 'Venue',
                          value: a.locationName,
                        ),
                        _detailTile(
                          icon: Icons.location_city,
                          color: Colors.brown,
                          label: 'Address',
                          value: a.locationAddress,
                        ),

                        const SizedBox(height: 16),
                        _sectionTitle('Description'),
                        _detailTile(
                          icon: Icons.description,
                          color: Colors.grey.shade700,
                          label: 'Details',
                          value: a.description,
                        ),

                        const SizedBox(height: 30),
                        // ===== ACTION BASED ON EXPLANATION REASON =====
                        if (a.status.toLowerCase() == 'pending_report_review')
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _navigateToReportReview(context, a);
                            },
                            icon: const Icon(Icons.assignment),
                            label: const Text('Review Report'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade300,
                              foregroundColor: Colors.black,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),

                        if (statusLower == 'pending_officer_review' ||
                            statusLower == 'pending_absence_review') ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Explanation',
                                  style: TextStyle(
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if ((a.explanationReason ?? '').isNotEmpty)
                                  Text(
                                    'Reason: ${a.explanationReason}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                if ((a.explanationDetails ?? '').isNotEmpty)
                                  Text(
                                    'Details: ${a.explanationDetails}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                if ((a.explanationProofUrl ?? '')
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  _proofPreview(
                                    proof: a.explanationProofUrl!,
                                    onTap: () => _showProofImage(
                                      context,
                                      a.explanationProofUrl!,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildExplanationActions(context, a),
                        ],

                        if (_canCancel(statusLower)) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showCancelActivityConfirmation(context, a),
                            icon: const Icon(Icons.event_busy),
                            label: const Text('Cancel Activity'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              foregroundColor: Colors.orange.shade900,
                              side: BorderSide(color: Colors.orange.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],

                        if (_canReschedule(a)) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showRescheduleDialog(context, a),
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Reschedule Activity'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),

                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
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

  void _navigateToReportReview(BuildContext context, ActivityData activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewReportScreen(activity: activity),
      ),
    );
  }

  // Build action buttons based on explanation reason
  Widget _buildExplanationActions(BuildContext context, ActivityData activity) {
    final statusLower = activity.status.toLowerCase();

    if (statusLower == 'pending_officer_review') {
      // Late check-in: mark attended (goes to pending_report) or mark absent
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await controller.officerApproveExplanation(activity);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Marked attended. Preacher notified. Report can be submitted.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark as Attended'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await controller.officerRejectLateCheckIn(activity);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Marked as absent. Preacher notified. Case closed.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Mark as Absent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      );
    }

    if (statusLower == 'pending_absence_review') {
      // No-show/absence review: finalize as absent
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await controller.officerRejectExplanation(activity);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Marked as absent. Preacher notified.'),
                ),
              );
            },
            icon: const Icon(Icons.cancel_schedule_send),
            label: const Text('Mark as Absent'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      );
    }

    // Default fallback
    return const SizedBox.shrink();
  }

  void _showRescheduleDialog(BuildContext context, ActivityData activity) {
    final dateCtrl = TextEditingController(text: activity.activityDate);
    final startCtrl = TextEditingController(text: activity.startTime);
    final endCtrl = TextEditingController(text: activity.endTime);
    final locationCtrl = TextEditingController(text: activity.locationName);
    final addressCtrl = TextEditingController(text: activity.locationAddress);
    final reasonCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              Future<void> pickDate() async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  final formatted =
                      '${picked.day}/${picked.month}/${picked.year}';
                  setState(() => dateCtrl.text = formatted);
                }
              }

              Future<void> pickTime(TextEditingController controller) async {
                final picked = await showTimePicker(
                  context: ctx,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) {
                  setState(() => controller.text = picked.format(ctx));
                }
              }

              Future<void> pickLocation() async {
                final result = await Navigator.push<Map<String, dynamic>>(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => EditMapScreen(
                      initialLat: activity.locationLat,
                      initialLng: activity.locationLng,
                      initialLocationName: activity.locationName,
                    ),
                  ),
                );
                if (result != null && mounted) {
                  setState(() {
                    locationCtrl.text = result['name'] ?? '';
                    addressCtrl.text = result['name'] ?? '';
                  });
                }
              }

              Future<void> submit() async {
                if (dateCtrl.text.trim().isEmpty ||
                    startCtrl.text.trim().isEmpty ||
                    reasonCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Date, start time, and reason are required.',
                      ),
                    ),
                  );
                  return;
                }
                setState(() => isSaving = true);
                await controller.officerRescheduleActivity(
                  activity,
                  newDate: dateCtrl.text.trim(),
                  newStartTime: startCtrl.text.trim(),
                  newEndTime: endCtrl.text.trim().isEmpty
                      ? activity.endTime
                      : endCtrl.text.trim(),
                  newLocationName: locationCtrl.text.trim().isEmpty
                      ? activity.locationName
                      : locationCtrl.text.trim(),
                  newLocationAddress: addressCtrl.text.trim().isEmpty
                      ? activity.locationAddress
                      : addressCtrl.text.trim(),
                  newLat: activity.locationLat,
                  newLng: activity.locationLng,
                  reason: reasonCtrl.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(dialogCtx); // dialog
                Navigator.pop(context); // details sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rescheduled and preacher notified'),
                  ),
                );
              }

              return SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.calendar_month,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Reschedule Activity',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info, color: Colors.orange.shade700),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Use only if the session did NOT happen. Preacher will be notified instantly.',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: dateCtrl,
                        readOnly: true,
                        onTap: pickDate,
                        decoration: InputDecoration(
                          labelText: 'New date',
                          hintText: 'DD/MM/YYYY',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: Colors.grey.shade600,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blue.shade300,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: startCtrl,
                              readOnly: true,
                              onTap: () => pickTime(startCtrl),
                              decoration: InputDecoration(
                                labelText: 'Start time',
                                hintText: 'HH:MM',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                prefixIcon: Icon(
                                  Icons.access_time,
                                  color: Colors.grey.shade600,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.blue.shade300,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: endCtrl,
                              readOnly: true,
                              onTap: () => pickTime(endCtrl),
                              decoration: InputDecoration(
                                labelText: 'End time (optional)',
                                hintText: 'HH:MM',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                prefixIcon: Icon(
                                  Icons.access_time_filled,
                                  color: Colors.grey.shade600,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.blue.shade300,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: locationCtrl,
                        readOnly: true,
                        onTap: pickLocation,
                        decoration: InputDecoration(
                          labelText: 'Location (optional)',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: Colors.grey.shade600,
                          ),
                          suffixIcon: Icon(
                            Icons.map,
                            color: Colors.blue.shade600,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blue.shade300,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressCtrl,
                        decoration: InputDecoration(
                          labelText: 'Address (optional)',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          prefixIcon: Icon(
                            Icons.map,
                            color: Colors.grey.shade600,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blue.shade300,
                              width: 2,
                            ),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonCtrl,
                        decoration: InputDecoration(
                          labelText: 'Reason (required)',
                          hintText:
                              'Surau closed, weather, committee request, double-booked...',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          prefixIcon: Icon(
                            Icons.edit_note,
                            color: Colors.grey.shade600,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blue.shade300,
                              width: 2,
                            ),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.pop(dialogCtx),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving ? null : submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(44),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text('Confirm'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Confirmation dialog for canceling activity
  void _showCancelActivityConfirmation(
    BuildContext context,
    ActivityData activity,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade600,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cancel activity?',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Use cancel only when the event itself is called off due to venue or organizer issues.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade800, height: 1.45),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Status will change to "cancelled".',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Preacher will be notified immediately.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: Colors.grey.shade800,
                  ),
                  child: const Text('Keep'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await controller.officerCancelEvent(activity);
                    if (!mounted) return;
                    Navigator.pop(context); // Close details popup
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Activity cancelled and preacher notified',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Confirm cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProofImage(BuildContext context, String url) {
    final isBase64 = ImageUtils.isBase64(url);
    final imageWidget = isBase64
        ? ImageUtils.decodeBase64Image(url, fit: BoxFit.contain)
        : Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (ctx, error, stack) => _proofErrorPlaceholder(),
          );

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageWidget,
          ),
        ),
      ),
    );
  }

  Widget _proofErrorPlaceholder() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.broken_image, size: 28),
            SizedBox(height: 6),
            Text('Unable to load proof image'),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _statusBgColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _statusTextColor(status),
        ),
      ),
    );
  }

  // Preview for proof image (supports Base64 or network URL)
  Widget _proofPreview({required String proof, required VoidCallback onTap}) {
    final isBase64 = ImageUtils.isBase64(proof);
    final imageWidget = isBase64
        ? ImageUtils.decodeBase64Image(proof, fit: BoxFit.cover, height: 200)
        : Image.network(
            proof,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              final value = progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                        (progress.expectedTotalBytes!)
                  : null;
              return Container(
                height: 200,
                alignment: Alignment.center,
                color: Colors.blue.shade100,
                child: CircularProgressIndicator(
                  value: value,
                  color: Colors.blue.shade700,
                ),
              );
            },
            errorBuilder: (ctx, error, stack) => _proofErrorPlaceholder(),
          );

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: imageWidget,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _detailTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gpsVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, size: 18, color: Colors.green),
          const SizedBox(width: 6),
          Text(
            'GPS Verified',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ActivityData activity) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_forever,
                color: Colors.red.shade600,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Delete Activity?',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will permanently delete this activity. This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade800, height: 1.45),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Only activities with "assigned" status can be deleted.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Assignment will also be removed.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: Colors.grey.shade800,
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await controller.deleteActivity(activity);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success ? 'Activity deleted successfully' : 'Cannot delete this activity',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
