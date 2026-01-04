import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/ActivityData.dart';
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
        title: const Text('Activities'),
        backgroundColor: Colors.lightGreen,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search and filter row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by title, location, officer...',
                      prefixIcon: Icon(Icons.search, color: Colors.white),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchText = value.trim().toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: selectedStatus,
                  items: ['All', 'checked_in', 'assigned', 'pending', 'approved', 'rejected']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status == 'All' ? 'All Status' : status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value ?? 'All';
                    });
                  },
                  underline: Container(),
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(
                    Icons.calendar_month,
                    color: selectedDate != null ? Colors.green : Colors.lightGreen,
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                if (selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    tooltip: 'Clear date filter',
                    onPressed: () {
                      setState(() {
                        selectedDate = null;
                      });
                    },
                  ),
              ],
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
              stream: controller.activitiesStream(),
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
                      padding: const EdgeInsets.all(16),
                      itemCount: myActivities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final a = myActivities[index];
                        return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(offset: const Offset(0, 3), blurRadius: 6, color: Colors.black12.withOpacity(0.06)),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + Status
                          Row(
                            children: [
                              Expanded(
                                child: Text(a.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _statusBgColor(a.status),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  a.status.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _statusTextColor(a.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            const Icon(Icons.calendar_month, size: 16, color: Colors.lightGreen),
                            const SizedBox(width: 8),
                            Text(a.activityDate),
                            const SizedBox(width: 8),
                            Text('${a.startTime} - ${a.endTime}'),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text(a.locationName)),
                          ]),
                          const SizedBox(height: 2),
                          Row(children: [
                            const Icon(Icons.person, size: 16, color: Colors.black),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Officer: ${a.officerName ?? a.createdBy}')),
                           if (a.status.toUpperCase() == 'ASSIGNED') ...[
                              ElevatedButton(
                                onPressed: () => _showDetailsPopup(context, a), // full details + check-in
                                child: const Text('View Details'),
                              ),
                            ]  else if (a.status.toUpperCase() == 'CHECKED_IN') ...[
                               ElevatedButton(
                                onPressed: () => _showCheckedInPopup(context, a), // summary popup with 2 buttons
                                child: const Text('View'),
                              ),
                            ] else if (a.status.toUpperCase() == 'PENDING') ...[
                              ElevatedButton(
                                onPressed: () => _showEditSubmissionPopup(context, a),
                                child: const Text('View'),
                              ),
                             
                            ] else ...[
                              ElevatedButton(
                                onPressed: () => _showDetailsPopup(context, a),
                                child: const Text('View Details'),
                              ),
                            ],

                          ]),
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
        return Colors.yellow.shade900;
      case "APPROVED":
        return Colors.green.shade800;
      case "PENDING":
        return Colors.orange.shade900;
      case "REJECTED":
        return Colors.red.shade900;
      default:
        return Colors.grey.shade800;
    }
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
                _detailRow(Icons.topic, "Topic", a.title),
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

                // If the activity is waiting for check-in
                if (a.status.toLowerCase() == "assigned") ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _checkInGPS(a); // <-- your GPS function here
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
                    side: BorderSide(color: Colors.green),
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
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
    ),
  );
}

Widget _detailRow(IconData icon, String label, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.green),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: Colors.black)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
        fontWeight: FontWeight.bold,
        color: _statusTextColor(status),
      ),
    ),
  );
}

Widget _gpsVerifiedBadge() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: _statusBgColor("checked_in"),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.green.shade300),
    ),
    child: Row(
      children: [
        Icon(Icons.verified, color: _statusTextColor("checked_in"), size: 18),
        const SizedBox(width: 6),
        Text(
          "GPS Verified",
          style: TextStyle(
            color: _statusTextColor("checked_in"),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

void _showCheckedInPopup(BuildContext context, ActivityData a) {
  showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with close icon
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 24, color: Colors.black54),
                  ),
                ],
              ),
              Text(
                a.locationName,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 18),

              // Info Box
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _popupDetail(Icons.calendar_today, "Date", a.activityDate),
                    _popupDetail(Icons.access_time, "Time", a.startTime),
                    _popupDetail(Icons.admin_panel_settings, "Officer", a.officerName ?? a.createdBy),
                    _popupDetail(Icons.verified, "Status", "CHECKED-IN"),
                  ],
                ),
              ),

              const SizedBox(height: 22),
              Divider(height: 1, color: Colors.grey.shade300),
              const SizedBox(height: 18),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDetailsPopup(context, a);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text("View Details"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToReportForm(context, a);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text("Submit Report"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Close button
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: Colors.black87)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
void _showEditSubmissionPopup(BuildContext context, ActivityData a) {
  showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with close icon
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 24, color: Colors.black54),
                  ),
                ],
              ),
              Text(
                a.locationName,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 18),

              // Info Box
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _popupDetail(Icons.calendar_today, "Date", a.activityDate),
                    _popupDetail(Icons.access_time, "Time", a.startTime),
                    _popupDetail(Icons.admin_panel_settings, "Officer", a.officerName ?? a.createdBy),
                    _popupDetail(Icons.pending, "Status", "PENDING"),
                  ],
                ),
              ),

              const SizedBox(height: 22),
              Divider(height: 1, color: Colors.grey.shade300),
              const SizedBox(height: 18),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDetailsPopup(context, a);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text("View Details"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToEditSubmission(context, a);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text("Edit Submission"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Close button
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: Colors.black87)),
                ),
              ),
            ],
          ),
        ),
      );
    },
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
  // GPS check-in: only allow when near assigned location
  Future<void> _checkInGPS(ActivityData activity) async {
    const allowedMeters = 200.0; // adjust threshold as needed

    if (activity.locationLat == 0 || activity.locationLng == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity has no valid coordinates.')),
      );
      return;
    }

    // Permissions and service check
    final permOk = await _ensureLocationPermission();
    if (!permOk) return;

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        activity.locationLat,
        activity.locationLng,
      );

      if (distance > allowedMeters) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Too far from location (distance ${(distance / 1000).toStringAsFixed(2)} km).')), 
        );
        return;
      }

      await controller.markCheckedIn(activity);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in successful!')),
        );
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
}