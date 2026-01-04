import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import '../models/ActivityData.dart';
import '../providers/ActvitiyController.dart';
import '../providers/Login/LoginController.dart';
import 'ManageProfile/userProfilePage.dart';
import 'ManageActivity/preacher/actvitiyList.dart';

class PreacherDashboard extends StatefulWidget {
  const PreacherDashboard({super.key});

  @override
  State<PreacherDashboard> createState() => _PreacherDashboardState();
}

class _PreacherDashboardState extends State<PreacherDashboard> {
  int _selectedIndex = 0;
  final ActivityController _activityController = ActivityController();

  final List<Widget> _pages = [
    // index 0 - dashboard
    const _DashboardBody(),
    // index 1 - activities
    const ActivityList(),
    // index 2 - preachers (placeholder)
    const Center(child: Text('Preachers')),
    // index 3 - reports (placeholder)
    const Center(child: Text('Reports')),
    // index 4 - profile
    const UserProfilePage(),
  ];

  Future<void> _logout(BuildContext context) async {
    final controller = LoginController();
    Map<String, dynamic> result = await controller.logout();

    if (context.mounted) {
      if (result['success']) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.lightGreen,
              foregroundColor: Colors.white,
              titleSpacing: 0,
              title: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 42,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 22),
                  ),
                  const SizedBox(width: 12),
                  StreamBuilder<DocumentSnapshot>(
                    stream: currentUser != null
                        ? FirebaseFirestore.instance
                            .collection('preachers')
                            .doc(currentUser.uid)
                            .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      String preacherName = 'Preacher';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        preacherName = snapshot.data!.get('fullName') ?? 'Preacher';
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assalamualaikum, ',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            preacherName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.gps_fixed, size: 16),
                      SizedBox(width: 4),
                      Text('GPS Active', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _logout(context),
                ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.lightGreen,
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          elevation: 0,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_outlined),
              activeIcon: Icon(Icons.event),
              label: 'Activities',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Preachers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// small extracted dashboard body to keep _pages clean
class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  final ActivityController _activityController = ActivityController();
  String _timeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Stats Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.lightGreen.shade400, Colors.lightGreen.shade600],
                ),
              ),
              child: StreamBuilder<List<ActivityData>>(
                stream: _activityController.activitiesStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }

                  final allActivities = snapshot.data!;
                  final myActivities = allActivities.where((a) => 
                    a.assignment?.preacherId == currentUser?.uid
                  ).toList();

                  final assigned = myActivities.where((a) => a.status == 'assigned').length;
                  final checkedIn = myActivities.where((a) => a.status == 'checked_in').length;
                  final pending = myActivities.where((a) => a.status == 'pending').length;
                  final approved = myActivities.where((a) => a.status == 'approved').length;
                  final rejected = myActivities.where((a) => a.status == 'rejected').length;
                  final total = myActivities.length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Statistics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard('Total', total, Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard('Assigned', assigned, Colors.blue.shade300),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard('Checked-In', checkedIn, Colors.cyan.shade300),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard('Pending', pending, Colors.orange.shade300),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard('Approved', approved, Colors.green.shade300),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard('Rejected', rejected, Colors.red.shade300),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            
            // Quick Actions
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement GPS Check-in
                          },
                          icon: const Icon(Icons.location_on),
                          label: const Text('GPS Check-In'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            
                          },
                          icon: const Icon(Icons.description),
                          label: const Text('Submit Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // My Activities Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Activities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All', style: TextStyle(fontSize: 12)),
                        selected: _timeFilter == 'all',
                        onSelected: (_) => setState(() => _timeFilter = 'all'),
                        selectedColor: Colors.lightGreen.shade100,
                        checkmarkColor: Colors.lightGreen,
                      ),
                      FilterChip(
                        label: const Text('Today', style: TextStyle(fontSize: 12)),
                        selected: _timeFilter == 'today',
                        onSelected: (_) => setState(() => _timeFilter = 'today'),
                        selectedColor: Colors.lightGreen.shade100,
                        checkmarkColor: Colors.lightGreen,
                      ),
                      FilterChip(
                        label: const Text('Week', style: TextStyle(fontSize: 12)),
                        selected: _timeFilter == 'week',
                        onSelected: (_) => setState(() => _timeFilter = 'week'),
                        selectedColor: Colors.lightGreen.shade100,
                        checkmarkColor: Colors.lightGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),

            // Activity Cards
            StreamBuilder<List<ActivityData>>(
              stream: _activityController.activitiesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                var activities = snapshot.data!.where((a) => 
                  a.assignment?.preacherId == currentUser?.uid
                ).toList();

                // Apply time filter
                if (_timeFilter != 'all') {
                  final now = DateTime.now();
                  activities = activities.where((activity) {
                    final date = activity.activityDate;
                    if (date.isEmpty) return false;
                    
                    DateTime? activityDate;
                    try {
                      if (date.contains('/')) {
                        final parts = date.split('/');
                        activityDate = DateTime(
                          int.parse(parts[2]),
                          int.parse(parts[1]),
                          int.parse(parts[0]),
                        );
                      } else {
                        activityDate = DateTime.parse(date);
                      }
                    } catch (e) {
                      return false;
                    }

                    if (_timeFilter == 'today') {
                      return activityDate.year == now.year &&
                             activityDate.month == now.month &&
                             activityDate.day == now.day;
                    } else if (_timeFilter == 'week') {
                      final weekAgo = now.subtract(const Duration(days: 7));
                      return activityDate.isAfter(weekAgo) && activityDate.isBefore(now.add(const Duration(days: 1)));
                    }
                    return true;
                  }).toList();
                }

                if (activities.isEmpty) {
                  return _EmptyStateCard(
                    title: 'No Activities',
                    message: _timeFilter == 'all'
                        ? 'You have no assigned activities yet.'
                        : 'No activities for this time period.',
                  );
                }

                // Sort by priority: assigned > checked_in > pending > approved/rejected
                activities.sort((a, b) {
                  int getPriority(String? status) {
                    switch (status?..toUpperCase()) {
                      case 'assigned':
                        return 1;
                      case 'checked_in':
                        return 2;
                      case 'pending':
                        return 3;
                      case 'approved':
                        return 4;
                      case 'rejected':
                        return 5;
                      default:
                        return 6;
                    }
                  }
                  return getPriority(a.status).compareTo(getPriority(b.status));
                });

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: activities.length,
                  itemBuilder: (context, index) => _ActivityCard(activities[index]),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatCard(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityData activity;

  const _ActivityCard(this.activity);

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'assigned':
        return Colors.blueAccent;
      case 'checked_in':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(activity.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    activity.title ?? 'Untitled Activity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    activity.status.toUpperCase() ?? 'N/A',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Location
            if (activity.locationAddress.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      activity.locationAddress.toUpperCase(),
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),

            // Date and Time
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.lightGreen),
                const SizedBox(width: 6),
                Text(
                  activity.activityDate,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(width: 6),
                Text(
                  '${activity.startTime} - ${activity.endTime}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Topic Badge
            if (activity.topic != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.shade100.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blueAccent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.topic, size: 14, color: Colors.blueAccent),
                    const SizedBox(width: 4),
                    Text(
                      activity.topic!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
      
            const SizedBox(height: 4),
            // Action Buttons based on status
            if (activity.status == 'assigned' || activity.status == 'checked_in')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    if (activity.status == 'assigned')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                          },
                          icon: const Icon(Icons.location_on, size: 18),
                          label: const Text('Check In'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.lightGreen,
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.lightGreen),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    if (activity.status == 'assigned') const SizedBox(width: 8),
                    if (activity.status == 'checked_in')
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                          },
                          icon: const Icon(Icons.description, size: 18),
                          label: const Text('Submit Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyStateCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
