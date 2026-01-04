import 'package:flutter/material.dart';
import '../../../models/ActivityData.dart';
import '../../../providers/ActvitiyController.dart';
import 'assignActivity.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Activities'),
        backgroundColor: Colors.amber.shade300,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            tooltip: 'Assign Activity',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>  AssignActivityForm(),
                  fullscreenDialog: true, // Optional: makes it slide from bottom on iOS
                ),
              );
            },
          ),
        ],
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
                    color: selectedDate != null ? Colors.green : Colors.amber,
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
                    icon: const Icon(Icons.clear, color: Colors.black),
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
          // Show selected date indicator
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
                    child: const Text('Clear', style: TextStyle(color: Colors.black)),
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
                print('Total activities from stream: ${activities.length}');
                
                // Filter by search text
                if (searchText.isNotEmpty) {
                  activities = activities.where((a) =>
                      a.title.toLowerCase().contains(searchText) ||
                      a.locationName.toLowerCase().contains(searchText) ||
                      a.createdBy.toLowerCase().contains(searchText) ||
                      a.locationAddress.toLowerCase().contains(searchText)
                  ).toList();
                  print('After search filter: ${activities.length}');
                }
                // Filter by status
                if (selectedStatus != 'All') {
                  activities = activities.where((a) => a.status.toLowerCase() == selectedStatus).toList();
                  print('After status filter: ${activities.length}');
                }
                // Filter by date
                if (selectedDate != null) {
                  activities = activities.where((a) {
                    try {
                      final activityDate = a.activityDate.trim();
                      
                      // Parse the activity date (handles both "D/M/YYYY" and "YYYY-MM-DD" formats)
                      DateTime? parsedActivityDate;
                      
                      if (activityDate.contains('/')) {
                        // Format: D/M/YYYY or DD/MM/YYYY
                        final parts = activityDate.split('/');
                        if (parts.length == 3) {
                          final day = int.parse(parts[0]);
                          final month = int.parse(parts[1]);
                          final year = int.parse(parts[2]);
                          parsedActivityDate = DateTime(year, month, day);
                        }
                      } else if (activityDate.contains('-')) {
                        // Format: YYYY-MM-DD
                        final parts = activityDate.split('-');
                        if (parts.length == 3) {
                          final year = int.parse(parts[0]);
                          final month = int.parse(parts[1]);
                          final day = int.parse(parts[2]);
                          parsedActivityDate = DateTime(year, month, day);
                        }
                      }
                      
                      if (parsedActivityDate != null) {
                        final match = parsedActivityDate.year == selectedDate!.year &&
                                     parsedActivityDate.month == selectedDate!.month &&
                                     parsedActivityDate.day == selectedDate!.day;
                        print('Comparing: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} == $activityDate ? $match');
                        return match;
                      }
                      return false;
                    } catch (e) {
                      print('Error parsing date: ${a.activityDate} - $e');
                      return false;
                    }
                  }).toList();
                  print('Activities after date filter: ${activities.length}');
                }
                if (activities.isEmpty) {
                  return const Center(child: Text('No activities available'));
                }
                
                // Fetch details for all activities
                return FutureBuilder<List<ActivityData>>(
                  future: ActivityData.fetchMultipleDetails(activities),
                  builder: (context, detailsSnapshot) {
                    if (detailsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final activitiesWithDetails = detailsSnapshot.data ?? activities;
                    
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: activitiesWithDetails.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final a = activitiesWithDetails[index];
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
                                  (a.status).toUpperCase(),
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
                            const Icon(Icons.calendar_month, size: 16, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(a.activityDate),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, size: 16, color: Colors.black),
                            const SizedBox(width: 8),
                            Text('${a.startTime} - ${a.endTime}'),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text(a.locationName)),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.person, size: 16, color: Colors.black),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Officer: ${a.officerName ?? a.createdBy}')),
                            if (a.status.toLowerCase() == 'pending') ...[
                              ElevatedButton(
                                onPressed: () => 
                                  _showDetailsPopup(context, a),
                                child: const Text('Review Report'),
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
                );                  },
                );              },
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
                _detailRow(Icons.person, "Preacher", a.preacherName ?? 'Not assigned'),
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

                // If the activity is already pending → allow submit report
                if (a.status.toLowerCase() == "pending") ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      //_navigateToReportForm(context, a);
                    },
                    icon: const Icon(Icons.assignment),
                    label: const Text("Review Report"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade300,
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
                    textStyle: const TextStyle(fontSize: 16, color: Colors.black),
                    side: BorderSide(color: Colors.amber.shade300),
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
}