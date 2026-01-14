import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/ActivityData.dart';
import '../../../models/ActivityAssignment.dart';
import '../../../providers/ActivityController.dart';
import 'submit_report.dart';
import 'editSubmission.dart';
import 'viewReport.dart';

class ActivityList extends StatefulWidget {
  final String? initialStatus;

  const ActivityList({super.key, this.initialStatus});

  @override
  State<ActivityList> createState() => _ActivityListState();
}

class _ActivityListState extends State<ActivityList> {
  final controller = ActivityController();
  String searchText = '';
  String selectedStatus = 'All';
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null) {
      selectedStatus = widget.initialStatus!;
    }
  }


  @override
  void didUpdateWidget(covariant ActivityList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatus != oldWidget.initialStatus && widget.initialStatus != null) {
      setState(() {
        selectedStatus = widget.initialStatus!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your activities')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
     appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.lightGreen.shade400,
        title: const Text(
          'My Activities',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),

      body: Column(
        children: [          
          // Search and filter row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(3),
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
                          onChanged: (v) {
                            setState(() => searchText = v.trim().toLowerCase());
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      _statusFilterChip(),
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
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (selectedDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Filtering by date: ${selectedDate!.day.toString().padLeft(2, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.year}',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedDate = null;
                      });
                    },
                    child: const Text('Clear', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          // Activity list
          Expanded(
            child: StreamBuilder<List<ActivityData>>(
              stream: controller.preacherActivitiesStream(currentUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                var activities = snapshot.data ?? [];
                // Filter by search text
                if (searchText.isNotEmpty) {
                  activities = activities.where((a) =>
                      a.title.toLowerCase().contains(searchText) ||
                      a.locationName.toLowerCase().contains(searchText) ||
                      a.createdBy.toLowerCase().contains(searchText) ||
                      a.locationAddress.toLowerCase().contains(searchText)
                  ).toList();
                }
                // Filter by status
                if (selectedStatus != 'All') {
                  if (selectedStatus == 'checked_in') {
                    // Show both checked_in and pending_report when checked_in filter is selected
                    activities = activities.where((a) => 
                      a.status.toLowerCase() == 'checked_in' || 
                      a.status.toLowerCase() == 'pending_report'||
                      a.status.toLowerCase() == 'pending'
                    ).toList();
                  } else {
                    activities = activities.where((a) => a.status.toLowerCase() == selectedStatus).toList();
                  }
                }
                // Filter by date (supports both D/M/YYYY and YYYY-MM-DD)
                if (selectedDate != null) {
                  activities = activities.where((a) {
                    try {
                      final activityDate = a.activityDate.trim();
                      DateTime? parsed;
                      if (activityDate.contains('/')) {
                        final parts = activityDate.split('/');
                        if (parts.length == 3) {
                          parsed = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                        }
                      } else if (activityDate.contains('-')) {
                        final parts = activityDate.split('-');
                        if (parts.length == 3) {
                          parsed = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
                        }
                      }
                      if (parsed == null) return false;
                      return parsed.year == selectedDate!.year &&
                             parsed.month == selectedDate!.month &&
                             parsed.day == selectedDate!.day;
                    } catch (_) {
                      return false;
                    }
                  }).toList();
                }
                if (activities.isEmpty) {
                  return const Center(child: Text('No activities available'));
                }

                return FutureBuilder<List<ActivityData>>(
                  future: ActivityData.fetchMultipleDetails(activities),
                  builder: (context, detailsSnapshot) {
                    if (detailsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final activitiesWithDetails = detailsSnapshot.data ?? activities;
                    final myActivities = activitiesWithDetails
                        .where((a) => a.assignment?.preacherId == currentUid)
                        .toList();

                    if (myActivities.isEmpty) {
                      return const Center(child: Text('No activities assigned to you'));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(10),
                      itemCount: myActivities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final a = myActivities[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border(
                              left: BorderSide(
                                color: Colors.lightGreen.shade400,
                                width: 4,
                              ),
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
                                  Expanded(
                                    child: _infoRow(Icons.calendar_month, a.activityDate),
                                  ),
                                  Expanded(
                                    child: _infoRow(Icons.access_time, '${a.startTime} - ${a.endTime}'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.lightGreen.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.lightGreen.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.location_on, color: Colors.lightGreen, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        a.locationName,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _showDetailsPopup(context, a),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.lightGreen.shade400,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(44),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text('View Details'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
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

  String _formatStatus(String? status) {
    if (status == null || status.isEmpty) return 'Unknown';
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toUpperCase())
        .join(' ');
  }

  Color _statusBgColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case "CHECKED_IN":
      case "PENDING":
      case "PENDING_REPORT":
      case "PENDING_REPORT_REVIEW":
      case "ASSIGNED":
        return Colors.yellow.shade100;
      case "CHECK_IN_MISSED":
        return Colors.red.shade50;
      case "PENDING_ABSENCE_REVIEW":
        return Colors.blue.shade50;
      case "PENDING_OFFICER_REVIEW":
        return Colors.purple.shade50;
      case "ABSENT":
        return Colors.red.shade100;
      case "CANCELLED":
        return Colors.grey.shade300;
      case "APPROVED":
        return Colors.green.shade100;
      case "REJECTED":
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _statusTextColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case "CHECKED_IN":
      case "PENDING":
      case "PENDING_REPORT":
      case "PENDING_REPORT_REVIEW":
      case "ASSIGNED":
        return Colors.orange.shade800;
      case "CHECK_IN_MISSED":
        return Colors.red.shade800;
      case "PENDING_ABSENCE_REVIEW":
        return Colors.blue.shade800;
      case "PENDING_OFFICER_REVIEW":
        return Colors.purple.shade800;
      case "ABSENT":
        return Colors.red.shade700;
      case "CANCELLED":
        return Colors.grey.shade800;
      case "APPROVED":
        return Colors.green.shade800;
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

Widget _infoRow(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.lightGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black),
          ),
        ),
      ],
    ),
  );
}



//view details popup
 void _showDetailsPopup(BuildContext context, ActivityData a) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.60,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Title Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Activity Details",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 26),
                    )
                  ],
                ),

                const SizedBox(height: 10),

                // ⭐ Basic Info Section
                _sectionHeader("Basic Information"),
                _detailRow(Icons.topic, "Title", a.title),
                _detailRow(Icons.person, "Preacher",  a.preacherName ?? 'Not assigned'),
                _detailRow(Icons.admin_panel_settings, "Assigned Officer", a.officerName ?? a.createdBy),

                const SizedBox(height: 16),
                _sectionHeader("Date & Time"),
                _detailRow(Icons.calendar_month, "Date", a.activityDate),
                _detailRow(Icons.access_time, "Time", "${a.startTime} - ${a.endTime}"),

                const SizedBox(height: 16),
                _sectionHeader("Location"),
                _detailRow(Icons.location_on, "Venue", a.locationName),
                _detailRow(Icons.location_city, "Address", a.locationAddress),

                const SizedBox(height: 16),
                _sectionHeader("Activity Details"),
                _detailRow(Icons.topic, "Topic", a.topic),
                _detailRow(Icons.description, "Description", a.description),

                const SizedBox(height: 16),
                _sectionHeader("Status & Verification"),
                Row(
                  children: [
                    _statusChip(a.status),
                    const SizedBox(width: 10),
                    if (a.status.toLowerCase() == "checked_in")
                      _gpsVerifiedBadge(),
                  ],
                ),

                // Show "View Report" button if status is pending_report_review/approved/rejected
                if (a.status.toLowerCase() == "pending_report_review" || a.status.toLowerCase() == "approved" || a.status.toLowerCase() == "rejected") ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ViewReportScreen(activity: a),
                          ),
                        );
                      },
                      icon: const Icon(Icons.description_outlined),
                      label: const Text(
                        "View Report",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // 📍 ACTION BUTTONS

                SizedBox(height: 20),

                // If the activity is waiting for check-in (only show 1 hour before to 1 hour after)
                if (a.status.toLowerCase() == "assigned" && _isCheckInTimeValid(a)) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _checkInGPS(a);
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text("Check-In (GPS)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else if (a.status.toLowerCase() == "assigned") ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.orange.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Check-in opens 1 hour before activity start time',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // NO SHOW → ask for explanation or mark absent
                if (a.status.toLowerCase() == "check_in_missed") ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'CHECK-IN MISSED – Action Required',
                            style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showExplanationDialog(a, isLate: true);
                    },
                    icon: const Icon(Icons.fact_check),
                    label: const Text('Submit Explanation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                ],

                // If explanation already submitted
                if (a.status.toLowerCase() == "explanation_submitted") ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pending_actions, color: Colors.blue.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Explanation submitted. Awaiting officer review.',
                            style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // If the activity is checked in or awaiting report submission → allow submit report
                if (a.status.toLowerCase() == "checked_in" || a.status.toLowerCase() == "pending_report" || a.status.toLowerCase() == "pending") ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToReportForm(context, a);
                    },
                    icon: const Icon(Icons.assignment),
                    label: const Text("Submit Report"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],

                // Close button (always shown)
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text("Close"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.red.shade700),
                    backgroundColor: Colors.red.shade700,
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
Widget _sectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 6),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
      ),
    ),
  );
}

Widget _detailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.lightGreen.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.lightGreen, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
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
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: _statusTextColor(status),
      ),
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
        const Icon(Icons.verified, color: Colors.green, size: 18),
        const SizedBox(width: 6),
        Text(
          "GPS Verified",
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget _buildSubmissionDetails(ActivityData activity) {
  return FutureBuilder<QuerySnapshot>(
    future: FirebaseFirestore.instance
        .collection('activity_submissions')
        .where('assignment_id', isEqualTo: activity.assignment?.assignmentId)
        .limit(1)
        .get(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.orange.shade700),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading submission details...',
                style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
              ),
            ],
          ),
        );
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const SizedBox.shrink();
      }

      final submissionDoc = snapshot.data!.docs.first;
      final data = submissionDoc.data() as Map<String, dynamic>;

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange.shade50, Colors.orange.shade100.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Edit Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.orange.shade200, Colors.orange.shade100],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.assignment_turned_in, color: Colors.orange.shade800, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Submitted Report',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 14, color: Colors.orange.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Awaiting officer review',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Edit Submission Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToEditSubmission(context, activity);
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Submission'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Outcome & Attendance with improved design
                  Row(
                    children: [
                      Expanded(
                        child: _submissionDetailTile(
                          Icons.task_alt,
                          'Outcome',
                          data['outcome'] ?? 'N/A',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _submissionDetailTile(
                          Icons.people,
                          'Attendance',
                          data['attendance']?.toString() ?? 'N/A',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Time Details
                  Row(
                    children: [
                      Expanded(
                        child: _submissionDetailTile(
                          Icons.access_time,
                          'Start Time',
                          data['actual_start_time'] ?? 'N/A',
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _submissionDetailTile(
                          Icons.schedule,
                          'End Time',
                          data['actual_end_time'] ?? 'N/A',
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  
                  if (data['remarks'] != null && data['remarks'].toString().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _submissionTextDetail(
                      Icons.note_alt,
                      'Remarks',
                      data['remarks'],
                      Colors.indigo,
                    ),
                  ],
                  
                  if (data['incident_notes'] != null && data['incident_notes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _submissionTextDetail(
                      Icons.warning_amber_rounded,
                      'Incident Notes',
                      data['incident_notes'],
                      Colors.deepOrange,
                    ),
                  ],
                  
                  if (data['feedback_suggestions'] != null && data['feedback_suggestions'].toString().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _submissionTextDetail(
                      Icons.feedback_outlined,
                      'Feedback & Suggestions',
                      data['feedback_suggestions'],
                      Colors.teal,
                    ),
                  ],
                  
                  if (data['photo_base64'] != null && data['photo_base64'].toString().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.photo_camera, size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Photo Proof',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              base64Decode(data['photo_base64']),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 48),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Failed to load image',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _submissionDetailTile(IconData icon, String label, String value, Color color) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.08),
          blurRadius: 4,
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget _submissionTextDetail(IconData icon, String label, String value, Color color) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.08),
          blurRadius: 4,
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

/// --- Small detail row widget for popup ---
Widget _popupDetail(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Colors.lightGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "$label: $value",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}




void _navigateToReportForm(BuildContext context, ActivityData a) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SubmitReportScreen(activity: a),
    ),
  );
}

void _navigateToEditSubmission(BuildContext context, ActivityData a) async {
  try {
    // Fetch the submission data for this activity
    final submissionDoc = await FirebaseFirestore.instance
        .collection('activity_submissions')
        .where('activity_id', isEqualTo: a.activityId)
        .limit(1)
        .get();

    if (!mounted) return;

    if (submissionDoc.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No submission found for this activity')),
      );
      return;
    }

    final submissionData = submissionDoc.docs.first.data();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditSubmissionScreen(
          activity: a,
          submissionData: submissionData,
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading submission: $e')),
    );
  }
}

  Future<void> _showExplanationDialog(ActivityData activity, {bool isLate = false}) async {
    final absenceReasons = ['Emergency', 'Medical', 'Travel', 'Forgot', 'Miscommunication', 'Other'];
    final checkInReasons = ['Late Check-In'];
    String selectedReason = isLate ? 'Late Check-In' : absenceReasons.first;
    final detailsController = TextEditingController();
    XFile? proofImage;
    Uint8List? proofPreview;
    bool isUploading = false;

    Future<String> uploadProofAsBase64(XFile file) async {
      try {
        // Validate file exists
        final filePath = file.path;
        final fileExists = await File(filePath).exists();
        if (!fileExists) {
          throw Exception('Selected file no longer exists');
        }

        // Read bytes with timeout
        final bytes = await file.readAsBytes().timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('File read timeout'),
        );

        if (bytes.isEmpty) {
          throw Exception('File is empty');
        }

        // Check file size (Firestore has 1MB limit per field, keep under 500KB to be safe)
        if (bytes.length > 500000) {
          throw Exception('Image too large (${(bytes.length / 1024 / 1024).toStringAsFixed(2)}MB). Keep images under 500KB.');
        }

        // Convert to Base64
        final base64String = base64Encode(bytes);
        
        print('📸 Image size: ${(bytes.length / 1024).toStringAsFixed(2)}KB');
        print('📊 Base64 size: ${(base64String.length / 1024).toStringAsFixed(2)}KB');
        
        return base64String;
      } catch (e) {
        print('Upload Proof Error: $e');
        rethrow;
      }
    }

    void pickImage(ImageSource source, StateSetter setModalState) async {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 75);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setModalState(() {
          proofImage = picked;
          proofPreview = bytes;
        });
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isLateCheckInSelected = selectedReason == 'Late Check-In';
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 16,
                      offset: const Offset(0, -2),
                      color: Colors.black.withOpacity(0.08),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.fact_check, color: Colors.orange, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Submit Explanation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isLateCheckInSelected
                            ? 'Late check-in requires a photo proof and a short note so the officer can review quickly.'
                            : 'Share why you could not attend or check in. Keep it clear so the officer can decide faster.',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),

                      Text('Reason', style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...absenceReasons.map((reason) {
                            final isSelected = selectedReason == reason;
                            return ChoiceChip(
                              label: Text(reason),
                              selected: isSelected,
                              selectedColor: Colors.green.shade50,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.green.shade800 : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (selected) => setModalState(() => selected ? selectedReason = reason : null),
                            );
                          }),
                          ...checkInReasons.map((reason) {
                            final isSelected = selectedReason == reason;
                            return ChoiceChip(
                              label: Text(reason),
                              selected: isSelected,
                              selectedColor: Colors.orange.shade50,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.orange.shade800 : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (selected) => setModalState(() => selected ? selectedReason = reason : null),
                            );
                          }),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Text('Details', style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: detailsController,
                        decoration: InputDecoration(
                          hintText: 'Explain what happened... (required)',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        maxLines: 4,
                      ),

                      if (isLateCheckInSelected) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.photo_camera_back_outlined, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Photo Proof (required for late check-in)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.orange.shade800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: isUploading ? null : () => pickImage(ImageSource.camera, setModalState),
                                    icon: const Icon(Icons.photo_camera),
                                    label: const Text('Camera'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade700,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    onPressed: isUploading ? null : () => pickImage(ImageSource.gallery, setModalState),
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Gallery'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange.shade800,
                                      side: BorderSide(color: Colors.orange.shade300),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (proofPreview != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    proofPreview!,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (proofImage == null)
                                Row(
                                  children: [
                                    Icon(Icons.info, color: Colors.orange.shade600, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Attach a clear photo that shows you were at the venue.',
                                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isUploading ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                side: BorderSide(color: Colors.grey.shade400),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isUploading
                                  ? null
                                  : () async {
                                      if (detailsController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(this.context).showSnackBar(
                                          const SnackBar(content: Text('Please provide an explanation')),
                                        );
                                        return;
                                      }
                                      if (isLateCheckInSelected && proofImage == null) {
                                        ScaffoldMessenger.of(this.context).showSnackBar(
                                          const SnackBar(content: Text('Photo proof is required for late check-in')),
                                        );
                                        return;
                                      }

                                      try {
                                        setModalState(() => isUploading = true);
                                        String proofUrl = '';
                                        
                                        if (isLateCheckInSelected && proofImage != null) {
                                          try {
                                            proofUrl = await uploadProofAsBase64(proofImage!);
                                          } catch (uploadError) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(this.context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Photo processing failed: $uploadError'),
                                                  duration: const Duration(seconds: 5),
                                                ),
                                              );
                                            }
                                            setModalState(() => isUploading = false);
                                            return;
                                          }
                                        }

                                        await controller.submitExplanation(
                                          activity: activity,
                                          reason: selectedReason,
                                          details: detailsController.text.trim(),
                                          proofUrl: proofUrl,
                                        );
                                        if (!mounted) return;
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(this.context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isLateCheckInSelected
                                                  ? 'Late check-in submitted for officer review'
                                                  : 'Explanation submitted for review',
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        setModalState(() => isUploading = false);
                                        ScaffoldMessenger.of(this.context).showSnackBar(
                                          SnackBar(
                                            content: Text('Submit failed: $e'),
                                            duration: const Duration(seconds: 5),
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isUploading) ...[
                                    const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  const Text('Submit'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmMarkAbsent(ActivityData activity) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Absent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You must provide a reason why you cannot attend:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (required)',
                hintText: 'Explain why you cannot attend...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Confirm Absent'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      await controller.preacherMarkAbsent(activity, reason: reasonController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as absent')),
      );
    }
  }

  bool _isCheckInTimeValid(ActivityData activity) {
    try {
      final now = DateTime.now();
      
      // Parse activity date
      final activityDateStr = activity.activityDate.trim();
      DateTime? activityDate;
      if (activityDateStr.contains('/')) {
        final parts = activityDateStr.split('/');
        if (parts.length == 3) {
          activityDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } else if (activityDateStr.contains('-')) {
        final parts = activityDateStr.split('-');
        if (parts.length == 3) {
          activityDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      }
      
      if (activityDate == null) return false;
      
      // Check if today is the activity date
      final today = DateTime(now.year, now.month, now.day);
      final activityDay = DateTime(activityDate.year, activityDate.month, activityDate.day);
      if (!today.isAtSameMomentAs(activityDay)) return false;
      
      // Parse start and end times (handle both HH:mm and hh:mm AM/PM formats)
      int startHour = 0, startMinute = 0, endHour = 0, endMinute = 0;
      
      // Parse start time
      String startTimeStr = activity.startTime.trim();
      if (startTimeStr.contains('AM') || startTimeStr.contains('PM')) {
        final isAM = startTimeStr.contains('AM');
        startTimeStr = startTimeStr.replaceAll('AM', '').replaceAll('PM', '').trim();
        final parts = startTimeStr.split(':');
        if (parts.length >= 2) {
          startHour = int.parse(parts[0]);
          startMinute = int.parse(parts[1]);
          if (!isAM && startHour != 12) startHour += 12;
          else if (isAM && startHour == 12) startHour = 0;
        }
      } else {
        final parts = startTimeStr.split(':');
        if (parts.length >= 2) {
          startHour = int.parse(parts[0]);
          startMinute = int.parse(parts[1]);
        }
      }
      
      // Parse end time
      String endTimeStr = activity.endTime.trim();
      if (endTimeStr.contains('AM') || endTimeStr.contains('PM')) {
        final isAM = endTimeStr.contains('AM');
        endTimeStr = endTimeStr.replaceAll('AM', '').replaceAll('PM', '').trim();
        final parts = endTimeStr.split(':');
        if (parts.length >= 2) {
          endHour = int.parse(parts[0]);
          endMinute = int.parse(parts[1]);
          if (!isAM && endHour != 12) endHour += 12;
          else if (isAM && endHour == 12) endHour = 0;
        }
      } else {
        final parts = endTimeStr.split(':');
        if (parts.length >= 2) {
          endHour = int.parse(parts[0]);
          endMinute = int.parse(parts[1]);
        }
      }
      
      final currentMinutes = now.hour * 60 + now.minute;
      final startMinutes = startHour * 60 + startMinute;
      final endMinutes = endHour * 60 + endMinute;
      
      // Check-in window: 1 hour before start to 1 hour after end
      final earliestCheckIn = startMinutes - 60;
      final latestCheckIn = endMinutes + 60;
      
      return currentMinutes >= earliestCheckIn && currentMinutes <= latestCheckIn;
    } catch (e) {
      return false;
    }
  }
  
  // GPS check-in: only allow when near assigned location
  Future<void> _checkInGPS(ActivityData activity) async {
    const allowedMeters = 500.0; // 500-meter radius validation

    // Get current user ID
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    // 1. ASSIGNMENT VALIDATION
    ActivityAssignment? assignment = activity.assignment;
    assignment ??= await ActivityAssignment.getAssignmentByActivity(activity.activityId);
    
    if (assignment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No assignment found for this activity')),
      );
      return;
    }

    if (assignment.preacherId != currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This activity is not assigned to you')),
      );
      return;
    }

    // 6. SINGLE CHECK-IN RULE
    if (activity.status.toLowerCase() == 'checked_in') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already checked in for this activity')),
      );
      return;
    }

    // 2. ACTIVITY DATE VALIDATION
    final now = DateTime.now();
    DateTime? activityDate;
    
    try {
      final activityDateStr = activity.activityDate.trim();
      if (activityDateStr.contains('/')) {
        final parts = activityDateStr.split('/');
        if (parts.length == 3) {
          activityDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } else if (activityDateStr.contains('-')) {
        final parts = activityDateStr.split('-');
        if (parts.length == 3) {
          activityDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid activity date format')),
      );
      return;
    }

    if (activityDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity date is not properly set')),
      );
      return;
    }

    final today = DateTime(now.year, now.month, now.day);
    final activityDay = DateTime(activityDate.year, activityDate.month, activityDate.day);

    if (today.isBefore(activityDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot check in before the activity date')),
      );
      return;
    }

    if (today.isAfter(activityDay)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot check in after the activity date')),
      );
      return;
    }

    // 3. TIME WINDOW VALIDATION (with late tracking)
    int startHour = 0, startMinute = 0, endHour = 0, endMinute = 0;
    bool isLateCheckIn = false;
    
    try {
      // Parse start time (handle both HH:mm and hh:mm AM/PM formats)
      String startTimeStr = activity.startTime.trim();
      if (startTimeStr.contains('AM') || startTimeStr.contains('PM')) {
        final isAM = startTimeStr.contains('AM');
        startTimeStr = startTimeStr.replaceAll('AM', '').replaceAll('PM', '').trim();
        final parts = startTimeStr.split(':');
        if (parts.length >= 2) {
          startHour = int.parse(parts[0]);
          startMinute = int.parse(parts[1]);
          if (!isAM && startHour != 12) startHour += 12;
          else if (isAM && startHour == 12) startHour = 0;
        }
      } else {
        final parts = startTimeStr.split(':');
        if (parts.length >= 2) {
          startHour = int.parse(parts[0]);
          startMinute = int.parse(parts[1]);
        }
      }
      
      // Parse end time
      String endTimeStr = activity.endTime.trim();
      if (endTimeStr.contains('AM') || endTimeStr.contains('PM')) {
        final isAM = endTimeStr.contains('AM');
        endTimeStr = endTimeStr.replaceAll('AM', '').replaceAll('PM', '').trim();
        final parts = endTimeStr.split(':');
        if (parts.length >= 2) {
          endHour = int.parse(parts[0]);
          endMinute = int.parse(parts[1]);
          if (!isAM && endHour != 12) endHour += 12;
          else if (isAM && endHour == 12) endHour = 0;
        }
      } else {
        final parts = endTimeStr.split(':');
        if (parts.length >= 2) {
          endHour = int.parse(parts[0]);
          endMinute = int.parse(parts[1]);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid activity time format')),
      );
      return;
    }

    final currentTime = TimeOfDay.fromDateTime(now);
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;
    
    // Check-in window: 1 hour before start to 1 hour after end
    final earliestCheckInMinutes = startMinutes - 60;
    final latestCheckInMinutes = endMinutes + 60;
    
    if (currentMinutes < earliestCheckInMinutes) {
      final minutesUntilWindow = earliestCheckInMinutes - currentMinutes;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Too early! Check-in opens $minutesUntilWindow minutes before start time')),
      );
      return;
    }
    
    if (currentMinutes > latestCheckInMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in window closed (ended 1 hour after activity end time)')),
      );
      return;
    }
    
    // Determine if check-in is late (after start time)
    if (currentMinutes > startMinutes) {
      isLateCheckIn = true;
    }

    // Coordinate validation
    if (activity.locationLat == 0 || activity.locationLng == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity has no valid coordinates.')),
      );
      return;
    }

    // 4. GPS PERMISSION VALIDATION
    final permOk = await _ensureLocationPermission();
    if (!permOk) return;

    try {
      // 5. GPS DISTANCE VALIDATION
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        activity.locationLat,
        activity.locationLng,
      );

      // Debug: Show current and target locations
      print('📍 Current GPS: ${pos.latitude}, ${pos.longitude}');
      print('🎯 Target location: ${activity.locationLat}, ${activity.locationLng}');
      print('📏 Distance: ${distance.toStringAsFixed(2)} meters');

      final verificationResult = distance <= allowedMeters ? 'success' : 'failed';
      final submissionId = now.millisecondsSinceEpoch;
      final verificationId = now.millisecondsSinceEpoch + 1;

      // Store GPS verification log (always, regardless of success/failure)
      await FirebaseFirestore.instance.collection('gps_verification_logs').add({
        'verification_id': verificationId,
        'submission_id': submissionId,
        'captured_latitude': pos.latitude,
        'captured_longitude': pos.longitude,
        'expected_latitude': activity.locationLat,
        'expected_longitude': activity.locationLng,
        'distance_meters': distance,
        'verification_result': verificationResult,
        'verified_at': Timestamp.fromDate(now),
        'device_info': 'Flutter App - ${now.toIso8601String()}',
      });

      if (distance > allowedMeters) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Too far from location (${distance.toStringAsFixed(0)} meters away).\n'
              'You must be within 100 meters to check in.'
            ),
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      // Create activity_submissions document
      await FirebaseFirestore.instance.collection('activity_submissions').add({
        'submission_id': submissionId,
        'assignment_id': assignment.assignmentId,
        'preacher_id': currentUid,
        'gps_latitude': pos.latitude,
        'gps_longitude': pos.longitude,
        'gps_timestamp': Timestamp.fromDate(now),
        'attendance': 'Present',
        'check_in_status': isLateCheckIn ? 'late' : 'on_time',
        'remarks': '',
        'attachment_url': '',
        'submitted_at': Timestamp.fromDate(now),
      });

      // Update activity and assignment status
      await controller.markCheckedIn(activity);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-in failed: $e')),
      );
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled. Please enable GPS.')),
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission permanently denied. Enable it in Settings.')),
      );
      return false;
    }

    return true;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Success',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'GPS Check-In successful! Location verified.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusFilterChip() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.lightGreen.shade50,
      borderRadius: BorderRadius.circular(20),
    ),
    child: DropdownButton<String>(
      value: selectedStatus,
      underline: const SizedBox(),
      items: ['All', 'assigned', 'checked_in', 'pending_report_review', 'approved', 'rejected', 'check_in_missed', 'pending_absence_review', 'pending_officer_review', 'absent', 'cancelled']
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(_getStatusDisplayName(s)),
              ))
          .toList(),
      onChanged: (v) => setState(() => selectedStatus = v!),
    ),
  );
}
} 