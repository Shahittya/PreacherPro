import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/ActivityData.dart';
import '../../../models/ActivityAssignment.dart';
import '../../../providers/ActvitiyController.dart';
import 'submit_report.dart';
import 'editSubmission.dart';

class ActivityList extends StatefulWidget {
  const ActivityList({super.key});

  @override
  State<ActivityList> createState() => _ActivityListState();
}

class _ActivityListState extends State<ActivityList> {
  final controller = ActivityController();
  String searchText = '';
  String selectedStatus = 'All';
  DateTime? selectedDate;

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
                  activities = activities.where((a) => a.status.toLowerCase() == selectedStatus).toList();
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
                                      child: Text(
                                        a.status.toLowerCase() == 'pending'
                                            ? 'View Submission'
                                            : 'View Details',
                                      ),
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

  Color _statusBgColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case "CHECKED_IN":
      case "ASSIGNED":
        return Colors.yellow.shade100;
      case "APPROVED":
        return Colors.green.shade100;
      case "PENDING":
        return Colors.orange.shade100;
      case "REJECTED":
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _statusTextColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case "CHECKED_IN":
      case "ASSIGNED":
        return Colors.orange.shade800;
      case "APPROVED":
        return Colors.green.shade800;
      case "PENDING":
        return Colors.orange.shade900;
      case "REJECTED":
        return Colors.red.shade800;
      default:
        return Colors.grey.shade700;
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

                // If the activity is already checked in → allow submit report
                if (a.status.toLowerCase() == "checked_in") ...[
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
      status.toUpperCase(),
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

void _navigateToEditSubmission(BuildContext context, ActivityData a) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EditSubmissionScreen(activity: a),
    ),
  );
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
      
      // Parse start and end times
      final startParts = activity.startTime.split(':');
      final endParts = activity.endTime.split(':');
      if (startParts.length < 2 || endParts.length < 2) return false;
      
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);
      
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
    const allowedMeters = 200.0; // 100-meter radius validation

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

    // 3. TIME WINDOW VALIDATION
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    
    try {
      final startParts = activity.startTime.split(':');
      if (startParts.length >= 2) {
        startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
      }
      
      final endParts = activity.endTime.split(':');
      if (endParts.length >= 2) {
        endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid activity time format')),
      );
      return;
    }

    if (startTime != null && endTime != null) {
      final currentTime = TimeOfDay.fromDateTime(now);
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      
      // Allow check-in up to 1 hour before start time
      final earliestCheckInMinutes = startMinutes - 60;
      
      if (currentMinutes < earliestCheckInMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in opens 1 hour before activity start time')),
        );
        return;
      }
      
      if (currentMinutes > endMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in closed. Activity time has ended')),
        );
        return;
      }
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
      items: ['All', 'assigned', 'checked_in', 'pending', 'approved', 'rejected']
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(s),
              ))
          .toList(),
      onChanged: (v) => setState(() => selectedStatus = v!),
    ),
  );
}

}