import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

// Controllers & Providers
import '../providers/Login/LoginController.dart';
import '../providers/ActvitiyController.dart';
import '../providers/PreacherController.dart';

// Models
import '../models/ActivityData.dart';
import '../models/Notification.dart';
import '../models/PreacherData.dart';

// Pages
import 'ManageProfile/userProfilePage.dart';
import 'ManageActivity/officer/officerActivityList.dart';
import 'ManageActivity/officer/assignActivity.dart';
import 'ManagePayment/payment_page.dart';
import 'ManagePreacher/PreacherManagementPage.dart';
import 'ManageReport/ReportDashboardPage.dart';
import 'ManageKPI/ManageKPIPage.dart';

class OfficerDashboard extends StatefulWidget {
  const OfficerDashboard({super.key});

  @override
  State<OfficerDashboard> createState() => _OfficerDashboardState();
}

class _OfficerDashboardState extends State<OfficerDashboard> {
  int _selectedIndex = 0;

  // The IndexedStack keeps the state of pages alive when switching tabs
  final List<Widget> _pages = [
    const _DashboardBody(),              // Index 0
    const OfficerActivityList(),         // Index 1
    const ManageKPIPage(),               // Index 2
    const ReportDashboardPage(),         // Index 3
    const UserProfilePage(),             // Index 4
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
  }

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
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      // Show AppBar only on the Dashboard tab
      appBar: _selectedIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.amber.shade600,
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
                    child: const Icon(Icons.shield, size: 22),
                  ),
                  const SizedBox(width: 12),
                  StreamBuilder<DocumentSnapshot>(
                    stream: currentUser != null
                        ? FirebaseFirestore.instance
                            .collection('officers')
                            .doc(currentUser.uid)
                            .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      String officerName = 'Officer';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        officerName = snapshot.data!.get('fullName') ?? 'Officer';
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome, ',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            officerName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              actions: [
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
          : null, // No AppBar for other tabs
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
          selectedItemColor: Colors.amber.shade600,
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
              icon: Icon(Icons.payment),
              activeIcon: Icon(Icons.payment),
              label: 'Payment',
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

  Widget _buildAppBarTitle(User? user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: user != null 
          ? FirebaseFirestore.instance.collection('officers').doc(user.uid).snapshots() 
          : null,
      builder: (context, snapshot) {
        String name = 'Officer';
        if (snapshot.hasData && snapshot.data!.exists) {
          name = snapshot.data!.get('fullName') ?? 'Officer';
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade600,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  final controller = ActivityController();
  String officerName = 'Officer';
  
  @override
  void initState() {
    super.initState();
    _loadPreacherStats();
  }

  Future<void> _loadPreacherStats() async {
    final preachers = await PreacherData.getPreachersStream().first;
    if (mounted) {
      setState(() {
        _totalPreachers = preachers.length;
        _activePreachers = preachers.where((p) => p.status.toLowerCase() == 'active').length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActivityData>>(
      stream: activityController.activitiesStream(),
      builder: (context, snapshot) {
        final activities = snapshot.data ?? [];
        
        // Calculate statistics
        final assignedCount = activities.where((a) => a.status.toLowerCase() == 'assigned').length;
        final checkedInCount = activities.where((a) => a.status.toLowerCase() == 'checked_in').length;
        final pendingCount = activities.where((a) => a.status.toLowerCase() == 'pending').length;
        final approvedCount = activities.where((a) => a.status.toLowerCase() == 'approved').length;
        final rejectedCount = activities.where((a) => a.status.toLowerCase() == 'rejected').length;
        
        // Recent submissions (pending status)
        final recentSubmissions = activities
            .where((a) => a.status.toLowerCase() == 'pending')
            .take(5)
            .toList();

        return Container(
          color: Colors.grey.shade50,
          child: CustomScrollView(
            slivers: [
              // Header Section with Stats
              SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade600, Colors.amber.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Logout
                Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Text(
                'Welcome, $officerName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Text(
                  'MUIP OFFICER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
                  ],
                ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Statistics Cards in Header
                      const Text(
                        'My Statistics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildHeaderStatCard(
                              'Total',
                              activities.length,
                              Colors.white,
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatCard(
                              'Assigned',
                              assignedCount,
                              Colors.blue.shade200,
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatCard(
                              'Checked-In',
                              checkedInCount,
                              Colors.cyan.shade200,
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatCard(
                              'Pending',
                              pendingCount,
                              Colors.orange.shade200,
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatCard(
                              'Approved',
                              approvedCount,
                              Colors.green.shade200,
                            ),
                            const SizedBox(width: 10),
                            _buildHeaderStatCard(
                              'Rejected',
                              rejectedCount,
                              Colors.red.shade200,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Actions Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              context,
                              icon: Icons.add_circle,
                              label: 'Assign Activity',
                              color: Colors.amber.shade600,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AssignActivityForm(),
                                    fullscreenDialog: true,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickActionButton(
                              context,
                              icon: Icons.rate_review,
                              label: 'Review Reports',
                              color: Colors.orange,
                              onTap: () {
                                DefaultTabController.of(context)?.animateTo(1);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Activity Submissions Section
              if (recentSubmissions.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Submissions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            DefaultTabController.of(context)?.animateTo(1);
                          },
                          child: Text(
                            'See all',
                            style: TextStyle(
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Recent Submissions List
              if (recentSubmissions.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final activity = recentSubmissions[index];
                        return _buildSubmissionCard(context, activity);
                      },
                      childCount: recentSubmissions.length,
                    ),
                  ),
                ),

              // Empty state if no pending submissions
              if (recentSubmissions.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No Pending Submissions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All reports have been reviewed',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Notifications & Alerts Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notifications & Alerts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to notifications page
                        
                        },
                        child: Text(
                          'See all',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Notifications List
              SliverToBoxAdapter(
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('activity_assignments')
                      .where('assigned_by', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .get(),
                  builder: (context, assignmentsSnapshot) {
                    if (!assignmentsSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final assignedActivityIds = assignmentsSnapshot.data!.docs
                        .map((doc) => (doc.data() as Map<String, dynamic>)['activity_id'] as int)
                        .toSet();

                    if (assignedActivityIds.isEmpty) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.notifications_none, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'No Notifications',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'No activities assigned by you yet',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('notifications')
                          .orderBy('timestamp', descending: true)
                          .limit(50)
                          .snapshots(),
                      builder: (context, notificationSnapshot) {
                        if (!notificationSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        // Filter: only notifications for activities assigned by this officer
                        // and exclude type == 'assignment'
                        final filtered = notificationSnapshot.data!.docs
                            .map((doc) => ActivityNotification.fromDoc(doc))
                            .where((n) => n.type.toLowerCase() != 'assignment'
                                && assignedActivityIds.contains(n.activityId))
                            .take(5)
                            .toList();

                        if (filtered.isEmpty) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.notifications_none, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text(
                                  'No Notifications',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'No new updates on your assigned activities',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),
                            itemBuilder: (context, index) {
                              final notification = filtered[index];
                              return _buildNotificationItem(notification);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, int value) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('$value', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        shadowColor: color.withOpacity(0.4),
      ),
    );
  }

  Widget _buildSubmissionCard(BuildContext context, ActivityData activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.preacherName ?? 'Preacher',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'PENDING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  activity.locationName,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 15, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                activity.activityDate,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              if (activity.status.toLowerCase() == 'pending') ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 13, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'GPS Verified',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                DefaultTabController.of(context)?.animateTo(1);
              },
              icon: const Icon(Icons.rate_review, size: 18),
              label: const Text(
                'Review Report',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(ActivityNotification notification) {
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    switch (notification.type) {
      case 'submission':
        icon = Icons.description;
        iconColor = Colors.blue.shade700;
        iconBgColor = Colors.blue.shade50;
        break;
      case 'approval':
        icon = Icons.check_circle;
        iconColor = Colors.green.shade700;
        iconBgColor = Colors.green.shade50;
        break;
      case 'rejection':
        icon = Icons.cancel;
        iconColor = Colors.red.shade700;
        iconBgColor = Colors.red.shade50;
        break;
      case 'edit':
        icon = Icons.edit;
        iconColor = Colors.orange.shade700;
        iconBgColor = Colors.orange.shade50;
        break;
      case 'assignment':
        icon = Icons.assignment;
        iconColor = Colors.amber.shade700;
        iconBgColor = Colors.amber.shade50;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey.shade700;
        iconBgColor = Colors.grey.shade50;
    }

    final timeAgo = _getTimeAgo(notification.timestamp);

    return InkWell(
      onTap: () {
        // Handle notification tap
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade600,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${(difference.inDays / 7).floor()} ${(difference.inDays / 7).floor() == 1 ? 'week' : 'weeks'} ago';
    }
  }

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
      }
    }
  }
}
