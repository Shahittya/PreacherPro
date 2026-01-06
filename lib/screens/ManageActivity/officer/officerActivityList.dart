import 'package:flutter/material.dart';
import '../../../models/ActivityData.dart';
import '../../../providers/ActvitiyController.dart';
import 'assignActivity.dart';
import 'editActivity.dart';

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
                  activities = activities.where((a) =>
                      a.title.toLowerCase().contains(searchText) ||
                      a.locationName.toLowerCase().contains(searchText) ||
                      a.createdBy.toLowerCase().contains(searchText) ||
                      a.locationAddress.toLowerCase().contains(searchText)
                  ).toList();
                }

                // Status filter
                if (selectedStatus != 'All') {
                  activities = activities
                      .where((a) =>
                          a.status.toLowerCase() ==
                          selectedStatus.toLowerCase())
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
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
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
        items: ['All', 'assigned', 'checked_in', 'pending', 'approved', 'rejected']
            .map(
              (s) => DropdownMenuItem(
                value: s,
                child: Text(s == 'All' ? 'All Status' : s),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => selectedStatus = v!),
      ),
    );
  }

  Widget _activityCard(BuildContext context, ActivityData a) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(
            color: Colors.amber.shade400,
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
                    child: const Icon(Icons.location_on, color: Colors.amber, size: 18),
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
                  child: Text(
                    a.status.toLowerCase() == 'pending' ? 'Review' : 'View',
                  ),
                ),
              ),
              if (a.status.toLowerCase() == 'assigned') ...[
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
                  onPressed: () =>
                      _showDeleteConfirmation(context, a),
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
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
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
          Icon(Icons.event_busy,
              size: 64, color: Colors.grey.shade400),
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
      case "ASSIGNED":
        return Colors.yellow.shade100;
      case "APPROVED":
        return Colors.green.shade100;
      case "PENDING":
        return Colors.orange.shade100;
      case "REJECTED":
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _statusTextColor(String status) {
    switch (status.toUpperCase()) {
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

                      // ===== ACTION =====
                      if (a.status.toLowerCase() == 'pending')
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // navigate to review
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
              Text(label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  )),
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
      builder: (_) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text(
            'Are you sure you want to delete this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await controller.deleteActivity(activity);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Activity deleted'
                      : 'Cannot delete activity'),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
